wget https://github.com/electron/electron/releases/download/v11.3.0/electron-v11.3.0-win32-x64.zip
mkdir -p builds/windows
cd builds/windows
unzip ../../electron*win32-x64.zip
cp -r ../../../static/public resources/app/.
cp ../../main.js resources/app/.
cd ../..

mkdir -p releases
zip builds/windows/* releases/rawrs-win32-x64.zip
