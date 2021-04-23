#!/bin/bash

echo "Downloading Electron"
echo "===================="

wget -nc "https://github.com/electron/electron/releases/download/v11.3.0/electron-v11.3.0-win32-x64.zip"

echo "Installing Dependencies"
echo "======================="

npm install

echo "Copying"
echo "======="

if [ ! -d ../static/public ]; then
  echo "Error: No static site found."
  echo "       Use \`package.sh\` in the root directory to create."
  exit
fi

mkdir -p builds/windows
cd builds/windows
unzip -u ../../electron*win32-x64.zip
mv electron.exe rawrs.exe
mkdir -p resources/app
cp -r ../../../static/public resources/app/.
cp -r ../../node_modules resources/app/.
cp ../../electron.js resources/app/public/js/electron.js
cp ../../main.js resources/app/.
cp ../../package.json resources/app/.
cd ../..

echo ""
echo "Packaging"
echo "========="

mkdir -p releases
cd builds/windows
zip -yr ../../releases/rawrs-win32-x64.zip *
