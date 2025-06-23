#!/bin/bash

# Get the machine's IP address (preferring non-loopback interfaces)
MACHINE_IP=$(ifconfig | grep -E "inet ([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{print $2}' | head -n1)

if [ -z "$MACHINE_IP" ]; then
    echo "Error: Could not determine machine IP address"
    exit 1
fi

echo "Setting Blockscout to use machine IP: $MACHINE_IP"

# Replace localhost with machine IP in blockscout launcher
sed -i.bak 's/else "localhost:{0}"/else "'$MACHINE_IP':{0}"/g' src/blockscout/blockscout_launcher.star

echo "Successfully updated blockscout launcher to use machine IP: $MACHINE_IP"
echo "Original file backed up as: src/blockscout/blockscout_launcher.star.bak"

kurtosis run --enclave surge-devnet . --args-file network_params.yaml --production

echo "Surge Devnet is prepared"

echo "Reverting Blockscout to use localhost..."

# Check if backup exists
if [ -f "src/blockscout/blockscout_launcher.star.bak" ]; then
    # Restore from backup
    cp src/blockscout/blockscout_launcher.star.bak src/blockscout/blockscout_launcher.star
    echo "Successfully reverted blockscout launcher to use localhost"
    echo "Restored from backup: src/blockscout/blockscout_launcher.star.bak"
else
    # Manual replacement back to localhost
    echo "No backup found, performing manual revert..."
    
    # Replace any IP address pattern with localhost
    sed -i 's/else "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:{0}"/else "localhost:{0}"/g' src/blockscout/blockscout_launcher.star
    
    echo "Successfully reverted blockscout launcher to use localhost"
fi