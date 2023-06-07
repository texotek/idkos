cd "$(dirname "$0")"
cd ..
make &&
qemu-system-i386 -fda build/main_floppy.img
