def deploy(
    plan,
    prefunded_accounts,
    fork_url,
    protocol_params,
    prover_params,
):
    # Retrieve tcb info and qe identity files and save them in a files artifact
    retrieve_and_save_sgx_files(
        plan,
        prover_params,
    )

    # Run simulation of deploy surge L1 first
    simulation_result = deploy_surge_l1_simulation(
        plan,
        prefunded_accounts,
        fork_url,
        protocol_params,
        prover_params,
    )

    # Actually deploy surge L1
    deploy_surge_l1(
        plan,
        prefunded_accounts,
        fork_url,
        protocol_params,
        prover_params,
    )

    return simulation_result

def retrieve_and_save_sgx_files(
    plan,
    prover_params,
):
    tcb_link = "https://api.trustedservices.intel.com/sgx/certification/v3/tcb?fmspc={0}".format(prover_params.fmspc)
    qe_identity_link = "https://api.trustedservices.intel.com/sgx/certification/v3/qe/identity"

    plan.run_sh(
        run = "mkdir -p /sgx-assets && curl {0} -o /sgx-assets/tcb_info.json && curl {1} -o /sgx-assets/qe_identity.json".format(tcb_link, qe_identity_link),
        name = "retrieve-sgx-files",
        image = "badouralix/curl-jq",
        store = [
            StoreSpec(
                src = "/sgx-assets",
                name = "sgx_files",
            ),
        ],
        wait = "180s",
        description = "Retrieve TCB info and QE identity files",
    )

    pass

def deploy_surge_l1_simulation(
    plan,
    prefunded_accounts,
    fork_url,
    protocol_params,
    prover_params,
):
    # Get the env vars for the simulation, set verifier setup to false and broadcast to false
    env_vars = get_env_vars(
        prefunded_accounts,
        fork_url,
        protocol_params,
        prover_params,
        verifier_setup = "false",
        broadcast = "false",
    )
    
    # Set simulation command
    cmd = [
        "/app/script/layer1/surge/deploy_surge_l1.sh && sleep 600",
    ]

    # Get the service config for the simulation
    service_config = get_service_config(
        protocol_params,
        env_vars,
        cmd,
        need_ready_conditions = True,
    )

    # Simulate surge L1 deployment
    plan.add_service(
        name = "deploy-surge-l1-simulation",
        config = service_config,
        description = "Simulate surge L1 deployment",
    )

    # Extract the result of the simulation
    result = plan.exec(
        service_name = "deploy-surge-l1-simulation",
        recipe = ExecRecipe(
            command = ["/bin/sh", "-c", "cat /app/deployments/deploy_l1.json"],
            extract = {
                # Contract addresses
                "automata_dcap_attestation": "fromjson | .automata_dcap_attestation",
                "bridge": "fromjson | .bridge",
                "erc1155_vault": "fromjson | .erc1155_vault",
                "erc20_vault": "fromjson | .erc20_vault",
                "erc721_vault": "fromjson | .erc721_vault",
                "forced_inclusion_store": "fromjson | .forced_inclusion_store",
                "pem_cert_chain_lib": "fromjson | .pem_cert_chain_lib",
                "preconf_router": "fromjson | .preconf_router",
                "preconf_whitelist": "fromjson | .preconf_whitelist",
                "proof_verifier": "fromjson | .proof_verifier",
                "risc0_reth_verifier": "fromjson | .risc0_reth_verifier",
                "sgx_reth_verifier": "fromjson | .sgx_reth_verifier",
                "shared_resolver": "fromjson | .shared_resolver",
                "sig_verify_lib": "fromjson | .sig_verify_lib",
                "signal_service": "fromjson | .signal_service",
                "sp1_reth_verifier": "fromjson | .sp1_reth_verifier",
                "surge_timelock_controller": "fromjson | .surge_timelock_controller",
                "taiko": "fromjson | .taiko",
                "taiko_wrapper": "fromjson | .taiko_wrapper",
            }
        ),
        description = "Extract surge L1 deployment result",
    )

    return struct(
        # Contract addresses as object
        automata_dcap_attestation = result["extract.automata_dcap_attestation"],
        bridge = result["extract.bridge"],
        erc1155_vault = result["extract.erc1155_vault"],
        erc20_vault = result["extract.erc20_vault"],
        erc721_vault = result["extract.erc721_vault"],
        forced_inclusion_store = result["extract.forced_inclusion_store"],
        pem_cert_chain_lib = result["extract.pem_cert_chain_lib"],
        preconf_router = result["extract.preconf_router"],
        preconf_whitelist = result["extract.preconf_whitelist"],
        proof_verifier = result["extract.proof_verifier"],
        risc0_reth_verifier = result["extract.risc0_reth_verifier"],
        sgx_reth_verifier = result["extract.sgx_reth_verifier"],
        sig_verify_lib = result["extract.sig_verify_lib"],
        signal_service = result["extract.signal_service"],
        sp1_reth_verifier = result["extract.sp1_reth_verifier"],
        surge_timelock_controller = result["extract.surge_timelock_controller"],
        taiko = result["extract.taiko"],
        taiko_wrapper = result["extract.taiko_wrapper"],
    )

def deploy_surge_l1(
    plan,
    prefunded_accounts,
    fork_url,
    protocol_params,
    prover_params,
):
    # Get the env vars for the deployment, set verifier setup to true and broadcast to true
    env_vars = get_env_vars(
        prefunded_accounts,
        fork_url,
        protocol_params,
        prover_params,
        verifier_setup = "true",
        broadcast = "true",
    )

    # Set deployment command
    cmd = [
        "sleep infinity && echo 'Waiting for surge L1 deployment to be executed once provers build info is provided'",
    ]

    # Get the service config for the deployment
    service_config = get_service_config(
        protocol_params,
        env_vars,
        cmd,
        need_ready_conditions = False,
    )

    # Actually deploy surge L1
    plan.add_service(
        name = "deploy-surge-l1",
        config = service_config,
        description = "Deploy surge L1",
    )

def get_env_vars(
    prefunded_accounts,
    fork_url,
    protocol_params,
    prover_params,
    verifier_setup,
    broadcast,
):
    env_vars = {
        "SHOULD_SETUP_VERIFIERS": verifier_setup,
        "BROADCAST": broadcast,
        # Core Configuration
        "PRIVATE_KEY": "0x{0}".format(prefunded_accounts[10].private_key),
        "FORK_URL": fork_url,
        "LOG_LEVEL": protocol_params.protocol_log_level,
        "BLOCK_GAS_LIMIT": protocol_params.protocol_block_gas_limit,
        # Owner and Executor Configuration
        "OWNER_MULTISIG": protocol_params.owner_multisig,
        "OWNER_MULTISIG_SIGNERS": protocol_params.owner_multisig_signers,
        "TIMELOCK_PERIOD": protocol_params.timelock_period,
        # DAO Configuration
        "DAO": protocol_params.dao,
        # L2 Configuration
        "L2_CHAINID": protocol_params.l2_chain_id,
        "L2_GENESIS_HASH": protocol_params.l2_genesis_hash,
        # Liveness Configuration
        "MAX_VERIFICATION_DELAY": protocol_params.liveness_max_verification_delay,
        "MIN_VERIFICATION_STREAK": protocol_params.liveness_min_verification_streak,
        "LIVENESS_BOND_BASE": protocol_params.liveness_bond_base,
        "LIVENESS_BOND_PER_BLOCK": protocol_params.liveness_bond_per_block,
        # Preconf Configuration
        "INCLUSION_WINDOW": protocol_params.preconf_inclusion_window,
        "INCLUSION_FEE_IN_GWEI": protocol_params.preconf_inclusion_fee_in_gwei,
        "FALLBACK_PRECONF": protocol_params.preconf_fallback_preconf,
        # RISC0 Verifier Configuration
        "RISC0_BLOCK_PROVING_IMAGE_ID": prover_params.block_proving_image_id,
        "RISC0_AGGREGATION_IMAGE_ID": prover_params.aggregation_image_id,
        # SP1 Verifier Configuration
        "SP1_BLOCK_PROVING_PROGRAM_VKEY": prover_params.block_proving_program_vkey,
        "SP1_AGGREGATION_PROGRAM_VKEY": prover_params.aggregation_program_vkey,
        # SGX Verifier Configuration
        "MR_ENCLAVE": prover_params.mr_enclave,
        "MR_SIGNER": prover_params.mr_signer,
        "QEID_PATH": prover_params.qeid_path,
        "TCB_INFO_PATH": prover_params.tcb_info_path,
        "V3_QUOTE_BYTES": prover_params.v3_quote_bytes,
        # Foundry Configuration
        "FOUNDRY_PROFILE": "layer1",
    }

    return env_vars

def get_service_config(
    protocol_params,
    env_vars,
    cmd,
    need_ready_conditions,
):
    # Mount sgx files
    files = {
        "/app/test/sgx-assets": "sgx_files",
    }

    # Set entrypoint
    entrypoint = [
        "/bin/sh",
        "-c",
    ]

    # Set ready conditions that checks if the deployment result file exists
    ready_conditions = ReadyCondition(
        recipe = ExecRecipe(
            command = ["test", "-f", "/app/deployments/deploy_l1.json"]
        ),
        field = "code",
        assertion = "==",
        target_value = 0,
        interval = "10s",
        timeout = "120s",
    )

    # Set labels for monitoring
    labels = {
        "logs_enabled": "true",
        "custom_network": "devnet",
    }

    # Return the service config with ready conditions if needed
    if need_ready_conditions:
        return ServiceConfig(
            image = protocol_params.image,
            files = files,
            entrypoint = entrypoint,
            cmd = cmd,
            env_vars = env_vars,
            ready_conditions = ready_conditions,
            labels = labels,
        )
    else:
        return ServiceConfig(
            image = protocol_params.image,
            files = files,
            entrypoint = entrypoint,
            cmd = cmd,
            env_vars = env_vars,
            labels = labels,
        )
