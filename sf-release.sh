#!/bin/bash
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    swift build -c release -Xswiftc -I"openssl/v1_1_1g-mint_19_3/include" -Xlinker -L"openssl/v1_1_1g-mint_19_3/lib"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    swift build -c release -Xswiftc -I"openssl/v1_1_1g-macos_10_15/include" -Xlinker -L"openssl/v1_1_1g-macos_10_15/lib"
else
    echo "Error: Unknown OS"
fi