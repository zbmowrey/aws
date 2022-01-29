#!/bin/bash

echo | openssl s_client -connect token.actions.githubusercontent.com:443 -showcerts  2>&- | keytool -printcert | grep 'Certificate fingerprints' -A1  | tail -n1 | cut -d' ' -f3 | tr -d ':' | awk '{print tolower($1)}' | jq -rR 'split(" ")|{fingerprint:.[0]}'

