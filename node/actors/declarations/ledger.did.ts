import { IDL } from '@dfinity/candid';

export const idlFactory : IDL.InterfaceFactory = ({ IDL }) => {
  const AccountIdentifier__1 = IDL.Vec(IDL.Nat8);
  const AccountBalanceArgs = IDL.Record({ 'account' : AccountIdentifier__1 });
  const Tokens = IDL.Record({ 'e8s' : IDL.Nat64 });
  const BlockIndex = IDL.Nat64;
  const Memo = IDL.Nat64;
  const SubAccount = IDL.Vec(IDL.Nat8);
  const TimeStamp = IDL.Record({ 'timestamp_nanos' : IDL.Nat64 });
  const TransferArgs = IDL.Record({
    'to' : AccountIdentifier__1,
    'fee' : Tokens,
    'memo' : Memo,
    'from_subaccount' : IDL.Opt(SubAccount),
    'created_at_time' : IDL.Opt(TimeStamp),
    'amount' : Tokens,
  });
  const TransferError = IDL.Variant({
    'TxTooOld' : IDL.Record({ 'allowed_window_nanos' : IDL.Nat64 }),
    'BadFee' : IDL.Record({ 'expected_fee' : Tokens }),
    'TxDuplicate' : IDL.Record({ 'duplicate_of' : BlockIndex }),
    'TxCreatedInFuture' : IDL.Null,
    'InsufficientFunds' : IDL.Record({ 'balance' : Tokens }),
  });
  const TransferResult = IDL.Variant({
    'Ok' : BlockIndex,
    'Err' : TransferError,
  });
  const AccountIdentifier = IDL.Vec(IDL.Nat8);
  const MockLedger = IDL.Service({
    'account_balance' : IDL.Func([AccountBalanceArgs], [Tokens], ['query']),
    'mint' : IDL.Func(
        [IDL.Record({ 'to' : AccountIdentifier__1, 'amount' : Tokens })],
        [BlockIndex],
        [],
      ),
    'transfer' : IDL.Func([TransferArgs], [TransferResult], []),
    'zeroAccount' : IDL.Func([IDL.Principal], [AccountIdentifier], ['query']),
  });
  return MockLedger;
};
