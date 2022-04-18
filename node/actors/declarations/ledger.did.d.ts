import type { Principal } from '@dfinity/principal';
export interface AccountBalanceArgs { 'account' : AccountIdentifier__1 }
export type AccountIdentifier = Array<number>;
export type AccountIdentifier__1 = Array<number>;
export type BlockIndex = bigint;
export type Memo = bigint;
export interface Ledger {
  'account_balance' : (arg_0: AccountBalanceArgs) => Promise<Tokens>,
  'mint' : (
      arg_0: { 'to' : AccountIdentifier__1, 'amount' : Tokens },
    ) => Promise<BlockIndex>,
  'transfer' : (arg_0: TransferArgs) => Promise<TransferResult>,
  'zeroAccount' : (arg_0: Principal) => Promise<AccountIdentifier>,
}
export type SubAccount = Array<number>;
export interface TimeStamp { 'timestamp_nanos' : bigint }
export interface Tokens { 'e8s' : bigint }
export interface TransferArgs {
  'to' : AccountIdentifier__1,
  'fee' : Tokens,
  'memo' : Memo,
  'from_subaccount' : [] | [SubAccount],
  'created_at_time' : [] | [TimeStamp],
  'amount' : Tokens,
}
export type TransferError = {
    'TxTooOld' : { 'allowed_window_nanos' : bigint }
  } |
  { 'BadFee' : { 'expected_fee' : Tokens } } |
  { 'TxDuplicate' : { 'duplicate_of' : BlockIndex } } |
  { 'TxCreatedInFuture' : null } |
  { 'InsufficientFunds' : { 'balance' : Tokens } };
export type TransferResult = { 'Ok' : BlockIndex } |
  { 'Err' : TransferError };
export interface _SERVICE extends Ledger {}
