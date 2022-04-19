import type { Principal } from '@dfinity/principal';
export type AccountIdentifier = string;
export type AccountIdentifier__1 = Array<number>;
export interface ApproveRequest {
  'token' : TokenIdentifier,
  'subaccount' : [] | [SubAccount],
  'allowance' : Balance,
  'spender' : Principal,
}
export interface Asset {
  'contentType' : string,
  'payload' : Array<Array<number>>,
}
export interface Backup {
  'lowestPriceSale' : [] | [bigint],
  'highestPriceSale' : [] | [bigint],
  'totalVolume' : [] | [bigint],
  'listings' : [] | [Array<[TokenIndex, Listing]>],
  'nextSubAccount' : [] | [bigint],
  'transactions' : [] | [Array<[bigint, Transaction]>],
  'pendingDisbursements' : [] | [
    Array<[TokenIndex, AccountIdentifier, SubAccount, bigint]>
  ],
  'pendingTransactions' : [] | [Array<[TokenIndex, Transaction]>],
  '_usedPaymentAddresses' : [] | [
    Array<[AccountIdentifier, Principal, SubAccount]>
  ],
}
export type Balance = bigint;
export type BearerResponse = { 'ok' : AccountIdentifier } |
  { 'err' : CommonError };
export type BlockHeight = bigint;
export type BlockIndex = bigint;
export type CanisterCyclesAggregatedData = Array<bigint>;
export type CanisterHeapMemoryAggregatedData = Array<bigint>;
export type CanisterLogFeature = { 'filterMessageByContains' : null } |
  { 'filterMessageByRegex' : null };
export interface CanisterLogMessages {
  'data' : Array<LogMessagesData>,
  'lastAnalyzedMessageTimeNanos' : [] | [Nanos],
}
export interface CanisterLogMessagesInfo {
  'features' : Array<[] | [CanisterLogFeature]>,
  'lastTimeNanos' : [] | [Nanos],
  'count' : number,
  'firstTimeNanos' : [] | [Nanos],
}
export type CanisterLogRequest = { 'getMessagesInfo' : null } |
  { 'getMessages' : GetLogMessagesParameters } |
  { 'getLatestMessages' : GetLatestLogMessagesParameters };
export type CanisterLogResponse = { 'messagesInfo' : CanisterLogMessagesInfo } |
  { 'messages' : CanisterLogMessages };
export type CanisterMemoryAggregatedData = Array<bigint>;
export interface CanisterMetrics { 'data' : CanisterMetricsData }
export type CanisterMetricsData = { 'hourly' : Array<HourlyMetricsData> } |
  { 'daily' : Array<DailyMetricsData> };
export interface Color {
  'background' : string,
  'base' : string,
  'name' : string,
  'specular' : string,
  'emissive' : string,
}
export type CommonError = { 'InvalidToken' : TokenIdentifier } |
  { 'Other' : string };
export interface DailyMetricsData {
  'updateCalls' : bigint,
  'canisterHeapMemorySize' : NumericEntity,
  'canisterCycles' : NumericEntity,
  'canisterMemorySize' : NumericEntity,
  'timeMillis' : bigint,
}
export type DetailsResponse = { 'ok' : [AccountIdentifier, [] | [Listing]] } |
  { 'err' : CommonError };
export type Disbursement = [TokenIndex, AccountIdentifier, SubAccount, bigint];
export interface EntrepotTransaction {
  'token' : TokenIdentifier,
  'time' : Time,
  'seller' : Principal,
  'buyer' : AccountIdentifier,
  'price' : bigint,
}
export interface ExtListing {
  'locked' : [] | [Time],
  'seller' : Principal,
  'price' : bigint,
}
export type FilePath = string;
export interface GetLatestLogMessagesParameters {
  'upToTimeNanos' : [] | [Nanos],
  'count' : number,
  'filter' : [] | [GetLogMessagesFilter],
}
export interface GetLogMessagesFilter {
  'analyzeCount' : number,
  'messageRegex' : [] | [string],
  'messageContains' : [] | [string],
}
export interface GetLogMessagesParameters {
  'count' : number,
  'filter' : [] | [GetLogMessagesFilter],
  'fromTimeNanos' : [] | [Nanos],
}
export interface GetMetricsParameters {
  'dateToMillis' : bigint,
  'granularity' : MetricsGranularity,
  'dateFromMillis' : bigint,
}
export type HeaderField = [string, string];
export interface HourlyMetricsData {
  'updateCalls' : UpdateCallsAggregatedData,
  'canisterHeapMemorySize' : CanisterHeapMemoryAggregatedData,
  'canisterCycles' : CanisterCyclesAggregatedData,
  'canisterMemorySize' : CanisterMemoryAggregatedData,
  'timeMillis' : bigint,
}
export interface ICP { 'e8s' : bigint }
export interface LegendsNFT {
  'addAdmin' : (arg_0: Principal) => Promise<undefined>,
  'address' : () => Promise<[Array<number>, string]>,
  'allowance' : (arg_0: Request__1) => Promise<Response__1>,
  'approve' : (arg_0: ApproveRequest) => Promise<undefined>,
  'assetsBackup' : () => Promise<State>,
  'assetsRestore' : (arg_0: State) => Promise<undefined>,
  'assetsTag' : (arg_0: Array<[string, Array<string>]>) => Promise<undefined>,
  'balance' : () => Promise<ICP>,
  'bearer' : (arg_0: TokenIdentifier) => Promise<BearerResponse>,
  'collectCanisterMetrics' : () => Promise<undefined>,
  'configureColors' : (arg_0: Array<Color>) => Promise<undefined>,
  'configureMetadata' : (arg_0: Array<Metadata>) => Promise<Result>,
  'configureNri' : (arg_0: Array<[string, number]>) => Promise<undefined>,
  'configurePublicSalePrice' : (arg_0: bigint, arg_1: bigint) => Promise<
      undefined
    >,
  'deleteDisbursementJob' : (
      arg_0: TokenIndex,
      arg_1: AccountIdentifier,
      arg_2: bigint,
    ) => Promise<undefined>,
  'deleteListing' : (arg_0: TokenIndex) => Promise<undefined>,
  'details' : (arg_0: TokenIdentifier) => Promise<DetailsResponse>,
  'disbursementPendingCount' : () => Promise<bigint>,
  'disbursementQueueSize' : () => Promise<bigint>,
  'entrepotRestore' : (arg_0: Backup) => Promise<undefined>,
  'getAdmins' : () => Promise<Array<Principal>>,
  'getAllowlist' : () => Promise<Array<[AccountIdentifier__1, number]>>,
  'getCanisterLog' : (arg_0: [] | [CanisterLogRequest]) => Promise<
      [] | [CanisterLogResponse]
    >,
  'getCanisterMetrics' : (arg_0: GetMetricsParameters) => Promise<
      [] | [CanisterMetrics]
    >,
  'getRegistry' : () => Promise<Array<[TokenIndex, AccountIdentifier]>>,
  'getTokens' : () => Promise<Array<[TokenIndex, Metadata__1]>>,
  'heartbeatSetInterval' : (arg_0: bigint) => Promise<undefined>,
  'heartbeatSwitch' : (arg_0: boolean) => Promise<undefined>,
  'http_request' : (arg_0: Request) => Promise<Response>,
  'init' : () => Promise<Result>,
  'isAdmin' : (arg_0: Principal) => Promise<boolean>,
  'isPresale' : () => Promise<boolean>,
  'list' : (arg_0: ListRequest) => Promise<ListResponse>,
  'listings' : () => Promise<ListingsResponse>,
  'lock' : (
      arg_0: TokenIdentifier,
      arg_1: bigint,
      arg_2: AccountIdentifier,
      arg_3: Array<number>,
    ) => Promise<LockResponse>,
  'metadata' : (arg_0: TokenIdentifier) => Promise<MetadataResponse>,
  'mint' : (arg_0: User) => Promise<Result_6>,
  'nnsTransfer' : (arg_0: ICP, arg_1: string, arg_2: Memo__1) => Promise<
      TransferResult
    >,
  'payments' : () => Promise<[] | [Array<SubAccount>]>,
  'paymentsRaw' : () => Promise<Array<[bigint, Transaction]>>,
  'publicSaleBackup' : () => Promise<
      {
        'locks' : Array<[TxId, Lock]>,
        'purchases' : Array<[TxId, Purchase]>,
        'allowlist' : Array<[AccountIdentifier__1, number]>,
        'refunds' : Array<[TxId, Refund]>,
        'nextTxId' : TxId,
      }
    >,
  'publicSaleGetAvailable' : () => Promise<bigint>,
  'publicSaleGetPrice' : () => Promise<bigint>,
  'publicSaleLock' : (arg_0: bigint) => Promise<Result_5>,
  'publicSaleNotify' : (arg_0: bigint, arg_1: BlockHeight) => Promise<Result_4>,
  'publicSaleProcessRefunds' : (arg_0: Array<NNSTransaction>) => Promise<
      Result
    >,
  'publicSaleRestore' : (
      arg_0: {
        'presale' : [] | [boolean],
        'pricePrivateE8s' : [] | [bigint],
        'locks' : [] | [Array<[TxId, Lock]>],
        'purchases' : [] | [Array<[TxId, Purchase]>],
        'pricePublicE8s' : [] | [bigint],
        'allowlist' : [] | [Array<[AccountIdentifier__1, number]>],
        'refunds' : [] | [Array<[TxId, Refund]>],
        'nextTxId' : [] | [TxId],
      },
    ) => Promise<undefined>,
  'purgeAssets' : (arg_0: string, arg_1: [] | [string]) => Promise<Result>,
  'readDisbursements' : () => Promise<Array<Disbursement>>,
  'readLedger' : () => Promise<Array<[] | [Token]>>,
  'readMeta' : () => Promise<Array<Metadata>>,
  'readPending' : () => Promise<Array<[TokenIndex, Transaction]>>,
  'removeAdmin' : (arg_0: Principal) => Promise<undefined>,
  'setAllowlist' : (arg_0: Array<[string, number]>) => Promise<undefined>,
  'settle' : (arg_0: TokenIdentifier) => Promise<Result_3>,
  'shuffleMetadata' : () => Promise<undefined>,
  'stats' : () => Promise<
      [bigint, bigint, bigint, bigint, bigint, bigint, bigint]
    >,
  'togglePresale' : (arg_0: boolean) => Promise<undefined>,
  'tokenId' : (arg_0: TokenIndex) => Promise<TokenIdentifier>,
  'tokens' : (arg_0: AccountIdentifier) => Promise<Result_2>,
  'tokensBackup' : () => Promise<LocalStableState>,
  'tokensRestore' : (arg_0: LocalStableState) => Promise<Result>,
  'tokens_ext' : (arg_0: AccountIdentifier) => Promise<Result_1>,
  'transactions' : () => Promise<Array<EntrepotTransaction>>,
  'transfer' : (arg_0: TransferRequest) => Promise<TransferResponse>,
  'upload' : (arg_0: Array<Array<number>>) => Promise<undefined>,
  'uploadClear' : () => Promise<undefined>,
  'uploadFinalize' : (arg_0: string, arg_1: Meta) => Promise<Result>,
}
export interface ListRequest {
  'token' : TokenIdentifier,
  'from_subaccount' : [] | [SubAccount],
  'price' : [] | [bigint],
}
export type ListResponse = { 'ok' : null } |
  { 'err' : CommonError };
export interface Listing {
  'subaccount' : [] | [SubAccount],
  'locked' : [] | [Time],
  'seller' : Principal,
  'price' : bigint,
}
export type ListingsResponse = Array<[TokenIndex, ExtListing, Metadata__2]>;
export interface LocalStableState {
  'metadata' : Array<Metadata>,
  'tokens' : Array<[] | [Token]>,
  'isShuffled' : boolean,
}
export interface Lock {
  'id' : TxId,
  'token' : TokenIndex__1,
  'buyerAccount' : string,
  'memo' : bigint,
  'lockedAt' : Time,
  'buyer' : Principal,
}
export type LockResponse = { 'ok' : AccountIdentifier } |
  { 'err' : CommonError };
export interface LogMessagesData { 'timeNanos' : Nanos, 'message' : string }
export type Memo = Array<number>;
export type Memo__1 = bigint;
export interface Meta {
  'name' : string,
  'tags' : Array<Tag>,
  'description' : string,
  'filename' : FilePath,
}
export interface Metadata { 'ink' : string, 'back' : string, 'border' : string }
export type MetadataResponse = { 'ok' : Metadata__1 } |
  { 'err' : CommonError };
export type Metadata__1 = {
    'fungible' : {
      'decimals' : number,
      'metadata' : [] | [Array<number>],
      'name' : string,
      'symbol' : string,
    }
  } |
  { 'nonfungible' : { 'metadata' : [] | [Array<number>] } };
export type Metadata__2 = {
    'fungible' : {
      'decimals' : number,
      'metadata' : [] | [Array<number>],
      'name' : string,
      'symbol' : string,
    }
  } |
  { 'nonfungible' : { 'metadata' : [] | [Array<number>] } };
export type MetricsGranularity = { 'hourly' : null } |
  { 'daily' : null };
export interface NNSTransaction {
  'from' : string,
  'memo' : bigint,
  'blockheight' : bigint,
  'timestamp' : Time,
  'amount' : bigint,
}
export type Nanos = bigint;
export interface NumericEntity {
  'avg' : bigint,
  'max' : bigint,
  'min' : bigint,
  'first' : bigint,
  'last' : bigint,
}
export interface Purchase {
  'id' : TxId,
  'token' : TokenIndex__1,
  'buyerAccount' : string,
  'memo' : bigint,
  'blockheight' : BlockHeight,
  'closedAt' : Time,
  'lockedAt' : Time,
  'buyer' : Principal,
  'price' : bigint,
}
export interface Record { 'asset' : Asset, 'meta' : Meta }
export interface Refund {
  'id' : TxId,
  'buyer' : string,
  'transactions' : { 'original' : NNSTransaction, 'refund' : NNSTransaction },
}
export interface Request {
  'url' : string,
  'method' : string,
  'body' : Array<number>,
  'headers' : Array<HeaderField>,
}
export interface Request__1 {
  'token' : TokenIdentifier,
  'owner' : User,
  'spender' : Principal,
}
export interface Response {
  'body' : Array<number>,
  'headers' : Array<HeaderField>,
  'streaming_strategy' : [] | [StreamingStrategy],
  'status_code' : number,
}
export type Response__1 = { 'ok' : Balance } |
  { 'err' : CommonError };
export type Result = { 'ok' : null } |
  { 'err' : string };
export type Result_1 = {
    'ok' : Array<[TokenIndex, [] | [Listing], [] | [Array<number>]]>
  } |
  { 'err' : CommonError };
export type Result_2 = { 'ok' : Array<TokenIndex> } |
  { 'err' : CommonError };
export type Result_3 = { 'ok' : null } |
  { 'err' : CommonError };
export type Result_4 = { 'ok' : TokenIndex } |
  { 'err' : string };
export type Result_5 = { 'ok' : TxId } |
  { 'err' : string };
export type Result_6 = { 'ok' : bigint } |
  { 'err' : string };
export interface State { 'assets' : Array<Record>, 'colors' : Array<Color> }
export type StreamingCallback = (arg_0: StreamingCallbackToken) => Promise<
    StreamingCallbackResponse
  >;
export interface StreamingCallbackResponse {
  'token' : [] | [StreamingCallbackToken],
  'body' : Array<number>,
}
export interface StreamingCallbackToken {
  'key' : string,
  'index' : bigint,
  'content_encoding' : string,
}
export type StreamingStrategy = {
    'Callback' : {
      'token' : StreamingCallbackToken,
      'callback' : StreamingCallback,
    }
  };
export type SubAccount = Array<number>;
export type Tag = string;
export type Time = bigint;
export interface Token {
  'owner' : AccountIdentifier,
  'createdAt' : bigint,
  'txId' : string,
}
export type TokenIdentifier = string;
export type TokenIndex = number;
export type TokenIndex__1 = number;
export interface Transaction {
  'id' : bigint,
  'to' : AccountIdentifier,
  'closed' : [] | [Time],
  'token' : TokenIdentifier,
  'initiated' : Time,
  'from' : AccountIdentifier,
  'memo' : [] | [Array<number>],
  'seller' : Principal,
  'bytes' : Array<number>,
  'price' : bigint,
}
export type TransferError = {
    'TxTooOld' : { 'allowed_window_nanos' : bigint }
  } |
  { 'BadFee' : { 'expected_fee' : ICP } } |
  { 'TxDuplicate' : { 'duplicate_of' : BlockIndex } } |
  { 'TxCreatedInFuture' : null } |
  { 'InsufficientFunds' : { 'balance' : ICP } };
export interface TransferRequest {
  'to' : User,
  'token' : TokenIdentifier,
  'notify' : boolean,
  'from' : User,
  'memo' : Memo,
  'subaccount' : [] | [SubAccount],
  'amount' : Balance,
}
export type TransferResponse = { 'ok' : Balance } |
  {
    'err' : { 'CannotNotify' : AccountIdentifier } |
      { 'InsufficientBalance' : null } |
      { 'InvalidToken' : TokenIdentifier } |
      { 'Rejected' : null } |
      { 'Unauthorized' : AccountIdentifier } |
      { 'Other' : string }
  };
export type TransferResult = { 'Ok' : BlockIndex } |
  { 'Err' : TransferError };
export type TxId = number;
export type UpdateCallsAggregatedData = Array<bigint>;
export type User = { 'principal' : Principal } |
  { 'address' : AccountIdentifier };
export interface _SERVICE extends LegendsNFT {}
export interface LegendManifest {
  'ink' : Tag,
  'nri' : {
    'avg' : number,
    'ink' : number,
    'back' : number,
    'border' : number,
  },
  'views' : {
    'interactive' : FilePath,
    'flat' : FilePath,
    'animated' : FilePath,
    'sideBySide' : FilePath,
  },
  'back' : Tag,
  'maps' : {
    'normal' : FilePath,
    'back' : FilePath,
    'mask' : [] | [FilePath],
    'layers' : Array<FilePath>,
    'border' : FilePath,
  },
  'mask' : Tag,
  'border' : Tag,
  'stock' : Tag,
  'colors' : {
    'background' : string,
    'base' : string,
    'specular' : string,
    'emissive' : string,
  },
  'stockColors' : { 'base' : string, 'specular' : string, 'emissive' : string },
}