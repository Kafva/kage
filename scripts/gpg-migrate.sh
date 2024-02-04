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
NAME="$2"
AGE_STORE="$PWD/.passage"

mkdir -p "$AGE_STORE/store/$NAME"

# Generate a new key
KEY="$(age-keygen)"
PUBKEY=$(age-keygen -y <<< "$KEY")

# Save it, passphrase encrypted
age -p -a <<< "$KEY" > "$AGE_STORE/.$NAME"

# Add it to the list of identities
cat "$AGE_STORE/.$NAME" >> "$AGE_STORE/identities"

# Use it to encrypt/decrypt under store/$NAME
echo "$PUBKEY" >> "$AGE_STORE/store/$NAME/.age-recipients"

while read -r gpgfile; do
    _gpgfile=$(sed "s@$GPG_STORE/@@" <<< "$gpgfile")
    agefile="$AGE_STORE/store/$NAME/${_gpgfile%%.gpg}.age"
    mkdir -p "$(dirname $agefile)"

    info "$_gpgfile"
    gpg -r "$(cat $GPG_STORE/.gpg-id)" -d "$gpgfile" |
        age -r "$PUBKEY" -o "$agefile" -

done < <(find "$GPG_STORE" -type f -name '*.gpg')

tree -a --noreport $AGE_STORE

info "Test decryption"
agefile="$(find "$AGE_STORE/store/$NAME" -type f -name '*.age' | head -n1)"
age -i $AGE_STORE/identities -d $agefile
