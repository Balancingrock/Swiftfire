#!/bin/bash
if [[ "$OSTYPE" == "linux-gnu"* ]]; then

    OPENSSL_PATH="${PWD}/openssl/v1_1_1g-mint_19_3"

elif [[ "$OSTYPE" == "darwin"* ]]; then

    OPENSSL_PATH="${PWD}/openssl/v1_1_1g-macos_10_15"

else
    echo "Error: Unknown OS"
    exit 1
fi

echo "Using openssl path: $OPENSSL_PATH"
swift build -Xswiftc -I"${OPENSSL_PATH}/include" -Xlinker -L"${OPENSSL_PATH}/lib"
