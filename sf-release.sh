#!/bin/bash
if [[ "$OSTYPE" == "linux-gnu"* ]]; then

    OPENSSL = "openssl/v1_1_1g-mint_19_3"

elif [[ "$OSTYPE" == "darwin"* ]]; then

    OPENSSL = "openssl/v1_1_1g-macos_10_15"

else
    echo "Error: Unknown OS"
    exit 1
fi

echo "Using openssl path: $OPENSSL"
swift build -c release -Xswiftc -I"$OPENSSL/include" -Xlinker -L"$OPENSSL/lib"
