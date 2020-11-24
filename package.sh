rm -rf static/public
rackula generate -p assets -o static/public

# Copy kernel
cp kernel/*.s static/public/kernel/.
cp kernel/kernel.bin static/public/kernel/.

# Fix guidance instruction links
sed -i s/instructions_ajax.html\#/\#/g static/public/guidance/instructions_ajax.html
