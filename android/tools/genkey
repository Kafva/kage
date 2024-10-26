#!/usr/bin/env bash
#
# Generate a key to sign Android release builds with
#
rm -f ./kage.jks
keytool -v \
        -genkeypair \
        -keystore ./kage.jks \
        -alias kage \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -dname "CN=kafva.kage, OU=kafva, O=kafva, C=SE" \
        -storepass password \
        -keypass password
