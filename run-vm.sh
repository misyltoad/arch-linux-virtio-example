#!/bin/bash

basepath="$(pwd)"
datapath="$basepath/data"
imagepath="$datapath/vm_image.qcow"

# Make data path
mkdir -p "$datapath"

# Grab latest qemu
if [[ ! -d "$datapath/qemu" ]]; then
    git clone -b josh-venus --recursive https://github.com/Joshua-Ashton/qemu "$datapath/qemu"

    mkdir -p "$datapath/qemu/build"
    # Build...
    pushd "$datapath/qemu/build"
        ../configure \
            --smbd=/usr/bin/smbd    \
            --enable-modules        \
            --enable-sdl            \
            --enable-slirp=system   \
            --disable-werror

        ninja
    popd
fi

# Grab image if we don't have one
if [[ ! -f "$imagepath" ]]; then
    # NOTE default user: arch/arch
    wget https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-basic.qcow2 -O "$imagepath"
fi

# Not sure why this needs sudo but whatever...
sudo cp /usr/share/OVMF/x64/OVMF_VARS.fd "$datapath/OVMF_VARS.fd"
sudo chown -R $(id -u):$(id -g) "$datapath/OVMF_VARS.fd"

# The Wayland one is broken with resizing, yay!
export GDK_BACKEND=x11

# This Arch is not EFI for some reason
# but if you were to...
#   -drive if=pflash,format=raw,readonly=on,file="/usr/share/OVMF/x64/OVMF.fd" \
#   -drive if=pflash,format=raw,file="$datapath/OVMF_VARS.fd" \

valgrind "$datapath/qemu/build/qemu-system-x86_64" \
    -M accel=kvm:tcg \
    -m 4G \
    -cpu host \
    -smp cores=4 \
    -device virtio-vga-gl,context_init=true,blob=true,hostmem=4G \
    -vga none \
    -display gtk,gl=on,show-cursor=on \
    -object memory-backend-memfd,id=mem1,size=4G \
    -machine memory-backend=mem1 \
    -device intel-hda \
    -device hda-duplex \
    -drive if=virtio,format=qcow2,file=if=virtio,file="$imagepath" \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -d guest_errors

