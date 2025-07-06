#!/bin/bash
set -e

echo "Preparing surge devnet"

kurtosis run --enclave surge-devnet . --args-file network_params.yaml --production

echo "Successfully prepared surge devnet"
