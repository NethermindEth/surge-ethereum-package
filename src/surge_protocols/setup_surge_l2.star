def setup(
    plan,
    network_id,
    prefunded_accounts,
    protocol_params,
    surge_l1_deployment_result,
    surge_stack_rpc_url,
):
    # Setup surge L2
    setup_result = setup_surge_l2(
        plan,
        network_id,
        prefunded_accounts,
        protocol_params,
        surge_l1_deployment_result,
        surge_stack_rpc_url,
    )

    return setup_result

def setup_surge_l2(
    plan,
    network_id,
    prefunded_accounts,
    protocol_params,
    surge_l1_deployment_result,
    surge_stack_rpc_url,
):
    # Get the env vars for the setup
    env_vars = get_env_vars(
        network_id,
        prefunded_accounts,
        protocol_params,
        surge_l1_deployment_result,
        surge_stack_rpc_url,
        broadcast = "true",
    )

    # Set setup command
    cmd = [
        "sleep infinity && echo 'Waiting for surge L2 deployment to be executed once L2 stack is ready'",
    ]

    # Get the service config for the setup
    service_config = get_service_config(
        protocol_params,
        surge_l1_deployment_result,
        surge_stack_rpc_url,
        env_vars,
        cmd,
        need_ready_conditions = False,
    )

    # Setup surge L2
    result = plan.add_service(
        name = "setup-surge-l2",
        config = service_config,
        description = "Setup surge L2",
    )

    # TODO: Uncomment this when surge stack is available
    # Extract the result of the setup
    # result = plan.exec(
    #     service_name = "setup-surge-l2",
    #     recipe = ExecRecipe(
    #         command = ["/bin/sh", "-c", "cat /app/deployments/setup_l2.json"],
    #         extract = {
    #             "shared_resolver": "fromjson | .shared_resolver",
    #         }
    #     ),
    #     description = "Extract surge L2 setup result",
    # )

    # return struct(
    #     shared_resolver = result["extract.shared_resolver"],
    # )

    # TODO: Replace service result with deployment result
    return result

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
        "L1_BRIDGE": surge_l1_deployment_result.bridge,
        "L1_SIGNAL_SERVICE": surge_l1_deployment_result.signal_service,
        "L1_ERC20_VAULT": surge_l1_deployment_result.erc20_vault,
        "L1_ERC721_VAULT": surge_l1_deployment_result.erc721_vault,
        "L1_ERC1155_VAULT": surge_l1_deployment_result.erc1155_vault,
        # "L1_TIMELOCK_CONTROLLER": surge_l1_deployment_result.surge_timelock_controller,
        # Foundry Configuration
        "FOUNDRY_PROFILE": "layer2",

    }

    return env_vars

def get_service_config(
    protocol_params,
    surge_l1_deployment_result,
    surge_stack_rpc_url,
    env_vars,
    cmd,
    need_ready_conditions,
):
    # Set entrypoint
    entrypoint = [
        "/bin/sh",
        "-c",
    ]

    # Set ready conditions that checks if the deployment result file exists
    ready_conditions = ReadyCondition(
        recipe = ExecRecipe(
            command = ["test", "-f", "/app/deployments/setup_l2.json"]
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

    if need_ready_conditions:
        return ServiceConfig(
            image = protocol_params.image,
            entrypoint = entrypoint,
            cmd = cmd,
            env_vars = env_vars,
            ready_conditions = ready_conditions,
            labels = labels,
        )
    else:
        return ServiceConfig(
            image = protocol_params.image,
            entrypoint = entrypoint,
            cmd = cmd,
            env_vars = env_vars,
            labels = labels,
        )