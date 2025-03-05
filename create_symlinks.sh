#!/bin/sh

BUSYBOX_BINARY="busybox"
TARGET_DIR="."
COMMANDS=$($BUSYBOX_BINARY --list)

for cmd in $COMMANDS; do
    ln -s $BUSYBOX_BINARY $TARGET_DIR/$cmd
done

echo "Busybox commands symlinks: done."
