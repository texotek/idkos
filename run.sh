cd "$(dirname "$0")"
make && qemu-system-i386 -kernel build/idkos.bin
