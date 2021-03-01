mkdir -p static
rm -rf static/public
rackula generate -p assets -o static/public

# Copy kernel
cp kernel/*.s static/public/kernel/.
cp kernel/kernel.bin static/public/kernel/.

# Fix guidance instruction links
sed -i s/instructions_ajax.html\#/\#/g static/public/guidance/instructions_ajax.html

# Remove things we don't need
rm -rf static/public/js/ace-builds/.git
rm -rf static/public/js/ace-builds/.github
rm -rf static/public/js/ace-builds/src
rm -rf static/public/js/ace-builds/src-min
rm -rf static/public/js/ace-builds/src-min-noconflict
rm -rf static/public/js/ace-builds/demo
