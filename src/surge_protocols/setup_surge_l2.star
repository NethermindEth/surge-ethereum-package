def setup(
    plan,
    network_id,
    prefunded_accounts,
    protocol_params,
    surge_l1_deployment_result,
    surge_stack_rpc_url,
):
    # Get the env vars for the deployment
    env_vars = get_env_vars(
        network_id,
        prefunded_accounts,
        surge_l1_deployment_result,
        surge_stack_rpc_url,
        broadcast = "false",
    )

    # Setup surge L2
    plan.run_sh(
        run = "/app/script/layer2/surge/setup_surge_l2.sh",
        name = "setup-surge-l2",
        image = protocol_params.image,
        env_vars = env_vars,
        wait = None,
        description = "Setup surge L2",
    )

def get_env_vars(
    network_id,
    prefunded_accounts,
    protocol_params,
    surge_l1_deployment_result,
    surge_stack_rpc_url,
    broadcast,
):
    env_vars = {
        "BROADCAST": broadcast,
        # Core Configuration
        "PRIVATE_KEY": "0x{0}".format(prefunded_accounts[10].private_key),
        "FORK_URL": surge_stack_rpc_url,
        "LOG_LEVEL": protocol_params.protocol_log_level,
        "BLOCK_GAS_LIMIT": protocol_params.protocol_block_gas_limit,
        # L1 Configuration
        "L1_CHAINID": network_id,
        "L1_BRIDGE": surge_l1_deployment_result["bridge"],
        "L1_SIGNAL_SERVICE": surge_l1_deployment_result["signal_service"],
        "L1_ERC20_VAULT": surge_l1_deployment_result["erc20_vault"],
        "L1_ERC721_VAULT": surge_l1_deployment_result["erc721_vault"],
        "L1_ERC1155_VAULT": surge_l1_deployment_result["erc1155_vault"],
        "L1_TIMELOCK_CONTROLLER": surge_l1_deployment_result["surge_timelock_controller"],
        # Foundry Configuration
        "FOUNDRY_PROFILE": "layer2",

    }

    return env_vars