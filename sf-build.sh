#!/bin/bash
USED_SSL_ROOT="${PWD}/openssl/v1_1_0-macos_10_12/"
echo "Using openSSL root = $USED_SSL_ROOT"
swift build -Xswiftc -I"${USED_SSL_ROOT}include" -Xlinker -L"${USED_SSL_ROOT}lib"
