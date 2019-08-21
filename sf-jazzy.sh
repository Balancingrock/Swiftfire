#!/bin/bash
jazzy --config .custom.jazzy.yaml
jazzy --config .admin.jazzy.yaml
jazzy --config .core.jazzy.yaml
jazzy --config .functions.jazzy.yaml
jazzy --config .services.jazzy.yaml
jazzy --config .swiftfire.jazzy.yaml
echo "Jazzy completed"
