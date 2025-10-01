#!/bin/bash
set -e

# Select simulation or broadcast
echo "Select simulation or broadcast (false for simulation, true for broadcast) [default: simulation]: "
read -r broadcast_or_simulation

BROADCAST_OR_SIMULATION=${broadcast_or_simulation:-false}

echo "Deploying URC"

docker run --rm \
  -e PRIVATE_KEY="0x94eb3102993b41ec55c241060f47daa0f6372e2e3ad7e91612ae36c364042e44" \
  -e FORK_URL="http://host.docker.internal:32003" \
  -e MIN_COLLATERAL_WEI="1000000000000000000" \
  -e FRAUD_PROOF_WINDOW="86400" \
  -e UNREGISTRATION_DELAY="86400" \
  -e SLASH_WINDOW="86400" \
  -e OPT_IN_DELAY="86400" \
  -e BROADCAST="$BROADCAST_OR_SIMULATION" \
  -e LOG_LEVEL="-vvvv" \
  -e BLOCK_GAS_LIMIT="20000000" \
  catalyst/urc ./script/deploy.sh

echo "Deployed URC"
