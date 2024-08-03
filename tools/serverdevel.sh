#!/usr/bin/env bash
set -e
set -o pipefail

REMOTE_ORIGIN="git://127.0.0.1"
TOP="$(cd "$(dirname "$0")/.." && pwd)"
JAMES_REPO_REMOTE="$TOP/.testenv/kage-store/james"
JAMES_REPO_CLIENT="$TOP/.testenv/kage-client/james"
JAMES_KEY="$TOP/.testenv/kage-client/james/.age-identities"
JAMES_PUBKEY="$TOP/.testenv/kage-client/james/.age-recipients"
UNIT_TESTS_MODE=false

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
    _age_generate_files "$JAMES_REPO_CLIENT/red/a" "$JAMES_PUBKEY"
    _age_generate_files "$JAMES_REPO_CLIENT/green/a" "$JAMES_PUBKEY"
    _age_generate_files "$JAMES_REPO_CLIENT/green/b" "$JAMES_PUBKEY"
    _age_generate_files "$JAMES_REPO_CLIENT/blue/a" "$JAMES_PUBKEY"

    echo "Creating $JAMES_REPO_REMOTE"
    mkdir -p $JAMES_REPO_REMOTE
    git -C $JAMES_REPO_REMOTE init --bare

    git -C $JAMES_REPO_CLIENT init
    git -C $JAMES_REPO_CLIENT config user.name "James Doe"
    git -C $JAMES_REPO_CLIENT config user.email "james.doe@kafva.one"
    git -C $JAMES_REPO_CLIENT config commit.gpgsign false
    git -C $JAMES_REPO_CLIENT add .
    git -C $JAMES_REPO_CLIENT commit -m "First commit"
    git -C $JAMES_REPO_CLIENT remote add origin "$REMOTE_ORIGIN/james"

    git_server_restart
    sleep 1

    echo "Pushing first commit"
    git -C $JAMES_REPO_CLIENT push --set-upstream origin main
}

git_server_unit() {
    mkdir -p $TOP/.testenv/kage-store
    mkdir -p $TOP/.testenv/kage-client/tests
    git_server_restart

    # Create one git repo for each test case in the git.rs module
    local tmpdir=$(mktemp -d)
    while read -r testcase; do
        local testname=$(sed -nE 's/^git_test::git_([_a-z]+):.*/\1/p' <<< "$testcase")
        local test_remote="$TOP/.testenv/kage-store/tests/$testname"

        echo "Creating $test_remote"
        mkdir -p $test_remote
        git -C $test_remote init --bare

        git clone "$REMOTE_ORIGIN/tests/$testname" $tmpdir

        echo "$testname" > "$tmpdir/$testname"
        git -C $tmpdir add .
        git -C $tmpdir commit --no-gpg-sign -m "First commit"
        git -C $tmpdir push origin main
        rm -rf $tmpdir

    done < <(cd $TOP/kage-core && cargo test -- -q --list 2> /dev/null | grep '^git_test::')

    tree -L 1 "$TOP/.testenv/kage-store/tests"
}

git_server_restart() {
    git_server_stop
    git daemon --base-path="$TOP/.testenv/kage-store" \
               --enable=receive-pack \
               --access-hook="$TOP/tools/ip-auth" \
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
    git -C $JAMES_REPO_CLIENT commit -m "Added ${folder##"$TOP/.testenv/"}"
    git -C $JAMES_REPO_CLIENT push -q
    git -C $JAMES_REPO_CLIENT log -n1
}

git_server_pull() {
    git -C $JAMES_REPO_CLIENT pull origin main
}

git_server_del() {
    local file=$(find $JAMES_REPO_CLIENT -type f -name '*.age' | shuf | head -n1)
    [ -f "$file" ] || die "No files to delete"

    rm "$file"
    git -C $JAMES_REPO_CLIENT rm "$file"
    git -C $JAMES_REPO_CLIENT commit -m "Removed ${file##"$TOP/.testenv/"}"
    git -C $JAMES_REPO_CLIENT push -q
    git -C $JAMES_REPO_CLIENT log -n1
}

git_server_mod() {
    local file=$(find $JAMES_REPO_CLIENT -type f -name '*.age' | shuf | head -n1)
    [ -f "$file" ] || die "No files to modify"

    age -r "$(cat $JAMES_PUBKEY)" -o "$file" - <<< "password-modified"

    git -C $JAMES_REPO_CLIENT add "$file"
    git -C $JAMES_REPO_CLIENT commit -m "Modified ${file##"$TOP/.testenv/"}"
    git -C $JAMES_REPO_CLIENT push -q
    git -C $JAMES_REPO_CLIENT log -n1
}

git_server_status() {
    if $UNIT_TESTS_MODE; then
        for d in "$TOP/.testenv/kage-store/tests"/*; do
            echo "+ $d"
            git -C $d log --format='%C(auto) %h %s'
        done
        echo
    else
        git -C $JAMES_REPO_CLIENT log --format='%C(auto) %h %s'
        git -C $JAMES_REPO_CLIENT status
    fi
}

git_server_controls() {
    local james=${JAMES_REPO_CLIENT##"${TOP}/.testenv/"}
    cat << EOF
R: Reinitialise git repo
S: Status of $james
P: Pull in changes for $james
A: Add files to $james
M: Modify files in $james
D: Delete files in $james
H: Show controls
Q: Quit

EOF
}

#==============================================================================#


trap git_server_exit SIGINT

case "$1" in
reset)
    rm -rf "${TOP?}/.testenv"
    git_server_stop
    exit $?
;;
unit)
    UNIT_TESTS_MODE=true

    rm -rf "${TOP?}/.testenv"
    git_server_unit
;;
*)
    if [[ ! -d "$JAMES_REPO_CLIENT" || ! -d "$JAMES_REPO_REMOTE" ]]; then
        git_server_setup
    else
        git_server_restart
    fi
;;
esac

echo "Launched git-daemon 🚀"
git_server_controls

while read -n1 -rs ans; do
    case "$ans" in
    [sS])
        git_server_status
    ;;
    [pP])
        git_server_pull
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
        git_server_stop

        echo "Clearing $TOP/.testenv"
        rm -rf "$TOP/.testenv"
        git_server_setup
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
