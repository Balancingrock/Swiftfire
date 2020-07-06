These are precompiled versions of OpenSSL.

Naming convention: <openssl-version>-<build-system>

### Swiftfire 1.3.3 and later

__v1_1_1g-macos_10_15__ OpenSSL v1.1.1g compiled on MacOS 10.15
__v1_1_1g-mint_19_03__ OpenSSL v1.1.1g compiled on Linux Mint 19.3

Swiftfire 1.3.3 and later use a different approach to adopting openSSL. It is no longer necessary to modify the openSSl sources, but instead use CopensslGlue to provide the glue code.

### Swiftfire 1.3.2 and earlier

__v1_1_0-macos_10_12__ OpenSSL v1.1.0 (probably subversion c) compiled on MacOS 10.12. This version contains two patches that are needed to due to C-header visibility issues on earlier Swift versions.



