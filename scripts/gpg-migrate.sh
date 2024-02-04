#!/usr/bin/env bash
die() { printf "$1\n" >&2 ; exit 1; }
info() { printf "\033[34m*\033[0m $1\n" >&2; }

#==============================================================================#

set -e
set -o pipefail

if [ -z "$2" ]; then
    echo  "usage: $(basename $0) <gpg-store> <name>" >&2
    exit 1
fi

GPG_STORE="$1"
GPG_ID=$(cat $GPG_STORE/.gpg-id)

NAME="$2"
AGE_STORE="$PWD/kage-store/$NAME"

mkdir -p "$AGE_STORE"

# Generate a new key
KEY="$(age-keygen)"
PUBKEY=$(age-keygen -y <<< "$KEY")

# Save it, passphrase encrypted
# We only want one identity to have access to each store
age -p -a <<< "$KEY" > "$AGE_STORE/.age-identities"

# Mark it as the recipient
echo "$PUBKEY" >> "$AGE_STORE/.age-recipients"

while read -r gpgfile; do
    _gpgfile=${gpgfile#"$GPG_STORE/"}
    agefile="$AGE_STORE/${_gpgfile%%.gpg}.age"
    mkdir -p "$(dirname $agefile)"

    info "$_gpgfile"
    gpg -q -r "$GPG_ID" -d "$gpgfile" |
        age -r "$PUBKEY" -o "$agefile" -

done < <(find "$GPG_STORE" -type f -name '*.gpg')

tree -a --noreport $AGE_STORE

[ -d $GPG_STORE/.git ] && cp -r $GPG_STORE/.git $AGE_STORE

info "Test decryption"
agefile="$(find "$AGE_STORE" -type f -name '*.age' | head -n1)"
age -i $AGE_STORE/.age-identities -d $agefile
