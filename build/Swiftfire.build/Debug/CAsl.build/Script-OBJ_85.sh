#!/bin/sh
mkdir -p "${PROJECT_TEMP_DIR}/SymlinkLibs"
ln -sf "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_PATH}" "${PROJECT_TEMP_DIR}/SymlinkLibs/lib${EXECUTABLE_NAME}.dylib"

