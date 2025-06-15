def deposit_bond(
    plan,
    prefunded_accounts,
    fuzz_target,
    protocol_params,
    surge_l1_deployment_result,
):
    # Get the service config for the deposit bond
    service_config = get_service_config(
        prefunded_accounts,
        fuzz_target,
        protocol_params,
        surge_l1_deployment_result,
    )

    # Deposit bond for prover and proposer key
    plan.add_service(
        name = "deposit-bond",
        config = service_config,
        description = "Deposit bond for prover and proposer key",
    )

    # Stop the deposit bond service
    plan.stop_service(
        name = "deposit-bond",
        description = "Stop deposit bond to wait for actual deploy surge L1",
    )

def get_service_config(
    prefunded_accounts,
    fuzz_target,
    protocol_params,
    surge_l1_deployment_result,
):
    # Set deposit bond image
    image = protocol_params.image

    # Set entrypoint
    entrypoint = [
        "/bin/sh",
        "-c",
    ]

    # Deposit bond for the contract deployer
    deposit_bond_cmd = "cast send {0} --value {1} --private-key {2} --rpc-url {3}".format(
        surge_l1_deployment_result.taiko,
        protocol_params.bond_eth_amount,
        # TODO: discuss about whether contract owner key is needed to deposit bond
        prefunded_accounts[10].private_key,
        fuzz_target,
    )

    # Sleep for 30 seconds to allow deposit bond to be stopped and ready to be started once surge L1 is actually deployed
    cmd = [
        "sleep 30 && echo 'Deposit bond will start in 30 seconds...' && {0}".format(
            deposit_bond_cmd,
        ),
    ]

    # Set labels for monitoring
    labels = {
        "logs_enabled": "true",
        "custom_network": "devnet",
    }

    return ServiceConfig(
        image = image,
        entrypoint = entrypoint,
        cmd = cmd,
        labels = labels,
    )