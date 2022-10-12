import { IDL } from "@dfinity/candid";

export const idlFactory: IDL.InterfaceFactory = ({ IDL }) => {
    const WithWitnessArg = IDL.Record({ witness: IDL.Bool });
    const Witness = IDL.Record({
        certificate: IDL.Vec(IDL.Nat8),
        tree: IDL.Vec(IDL.Nat8),
    });
    const GetIndexCanistersResponse = IDL.Record({
        witness: IDL.Opt(Witness),
        canisters: IDL.Vec(IDL.Principal),
    });
    const GetTokenContractRootBucketArg = IDL.Record({
        witness: IDL.Bool,
        canister: IDL.Principal,
    });
    const GetTokenContractRootBucketResponse = IDL.Record({
        witness: IDL.Opt(Witness),
        canister: IDL.Opt(IDL.Principal),
    });
    const GetUserRootBucketsArg = IDL.Record({
        user: IDL.Principal,
        witness: IDL.Bool,
    });
    const GetUserRootBucketsResponse = IDL.Record({
        witness: IDL.Opt(Witness),
        contracts: IDL.Vec(IDL.Principal),
    });
    return IDL.Service({
        balance: IDL.Func([], [IDL.Nat64], []),
        deploy_plug_bucket: IDL.Func([IDL.Principal, IDL.Nat64], [], []),
        get_index_canisters: IDL.Func(
            [WithWitnessArg],
            [GetIndexCanistersResponse],
            ["query"]
        ),
        get_token_contract_root_bucket: IDL.Func(
            [GetTokenContractRootBucketArg],
            [GetTokenContractRootBucketResponse],
            ["query"]
        ),
        get_user_root_buckets: IDL.Func(
            [GetUserRootBucketsArg],
            [GetUserRootBucketsResponse],
            ["query"]
        ),
        insert_new_users: IDL.Func(
            [IDL.Principal, IDL.Vec(IDL.Principal)],
            [],
            []
        ),
        install_bucket_code: IDL.Func([IDL.Principal], [], []),
        trigger_upgrade: IDL.Func([], [], []),
    });
};
