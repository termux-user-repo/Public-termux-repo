#!/bin/bash

if [ "$1" = "--uninstall" ]; then
    echo "Removing Python mods..."
    pip uninstall -y some-package
    exit 0
fi

echo "Installing Python enhancements..."
apt update
apt install -y python python-pip

pip install --upgrade pip
pip install requests numpy

echo "✅ Python mods installed!"
python --version
