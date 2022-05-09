import { NftData } from './common';
import { hasProperty } from './utils';
import { serialize, httpGet } from './urlfetch';

type LooksrareOrder = {
  hash: string;
  collectionAddress: string;
  tokenId: string;
  isOrderAsk: boolean;
  signer: string;
  strategy: string;
  currencyAddress: string;
  amount: number;
  price: string;
  nonce: string;
  startTime: number;
  endTime: number;
  minPercentageToAsk: number;
  params: string;
  status: string;
  signature: string | null;
  v: number | null;
  r: string | null;
  s: string | null;
};

type ListLooksrareOrdersParams = {
  isOrderAsk?: boolean;
  collection?: string;
  tokenId?: string;
  signer?: string;
  strategy?: string;
  currency?: string;
  price?: {
    min?: string;
    max?: string;
  };
  startTime?: number;
  endTime?: number;
  status?: string[];
  pagination?: {
    first?: number;
    cursor?: string;
  };
  sort?: string;
};

type ListLooksrareOrdersResult = {
  success: boolean;
  message: string | null;
  data: LooksrareOrder[] | null;
};

function castLooksrareOrder(value: unknown): LooksrareOrder {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'hash')) throw new Error('panic');
  if (!hasProperty(value, 'collectionAddress')) throw new Error('panic');
  if (!hasProperty(value, 'tokenId')) throw new Error('panic');
  if (!hasProperty(value, 'isOrderAsk')) throw new Error('panic');
  if (!hasProperty(value, 'signer')) throw new Error('panic');
  if (!hasProperty(value, 'strategy')) throw new Error('panic');
  if (!hasProperty(value, 'currencyAddress')) throw new Error('panic');
  if (!hasProperty(value, 'amount')) throw new Error('panic');
  if (!hasProperty(value, 'price')) throw new Error('panic');
  if (!hasProperty(value, 'nonce')) throw new Error('panic');
  if (!hasProperty(value, 'startTime')) throw new Error('panic');
  if (!hasProperty(value, 'endTime')) throw new Error('panic');
  if (!hasProperty(value, 'minPercentageToAsk')) throw new Error('panic');
  if (!hasProperty(value, 'params')) throw new Error('panic');
  if (!hasProperty(value, 'status')) throw new Error('panic');
  if (!hasProperty(value, 'signature')) throw new Error('panic');
  if (!hasProperty(value, 'v')) throw new Error('panic');
  if (!hasProperty(value, 'r')) throw new Error('panic');
  if (!hasProperty(value, 's')) throw new Error('panic');
  const {
    hash,
    collectionAddress,
    tokenId,
    isOrderAsk,
    signer,
    strategy,
    currencyAddress,
    amount,
    price,
    nonce,
    startTime,
    endTime,
    minPercentageToAsk,
    params,
    status,
    signature,
    v,
    r,
    s,
  } = value;
  if (typeof hash !== 'string') throw new Error('panic');
  if (typeof collectionAddress !== 'string') throw new Error('panic');
  if (typeof tokenId !== 'string') throw new Error('panic');
  if (typeof isOrderAsk !== 'boolean') throw new Error('panic');
  if (typeof signer !== 'string') throw new Error('panic');
  if (typeof strategy !== 'string') throw new Error('panic');
  if (typeof currencyAddress !== 'string') throw new Error('panic');
  if (typeof amount !== 'number') throw new Error('panic');
  if (typeof price !== 'string') throw new Error('panic');
  if (typeof nonce !== 'string') throw new Error('panic');
  if (typeof startTime !== 'number') throw new Error('panic');
  if (typeof endTime !== 'number') throw new Error('panic');
  if (typeof minPercentageToAsk !== 'number') throw new Error('panic');
  if (typeof params !== 'string') throw new Error('panic');
  if (typeof status !== 'string') throw new Error('panic');
  if (signature !== null && typeof signature !== 'string') throw new Error('panic');
  if (v !== null && typeof v !== 'number') throw new Error('panic');
  if (r !== null && typeof r !== 'string') throw new Error('panic');
  if (s !== null && typeof s !== 'string') throw new Error('panic');
  return {
    hash,
    collectionAddress,
    tokenId,
    isOrderAsk,
    signer,
    strategy,
    currencyAddress,
    amount,
    price,
    nonce,
    startTime,
    endTime,
    minPercentageToAsk,
    params,
    status,
    signature,
    v,
    r,
    s,
  };
}

function castListLooksrareOrdersResult(value: unknown): ListLooksrareOrdersResult {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'success')) throw new Error('panic');
  if (!hasProperty(value, 'message')) throw new Error('panic');
  if (!hasProperty(value, 'data')) throw new Error('panic');
  const {
    success,
    message,
    data,
  } = value;
  if (typeof success !== 'boolean') throw new Error('panic');
  if (message !== null && typeof message !== 'string') throw new Error('panic');
  if (data !== null && !(data instanceof Array)) throw new Error('panic');
  const _data = data === null ? null : data.map(castLooksrareOrder);
  return {
    success,
    message: message,
    data: _data,
  };
}

async function listLooksrareOrders(apiKey: string/*unused*/, params: Partial<ListLooksrareOrdersParams> = {}, testnet = false): Promise<ListLooksrareOrdersResult> {
  const DEFAULT_PARAMS: ListLooksrareOrdersParams = {
    pagination: Object.assign({ first: 50 }, params.pagination || {}),
    status: ['VALID'],
    sort: 'NEWEST',
  };
  const _params: ListLooksrareOrdersParams = Object.assign({ ...DEFAULT_PARAMS }, params);
  const url = 'https://api' + (testnet ? '-rinkeby' : '') + '.looksrare.org/api/v1/orders?' + serialize(_params);
  const response = await httpGet(url);
  const result: unknown = JSON.parse(response);
  return castListLooksrareOrdersResult(result);
}

const TOKENS: { [name: string]: string[] } = {
  'mainnet': ['0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'],
  'rinkeby': ['0xc778417E063141139Fce010982780140Aa0cD5Ab'],
};

function translateOrder(order: LooksrareOrder, network: string): NftData {
  if (!(TOKENS[network] || []).includes(order.currencyAddress)) throw new Error('panic');
  return {
    collection: order.collectionAddress,
    tokenId: BigInt(order.tokenId),
    price: BigInt(order.price),
    decimals: 18,
    paymentToken: order.currencyAddress,
    source: 'looksrare',
    data: '',//encodeCalldata(order, EXTERNAL_ACQUIRER, String(price), metadata),
  };
}

export async function fetchNft(apiKey: string, collection: string, tokenId: bigint, network = 'mainnet', validate = false): Promise<NftData | null> {
  if (!['mainnet', 'rinkeby'].includes(network)) throw new Error('Unsupported network: ' + network);
  const testnet = network === 'rinkeby';
  const result = await listLooksrareOrders(apiKey, { collection, tokenId: String(tokenId), isOrderAsk: true }, testnet);
  if (!result.success || result.data === null) throw new Error(result.message || 'Missing data');
  if (result.data.length > 1) throw new Error('panic');
  const orders = result.data;//.filter(filterOrder);
  //if (validate) {
  //  orders.forEach((order) => validateOrder(order, network));
  //}
  const items = orders.map((order) => translateOrder(order, network));
  return items[0] || null;
}
