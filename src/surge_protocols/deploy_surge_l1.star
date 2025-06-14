def deploy(
    plan,
    prefunded_accounts,
    fork_url,
    protocol_params,
    prover_params,
):
    # TODO: Retrieve tcb info and qe identity files and save them in a files artifact
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

    plan.print("owner: {0}".format(prefunded_accounts[10]))
    
    # Simulate surge L1 deployment
    plan.run_sh(
        run = "/app/script/layer1/surge/deploy_surge_l1.sh",
        name = "deploy-surge-l1-simulation",
        image = protocol_params.image,
        env_vars = env_vars,
        store = [
            StoreSpec(
                src = "/app/deployments/deploy_l1.json",
                name = "simulation_result",
            )
        ],
        wait = None,
        description = "Simulate surge L1 deployment",
    )

    # Create a service to get the result of the simulation
    plan.add_service(
        name = "deploy-surge-l1-result",
        config = ServiceConfig(
            image = "badouralix/curl-jq",
            files = {
                "/result": "simulation_result",
            },
        ),
        description = "Start to extract surge L1 deployment result",
    )

    # Extract the result of the simulation
    result = plan.exec(
        service_name = "deploy-surge-l1-result",
        recipe = ExecRecipe(
            command = ["/bin/sh", "-c", "cat /result/deploy_l1.json"],
            extract = {
                "automata_dcap_attestation": "fromjson | .automata_dcap_attestation",
                "bridge": "fromjson | .bridge",
                "erc1155_vault": "fromjson | .erc1155_vault",
                "erc20_vault": "fromjson | .erc20_vault",
                "erc721_vault": "fromjson | .erc721_vault",
                "forced_inclusion_store": "fromjson | .forced_inclusion_store",
                "preconf_router": "fromjson | .preconf_router",
                "preconf_whitelist": "fromjson | .preconf_whitelist",
                "proof_verifier": "fromjson | .proof_verifier",
                "risc0_reth_verifier": "fromjson | .risc0_reth_verifier",
                "sgx_reth_verifier": "fromjson | .sgx_reth_verifier",
                "shared_resolver": "fromjson | .shared_resolver",
                "signal_service": "fromjson | .signal_service",
                "sp1_reth_verifier": "fromjson | .sp1_reth_verifier",
                "surge_timelock_controller": "fromjson | .surge_timelock_controller",
                "taiko": "fromjson | .taiko",
                "taiko_wrapper": "fromjson | .taiko_wrapper",
            }
        ),
        description = "Extract surge L1 deployment result",
    )

    plan.print("result: {0}".format(result["output"]))

    return result["output"]

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

    # Actually deploy surge L1
    plan.run_sh(
        run = "/app/script/layer1/surge/deploy_surge_l1.sh",
        name = "deploy-surge-l1",
        image = protocol_params.image,
        env_vars = env_vars,
        files = {
            "/app/test/sgx-assets": "sgx_files",
        },
        wait = None,
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
