rm -rf static/public
rackula generate -p assets -o static/public

# Copy kernel
cp kernel/*.s static/public/kernel/.
cp kernel/kernel.bin static/public/kernel/.

# Fix guidance image links
sed -i s/\\.\\.\\/images/images/g static/public/guidance/*.html
