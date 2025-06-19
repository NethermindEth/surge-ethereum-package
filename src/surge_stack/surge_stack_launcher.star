# TODO: Uncomment these once L2 stack is ready
# nethermind_launcher = import_module("./main/nethermind_launcher.star")
# taiko_client_launcher = import_module("./main/taiko_client_launcher.star")
# blockscout_launcher = import_module("./extra/blockscout_launcher.star")
# relayer_launcher = import_module("./extra/relayer_launcher.star")
# bridge_launcher = import_module("./extra/bridge_launcher.star")
# safe_launcher = import_module("./extra/safe_infrastructure/safe_launcher.star")

constants = import_module("../package_io/constants.star")
surge_devnet_files = import_module("../surge_devnet_files/surge_devnet_files.star")

def launch_surge_main_stack(
    plan,
    network_id,
    all_el_contexts,
    all_cl_contexts,
    surge_l1_deployment_result,
):
    plan.print("network_id: {0}".format(network_id))
    plan.print("all_el_contexts: {0}".format(all_el_contexts))
    plan.print("all_cl_contexts: {0}".format(all_cl_contexts))
    plan.print("surge_l1_deployment_result: {0}".format(surge_l1_deployment_result))

    # Upload l2_chainspec.json to the files artifact
    plan.upload_files(
        # src = "github.com/NethermindEth/Surge/spec/surge-devnet/",
        src = surge_devnet_files.L2_STACK_FILEPATH,
        name = "surge-devnet-l2-stack-files",
        description = "Upload surge devnet l2 stack files",
    )

    # TODO: Remove this once L2 stack is ready
    # service = plan.add_service(
    #     name = "check-l2-stack-files",
    #     config = ServiceConfig(
    #         image = "alpine:latest",
    #         cmd = ["ls", "-la", "/l2-stack-files"],
    #         files = {
    #             "/l2-stack-files": "surge-devnet-l2-stack-files",
    #         },
    #     )
    # )
    
    # TODO: Nethermind EL
    # nethermind_el_context = nethermind_launcher.launch(
    #     plan,
    # )

    # TODO: Taiko Driver
    # taiko_driver_context = taiko_client_launcher.launch(
    #     plan,
    #     all_el_contexts,
    #     all_cl_contexts,
    #     surge_l1_deployment_result,
    #     nethermind_el_context,
    # )

    # TODO: Block Explorer
    # block_explorer_context = blockscout_launcher.launch(
    #     plan,
    # )

    # TODO: Taiko Proposers
    # taiko_proposer_context = taiko_client_launcher.launch(
    #     plan,
    #     all_el_contexts,
    #     all_cl_contexts,
    #     surge_l1_deployment_result,
    #     nethermind_el_context,
    #     type = "proposer",
    # )

    # TODO: Taiko Prover Relayer
    # taiko_prover_relayer_context = taiko_client_launcher.launch(
    #     plan,
    #     all_el_contexts,
    #     all_cl_contexts,
    #     surge_l1_deployment_result,
    #     nethermind_el_context,
    #     type = "prover-relayer",
    # )

def launch_surge_extra_stack(
    plan,
    network_id,
    all_el_contexts,
    all_cl_contexts,
    surge_l1_deployment_result,
):
    # TODO: Relayers
    # relayer_context = relayer_launcher.launch(
    #     plan,
    # )

    # TODO: Brige UI
    # bridge_context = bridge_launcher.launch(
    #     plan,
    # )

    # TODO: Safe Infrastructure
    # safe_context = safe_launcher.launch(
    #     plan,
    # )

    pass
