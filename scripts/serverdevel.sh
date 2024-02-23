#!/usr/bin/env bash
set -e
set -o pipefail

REMOTE_ORIGIN="git://127.0.0.1"
TOP="$(cd "$(dirname "$0")/.." && pwd)"
JAMES_REPO_REMOTE="$TOP/kage-store/james"
JAMES_REPO_CLIENT="$TOP/kage-client/james"
JAMES_KEY="$TOP/kage-client/james/.age-identities"
JAMES_PUBKEY="$TOP/kage-client/james/.age-recipients"

die() {
    printf "$1\n" >&2
    git_server_stop
    exit 1
}

_age_generate_files() {
    local folder="$1"
    local pubkey="$2"
    local cnt="${3:-5}"
    mkdir -p "$folder"
    for i in $(seq 1 $cnt); do
        age -r "$(cat $pubkey)" \
            -o "$folder/pass$i.age" - <<< "password-$i"
    done
}

_age_generate_keys() {
    local repo_key="$1"
    local repo_pubkey="$2"
    # Skip if already present
    [[ -f "$repo_key" && -f "$repo_pubkey" ]] && return

    # Generate a new key
    local key="$(age-keygen)"
    local pubkey=$(age-keygen -y <<< "$key")

    # Save it, passphrase encrypted
    # We only want one identity to have access to each store
    age -p -a <<< "$key" > "$repo_key"

    # Mark it as the recipient
    echo "$pubkey" >> "$repo_pubkey"
}

git_server_setup() {
    echo "Creating $JAMES_REPO_CLIENT"
    mkdir -p $JAMES_REPO_CLIENT

    _age_generate_keys "$JAMES_KEY" "$JAMES_PUBKEY"
    _age_generate_files "$JAMES_REPO_CLIENT/red" "$JAMES_PUBKEY"

    echo "Creating $JAMES_REPO_REMOTE"
    mkdir -p $JAMES_REPO_REMOTE
    git -C $JAMES_REPO_REMOTE init --bare

    git -C $JAMES_REPO_CLIENT init
    git -C $JAMES_REPO_CLIENT config user.name "James Doe"
    git -C $JAMES_REPO_CLIENT config user.email "james.doe@kafva.one"
    git -C $JAMES_REPO_CLIENT add .
    git -C $JAMES_REPO_CLIENT commit -m "First commit"
    git -C $JAMES_REPO_CLIENT remote add origin "$REMOTE_ORIGIN/james"

    git_server_restart
    sleep 1

    echo "Pushing first commit"
    git -C $JAMES_REPO_CLIENT push --set-upstream origin main
}

git_server_restart() {
    git_server_stop
    git daemon --base-path="$TOP/kage-store" \
               --enable=receive-pack \
               --access-hook="$TOP/scripts/ip-auth" \
               --export-all \
               --reuseaddr \
               --informative-errors &
    GIT_SERVER_PID=$!
}

git_server_exit() {
    printf "\nExitting...\n"
    git_server_stop
    exit 0
}

git_server_stop() {
    if [ -n "$GIT_SERVER_PID" ]; then
        kill $GIT_SERVER_PID &> /dev/null || :
    fi

    killall -SIGTERM git-daemon &> /dev/null || :
}

git_server_add() {
    local folder="added-$RANDOM"
    _age_generate_files "$JAMES_REPO_CLIENT/$folder" "$JAMES_PUBKEY" 1

    git -C $JAMES_REPO_CLIENT add .
    git -C $JAMES_REPO_CLIENT commit -m "Added ${folder##"$TOP/"}"
    git -C $JAMES_REPO_CLIENT push -q
    git -C $JAMES_REPO_CLIENT log -n1
}

git_server_del() {
    local file=$(find $JAMES_REPO_CLIENT -type f -name '*.age' | shuf | head -n1)
    [ -f "$file" ] || die "No files to delete"

    rm "$file"
    git -C $JAMES_REPO_CLIENT rm "$file"
    git -C $JAMES_REPO_CLIENT commit -m "Removed ${file##"$TOP/"}"
    git -C $JAMES_REPO_CLIENT push -q
    git -C $JAMES_REPO_CLIENT log -n1
}

git_server_mod() {
    local file=$(find $JAMES_REPO_CLIENT -type f -name '*.age' | shuf | head -n1)
    [ -f "$file" ] || die "No files to modify"

    age -r "$(cat $JAMES_PUBKEY)" -o "$file" - <<< "password-modified"

    git -C $JAMES_REPO_CLIENT add "$file"
    git -C $JAMES_REPO_CLIENT commit -m "Modified ${file##"$TOP/"}"
    git -C $JAMES_REPO_CLIENT push -q
    git -C $JAMES_REPO_CLIENT log -n1
}

git_server_status() {
    git -C $JAMES_REPO_CLIENT log --format='%C(auto) %h %s'
    git -C $JAMES_REPO_CLIENT status
}

git_server_controls() {
    local james=${JAMES_REPO_CLIENT##"${TOP}/"}
    cat << EOF
R: Restart git-daemon
S: Status of $james
A: Add files to $james
M: Modify files in $james
D: Delete files in $james
H: Show controls
Q: Quit

EOF
}

#==============================================================================#


trap git_server_exit SIGINT

if [[ ! -d "$JAMES_REPO_CLIENT" || ! -d "$JAMES_REPO_REMOTE" ]]; then
    git_server_setup
else
    git_server_restart
fi


echo "Launched git-daemon:"
git_server_controls

while read -n1 -rs ans; do
    case "$ans" in
    [sS])
        git_server_status
    ;;
    [aA])
        git_server_add
    ;;
    [mM])
        git_server_mod
    ;;
    [dD])
        git_server_del
    ;;
    [rR])
        git_server_restart
    ;;
    [qQ])
        git_server_exit
    ;;
    [hH])
        git_server_controls
    ;;
    esac
done
