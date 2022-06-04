#!/bin/bash

kernelname="linux"

basepath="$(pwd)"
datapath="$basepath/data"
kernelpath="$datapath/vm_image_kernel"
imagepath="$datapath/vm_image.img"

# Make data path
mkdir -p "$datapath"

# Grab latest crosvm
if [[ ! -d "$datapath/crosvm" ]]; then
    git clone --recursive https://chromium.googlesource.com/chromiumos/platform/crosvm "$datapath/crosvm"
else
    pushd "$datapath/crosvm"
    git pull
    popd
fi

# Grab image if we don't have one
if [[ ! -f "$imagepath" ]]; then
    # NOTE default user: arch/arch
    wget https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-basic.qcow2 -O "$imagepath.qcow2"
    qemu-img convert -f qcow2 -O raw "$imagepath.qcow2" "$imagepath"
    rm "$imagepath.qcow2"
fi

# Extract kernel and initramfs to work with pacman -Syu updates
rm -rf "$kernelpath" || true
mkdir -p "$kernelpath"
virt-builder --get-kernel "$imagepath" -o "$kernelpath"

pushd "$datapath/crosvm"
cargo run --features=gpu,x,virgl_renderer,virgl_renderer_next -- run \
    --cpus 4 \
    --mem 8192 \
    --disable-sandbox \
    --gpu backend=virglrenderer,width=1920,height=1080,vulkan=true \
    --display-window-keyboard \
    --display-window-mouse \
    --tap-name crosvm_tap \
    --rwroot "$imagepath" \
    -p "root=/dev/vda2" \
    --initrd "$kernelpath/initramfs-$kernelname.img" \
    "$kernelpath/vmlinuz-$kernelname"
popd
