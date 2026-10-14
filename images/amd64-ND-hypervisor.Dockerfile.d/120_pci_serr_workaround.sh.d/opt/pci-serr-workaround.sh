#!/bin/bash

FILES="/sys/bus/pci/devices/*"

for dev in $FILES
do
    port=$(basename "$(dirname "$(readlink "$dev")")")
    if [ ! -e "/sys/bus/pci/devices/$port" ]; then
        continue
    fi

    cmd=$(setpci -s "$port" COMMAND)

    # clear SERR bit in command register
    setpci -s "$port" COMMAND="$(printf "%04x" $(("0x$cmd" & ~0x0100)))"

    ctrl=$(setpci -s "$port" CAP_EXP+8.w)

    echo "Disabling fatal error reporting on port $port..."
    echo "Command: $cmd - Device control: $ctrl"
    echo ""

    # clear fatal error reporting enable bit in device control register
    setpci -s "$port" CAP_EXP+8.w="$(printf "%04x" $(("0x$ctrl" & ~0x0004)))"
done
