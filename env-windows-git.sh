#!/usr/bin/env bash
if [ ! -e "./venv" ]; then
python -m venv venv
source ./venv/Scripts/activate
pip install mkdocs-material
python.exe -m pip install --upgrade pip
else
source ./venv/Scripts/activate
fi
mkdocs serve
