import Web3 from 'web3';
import { AbiItem } from 'web3-utils';

import { EXTERNAL_ACQUIRER, NftData } from './common';
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

const LOOKSRARE_EXCHANGE: { [name: string]: string } = {
  'mainnet': '0x59728544b08ab483533076417fbbb2fd0b17ce3a', // mainnet
  'rinkeby': '0x1AA777972073Ff66DCFDeD85749bDD555C0665dA', // rinkeby
}

const LOOKSRARE_STRATEGY_STANDARD_SALE_FOR_FIXED_PRICE: { [name: string]: string } = {
  'mainnet': '0x56244bb70cbd3ea9dc8007399f61dfc065190031', // mainnet
  'rinkeby': '0x732319A3590E4fA838C111826f9584a9A2fDEa1a', // rinkeby
}

function filterOrder(order: LooksrareOrder, network: string): boolean {
  return order.strategy === LOOKSRARE_STRATEGY_STANDARD_SALE_FOR_FIXED_PRICE[network];
}

function validateOrder(order: LooksrareOrder, network: string): void {
  const now = Math.floor(Date.now() / 1000);
  if (order.isOrderAsk !== true) throw new Error('Invalid isOrderAsk: ' + order.isOrderAsk);
  if (order.status !== 'VALID') throw new Error('Invalid status: ' + order.status);
  if (order.startTime > now) throw new Error('Invalid startTime: ' + order.startTime);
  if (order.endTime < now) throw new Error('Invalid endTime: ' + order.endTime);
}

function encodeCalldata(order: LooksrareOrder, acquirer: string, network: string): string {
  if (order.v === null) throw new Error('panic');
  if (order.r === null) throw new Error('panic');
  if (order.s === null) throw new Error('panic');
  const web3 = new Web3();
  const abi: AbiItem = {
      type: 'function',
      name: 'matchAskWithTakerBid',
      inputs: [
        {
          type: 'tuple',
          components: [
            { type: 'bool', name: 'isOrderAsk' },
            { type: 'address', name: 'taker' },
            { type: 'uint256', name: 'price' },
            { type: 'uint256', name: 'tokenId' },
            { type: 'uint256', name: 'minPercentageToAsk' },
            { type: 'bytes', name: 'params' },
          ],
          name: 'takerBid',
        },
        {
          type: 'tuple',
          "components": [
            { type: 'bool', name: 'isOrderAsk' },
            { type: 'address', name: 'signer' },
            { type: 'address', name: 'collection' },
            { type: 'uint256', name: 'price' },
            { type: 'uint256', name: 'tokenId' },
            { type: 'uint256', name: 'amount' },
            { type: 'address', name: 'strategy' },
            { type: 'address', name: 'currency' },
            { type: 'uint256', name: 'nonce' },
            { type: 'uint256', name: 'startTime' },
            { type: 'uint256', name: 'endTime' },
            { type: 'uint256', name: 'minPercentageToAsk' },
            { type: 'bytes', name: 'params' },
            { type: 'uint8', name: 'v' },
            { type: 'bytes32', name: 'r' },
            { type: 'bytes32', name: 's' },
          ],
          name: 'makerAsk',
        }
      ],
  };
  type Param = boolean | number | string | (boolean | number | string)[];
  const params: Param[] = [
    [
      false,
      acquirer,
      order.price,
      order.tokenId,
      order.minPercentageToAsk,
      '0x' + order.params,
    ],
    [
      true,
      order.signer,
      order.collectionAddress,
      order.price,
      order.tokenId,
      order.amount,
      order.strategy,
      order.currencyAddress,
      order.nonce,
      order.startTime,
      order.endTime,
      order.minPercentageToAsk,
      '0x' + order.params,
      order.v,
      order.r,
      order.s,
    ],
  ];
  const spender = LOOKSRARE_EXCHANGE[network] || '';
  const target = LOOKSRARE_EXCHANGE[network] || '';
  const _calldata = web3.eth.abi.encodeFunctionCall(abi, params as any); // type is incorrect on Web3
  return web3.eth.abi.encodeParameters(['address', 'address', 'bytes'], [spender, target, _calldata]);
}

function translateOrder(order: LooksrareOrder, network: string): NftData {
  if (!(TOKENS[network] || []).includes(order.currencyAddress)) throw new Error('panic');
  return {
    collection: order.collectionAddress,
    tokenId: BigInt(order.tokenId),
    price: BigInt(order.price),
    decimals: 18,
    paymentToken: order.currencyAddress,
    source: 'looksrare',
    data: encodeCalldata(order, EXTERNAL_ACQUIRER, network),
  };
}

export async function fetchNft(apiKey: string, collection: string, tokenId: bigint, network = 'mainnet', validate = false): Promise<NftData | null> {
  if (!['mainnet', 'rinkeby'].includes(network)) throw new Error('Unsupported network: ' + network);
  const testnet = network === 'rinkeby';
  const result = await listLooksrareOrders(apiKey, { collection, tokenId: String(tokenId), isOrderAsk: true }, testnet);
  if (!result.success || result.data === null) throw new Error(result.message || 'Missing data');
  if (result.data.length > 1) throw new Error('panic');
  const orders = result.data.filter((order) => filterOrder(order, network));
  if (validate) {
    orders.forEach((order) => validateOrder(order, network));
  }
  const items = orders.map((order) => translateOrder(order, network));
  return items[0] || null;
}
