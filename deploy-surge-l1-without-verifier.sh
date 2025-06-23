#!/bin/bash

kurtosis service update surge-devnet deploy-surge-l1 \
    --env "SHOULD_SETUP_VERIFIERS=false"

kurtosis service exec surge-devnet deploy-surge-l1 "/app/script/layer1/surge/deploy_surge_l1.sh"

kurtosis service start surge-devnet deposit-bond
