# TODO: Uncomment these once L2 stack is ready
# nethermind_launcher = import_module("./main/nethermind_launcher.star")
# taiko_client_launcher = import_module("./main/taiko_client_launcher.star")
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
        src = "github.com/NethermindEth/Surge/spec/surge-hoodi/",
        # TODO: Replace with Surge repo path once https://github.com/NethermindEth/Surge/pull/116 is merged to main
        # src = surge_devnet_files.L2_STACK_FILEPATH,
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

    # TODO: Taiko Proposer

    # TODO: Taiko Prover Relayer

    return service

def launch_surge_extra_stack(
    plan,
    network_id,
    all_el_contexts,
    all_cl_contexts,
    surge_l1_deployment_result,
):
    # TODO: Relayer

    # TODO: Brige UI

    # TODO: Safe Infrastructure
    pass
