#!/bin/bash

if [ "$1" = "--uninstall" ]; then
    echo "Removing C# tools..."
    apt remove -y dotnet-runtime mono
    exit 0
fi

echo "Installing C# development tools..."
apt update
apt install -y mono

echo "✅ C# tools installed!"
mono --version
