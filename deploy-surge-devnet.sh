#!/bin/bash

# Extract all prover parameters (SGX, RISC0, SP1) in one container call
eval $(docker run --rm \
  -v "$PWD:$PWD" \
  -w "$PWD" \
  mikefarah/yq \
  '.prover_params | to_entries | .[] | .key as $provider | .value | to_entries | .[] | ($provider | upcase) + "_" + (.key | upcase) + "=" + (.value | tostring)' \
  network_params.yaml)

kurtosis service update surge-devnet deploy-surge-l1 \
    --env "SHOULD_SETUP_VERIFIERS=false,RISC0_BLOCK_PROVING_IMAGE_ID=${RISC0_PARAMS_BLOCK_PROVING_IMAGE_ID},RISC0_AGGREGATION_IMAGE_ID=${RISC0_PARAMS_AGGREGATION_IMAGE_ID},SP1_BLOCK_PROVING_PROGRAM_VKEY=${SP1_PARAMS_BLOCK_PROVING_PROGRAM_VKEY},SP1_AGGREGATION_PROGRAM_VKEY=${SP1_PARAMS_AGGREGATION_PROGRAM_VKEY},MR_ENCLAVE=${SGX_PARAMS_MR_ENCLAVE},MR_SIGNER=${SGX_PARAMS_MR_SIGNER},V3_QUOTE_BYTES=${SGX_PARAMS_V3_QUOTE_BYTES}"

kurtosis service exec surge-devnet deploy-surge-l1 "/app/script/layer1/surge/deploy_surge_l1.sh"

kurtosis service start surge-devnet deposit-bond
