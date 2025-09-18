#!/bin/bash
set -e

echo
echo "╔══════════════════════════════════════════════════════════════╗"
echo "  ⚠️ Select remote or local:                                    "
echo "║══════════════════════════════════════════════════════════════║"
echo "║  0 for local                                                 ║"
echo "║  1 for remote                                                ║"
echo "║ [default: local]                                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo
read -r remote_or_local

REMOTE_OR_LOCAL=${remote_or_local:-0}

if [ "$REMOTE_OR_LOCAL" == "1" ]; then
    # Save the original blockscout launcher
    cp src/blockscout/blockscout_launcher.star src/blockscout/blockscout_launcher.star.bak

    # Get the machine's IP address using ip command (works on Ubuntu)
    MACHINE_IP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+' | head -n1)

    # Fallback to hostname -I if ip route doesn't work
    if [ -z "$MACHINE_IP" ]; then
        MACHINE_IP=$(hostname -I | awk '{print $1}')
    fi

    # Final fallback to parsing ip addr output
    if [ -z "$MACHINE_IP" ]; then
        MACHINE_IP=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}' | cut -d'/' -f1)
    fi

    if [ -z "$MACHINE_IP" ]; then
        echo
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "  ❌ Error: Could not determine machine IP address              "
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo
        exit 1
    fi

    echo
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║ Setting Blockscout to use machine IP: $MACHINE_IP            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo

    # Replace localhost with machine IP in blockscout launcher
    sed -i.bak 's/else "localhost:{0}"/else "'$MACHINE_IP':{0}"/g' src/blockscout/blockscout_launcher.star

    echo
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "  💾 Original file backed up                                    "
    echo "║══════════════════════════════════════════════════════════════║"
    echo "║ src/blockscout/blockscout_launcher.star.bak                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo

    kurtosis run --enclave surge-devnet . --args-file network_params.yaml --production --image-download always

    echo
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "  ✅ Successfully prepared surge devnet remotely                "
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo

    echo
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "  💡 Reverting blockscout to original state...                  "
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo

    # Check if backup exists
    if [ -f "src/blockscout/blockscout_launcher.star.bak" ]; then
        # Restore from backup
        mv src/blockscout/blockscout_launcher.star.bak src/blockscout/blockscout_launcher.star
        echo
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "  ✅ Successfully reverted blockscout to original state         "
        echo "║══════════════════════════════════════════════════════════════║"
        echo "║ Restored from: src/blockscout/blockscout_launcher.star.bak   ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo
    else
        # Manual replacement back to localhost
        echo
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "  ❌ No backup found, git stash to restore...                   "
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo
    fi
else
    kurtosis run --enclave surge-devnet . --args-file network_params.yaml --production --image-download always

    echo
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "  ✅ Successfully prepared surge devnet locally                 "
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo
fi

