import 'source-map-support/register';
import axios from 'axios';
import Web3 from 'web3';
import { AbiItem } from 'web3-utils';

function serialize(params: { [name: string]: string[] | string | number | boolean }): string {
  return Object.keys(params)
    .filter((name) => params[name] !== undefined)
    .map((name) => {
      const value = params[name];
      if (value === undefined) throw new Error('panic');
      if (value instanceof Array) {
        const list: string[] = [];
        for (const v of value) {
          list.push(encodeURIComponent(name) + '=' + encodeURIComponent(v));
        }
        return list.join('&');
      }
      return encodeURIComponent(name) + '=' + encodeURIComponent(value);
    })
    .join('&');
}

function httpGet(url: string, headers: { [name: string]: string } = {}): Promise<string> {
  return new Promise((resolve, reject) => {
    axios.get(url, { headers, transformResponse: (data) => data })
      .then((response) => resolve(response.data))
      .catch((error) => reject(new Error(error.response.statusText)));
  });
}

function sleep(delay: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, delay));
}

type OpenseaUser = {
//  user: {
//    username: string;
//  } | null;
//  profile_img_url: string;
  address: string;
//  config: string;
};

type OpenseaAssetContract = {
  address: string;
//  asset_contract_type: string;
//  created_date: string;
//  name: string;
//  nft_version: string;
//  opensea_version: null;
//  owner: number;
  schema_name: string;
//  symbol: string;
//  total_supply: string;
//  description: string;
//  external_link: string;
//  image_url: string;
//  default_to_fiat: boolean;
//  dev_buyer_fee_basis_points: number;
//  dev_seller_fee_basis_points: number;
//  only_proxied_transfers: boolean;
//  opensea_buyer_fee_basis_points: number;
//  opensea_seller_fee_basis_points: number;
//  buyer_fee_basis_points: number;
//  seller_fee_basis_points: number;
//  payout_address: string;
};

type OpenseaAsset = {
//  id: number;
//  num_sales: number;
//  background_color: null;
//  image_url: string;
//  image_preview_url: string;
//  image_thumbnail_url: string;
//  image_original_url: string;
//  animation_url: string;
//  animation_original_url: string;
//  name: null;
//  description: null;
//  external_link: null;
  asset_contract: OpenseaAssetContract;
//  permalink: string;
//  collection: {
//    banner_image_url: string;
//    chat_url: null;
//    created_date: string;
//    default_to_fiat: boolean;
//    description: string;
//    dev_buyer_fee_basis_points: string;
//    dev_seller_fee_basis_points: string;
//    discord_url: string;
//    display_data: {
//      card_display_style: string;
//    };
//    external_url: string;
//    featured: boolean;
//    featured_image_url: string;
//    hidden: boolean;
//    safelist_request_status: string;
//    image_url: string;
//    is_subject_to_whitelist: boolean;
//    large_image_url: string;
//    medium_username: null;
//    name: string;
//    only_proxied_transfers: boolean;
//    opensea_buyer_fee_basis_points: string;
//    opensea_seller_fee_basis_points: string;
//    payout_address: string;
//    require_email: boolean;
//    short_description: null;
//    slug: string;
//    telegram_url: null;
//    twitter_username: null;
//    instagram_username: string;
//    wiki_url: null;
//  };
//  decimals: 0;
//  token_metadata: string;
//  owner: OpenseaUser;
  token_id: string;
};

type OpenseaPaymentTokenContract = {
//  id: number;
//  symbol: string;
//  address: string;
//  image_url: string;
//  name: string;
  decimals: number;
//  eth_price: string;
//  usd_price: string;
};

type OpenseaOrder = {
//  id: number;
  asset: OpenseaAsset | null;
//  asset_bundle: null;
//  created_date: string;
//  closing_date: string;
//  closing_extendable: boolean;
  expiration_time: number;
  listing_time: number;
//  order_hash: string;
//  metadata: {
//    asset: {
//      id: string;
//      address: string;
//    };
//    schema: string;
//    referrerAddress: string;
//  };
  exchange: string;
  maker: OpenseaUser;
  taker: OpenseaUser;
  current_price: string;
//  current_bounty: string;
//  bounty_multiple: string;
  maker_relayer_fee: string;
  taker_relayer_fee: string;
  maker_protocol_fee: string;
  taker_protocol_fee: string;
//  maker_referrer_fee: string;
  fee_recipient: OpenseaUser;
  fee_method: number;
  side: number;
  sale_kind: number;
  target: string;
  how_to_call: number;
  calldata: string;
  replacement_pattern: string;
  static_target: string;
  static_extradata: string;
  payment_token: string;
  payment_token_contract: OpenseaPaymentTokenContract;
  base_price: string;
  extra: string;
//  quantity: string;
  salt: string;
  v: number | null;
  r: string | null;
  s: string | null;
  approved_on_chain: boolean;
  cancelled: boolean;
  finalized: boolean;
  marked_invalid: boolean;
//  prefixed_hash: string;
};

type ListOpenseaOrdersParams = {
  asset_contract_address?: string;
  payment_token_address?: string;
  maker?: string;
  taker?: string;
  owner?: string;
  is_english?: boolean;
  bundled: boolean;
  include_bundled: boolean;
  include_invalid: boolean;
  listed_after?: number;
  listed_before?: number;
  token_id?: string;
  token_ids?: string[];
  side?: number;
  sale_kind?: number;
  limit: number;
  offset: number;
  order_by: string;
  order_direction: string;
};

type ListOpenseaOrdersResult = {
  count: number;
  orders: OpenseaOrder[];
};

function hasProperty<K extends string | number | symbol>(value: NonNullable<object>, property: K): value is { [property in K]: unknown } {
  return property in value;
}

function castOpenseaUser(value: unknown): OpenseaUser {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'address')) throw new Error('panic');
  const {
    address,
  } = value;
  if (typeof address !== 'string') throw new Error('panic');
  return {
    address,
  };
}

function castOpenseaAssetContract(value: unknown): OpenseaAssetContract {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'address')) throw new Error('panic');
  if (!hasProperty(value, 'schema_name')) throw new Error('panic');
  const {
    address,
    schema_name,
  } = value;
  if (typeof address !== 'string') throw new Error('panic');
  if (typeof schema_name !== 'string') throw new Error('panic');
  return {
    address,
    schema_name,
  };
}

function castOpenseaAsset(value: unknown): OpenseaAsset | null {
  if (value === null) return null;
  if (typeof value !== 'object') throw new Error('panic');
  if (!hasProperty(value, 'asset_contract')) throw new Error('panic');
  if (!hasProperty(value, 'token_id')) throw new Error('panic');
  const {
    asset_contract,
    token_id,
  } = value;
  const _asset_contract = castOpenseaAssetContract(asset_contract);
  if (typeof token_id !== 'string') throw new Error('panic');
  return {
    asset_contract: _asset_contract,
    token_id,
  };
}

function castOpenseaPaymentTokenContract(value: unknown): OpenseaPaymentTokenContract {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'decimals')) throw new Error('panic');
  const {
    decimals,
  } = value;
  if (typeof decimals !== 'number') throw new Error('panic');
  return {
    decimals,
  };
}

function castOpenseaOrder(value: unknown): OpenseaOrder {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'asset')) throw new Error('panic');
  if (!hasProperty(value, 'expiration_time')) throw new Error('panic');
  if (!hasProperty(value, 'listing_time')) throw new Error('panic');
  if (!hasProperty(value, 'exchange')) throw new Error('panic');
  if (!hasProperty(value, 'maker')) throw new Error('panic');
  if (!hasProperty(value, 'taker')) throw new Error('panic');
  if (!hasProperty(value, 'current_price')) throw new Error('panic');
  if (!hasProperty(value, 'maker_relayer_fee')) throw new Error('panic');
  if (!hasProperty(value, 'taker_relayer_fee')) throw new Error('panic');
  if (!hasProperty(value, 'maker_protocol_fee')) throw new Error('panic');
  if (!hasProperty(value, 'taker_protocol_fee')) throw new Error('panic');
  if (!hasProperty(value, 'fee_recipient')) throw new Error('panic');
  if (!hasProperty(value, 'fee_method')) throw new Error('panic');
  if (!hasProperty(value, 'side')) throw new Error('panic');
  if (!hasProperty(value, 'sale_kind')) throw new Error('panic');
  if (!hasProperty(value, 'target')) throw new Error('panic');
  if (!hasProperty(value, 'how_to_call')) throw new Error('panic');
  if (!hasProperty(value, 'calldata')) throw new Error('panic');
  if (!hasProperty(value, 'replacement_pattern')) throw new Error('panic');
  if (!hasProperty(value, 'static_target')) throw new Error('panic');
  if (!hasProperty(value, 'static_extradata')) throw new Error('panic');
  if (!hasProperty(value, 'payment_token')) throw new Error('panic');
  if (!hasProperty(value, 'payment_token_contract')) throw new Error('panic');
  if (!hasProperty(value, 'base_price')) throw new Error('panic');
  if (!hasProperty(value, 'extra')) throw new Error('panic');
  if (!hasProperty(value, 'salt')) throw new Error('panic');
  if (!hasProperty(value, 'v')) throw new Error('panic');
  if (!hasProperty(value, 'r')) throw new Error('panic');
  if (!hasProperty(value, 's')) throw new Error('panic');
  if (!hasProperty(value, 'approved_on_chain')) throw new Error('panic');
  if (!hasProperty(value, 'cancelled')) throw new Error('panic');
  if (!hasProperty(value, 'finalized')) throw new Error('panic');
  if (!hasProperty(value, 'marked_invalid')) throw new Error('panic');
  const {
    asset,
    expiration_time,
    listing_time,
    exchange,
    maker,
    taker,
    current_price,
    maker_relayer_fee,
    taker_relayer_fee,
    maker_protocol_fee,
    taker_protocol_fee,
    fee_recipient,
    fee_method,
    side,
    sale_kind,
    target,
    how_to_call,
    calldata,
    replacement_pattern,
    static_target,
    static_extradata,
    payment_token,
    payment_token_contract,
    base_price,
    extra,
    salt,
    v,
    r,
    s,
    approved_on_chain,
    cancelled,
    finalized,
    marked_invalid,
  } = value;
  const _asset = castOpenseaAsset(asset);
  if (typeof expiration_time !== 'number') throw new Error('panic');
  if (typeof listing_time !== 'number') throw new Error('panic');
  if (typeof exchange !== 'string') throw new Error('panic');
  const _maker = castOpenseaUser(maker);
  const _taker = castOpenseaUser(taker);
  if (typeof current_price !== 'string') throw new Error('panic');
  if (typeof maker_relayer_fee !== 'string') throw new Error('panic');
  if (typeof taker_relayer_fee !== 'string') throw new Error('panic');
  if (typeof maker_protocol_fee !== 'string') throw new Error('panic');
  if (typeof taker_protocol_fee !== 'string') throw new Error('panic');
  const _fee_recipient = castOpenseaUser(fee_recipient);
  if (typeof fee_method !== 'number') throw new Error('panic');
  if (typeof side !== 'number') throw new Error('panic');
  if (typeof sale_kind !== 'number') throw new Error('panic');
  if (typeof target !== 'string') throw new Error('panic');
  if (typeof how_to_call !== 'number') throw new Error('panic');
  if (typeof calldata !== 'string') throw new Error('panic');
  if (typeof replacement_pattern !== 'string') throw new Error('panic');
  if (typeof static_target !== 'string') throw new Error('panic');
  if (typeof static_extradata !== 'string') throw new Error('panic');
  if (typeof payment_token !== 'string') throw new Error('panic');
  const _payment_token_contract = castOpenseaPaymentTokenContract(payment_token_contract);
  if (typeof base_price !== 'string') throw new Error('panic');
  if (typeof extra !== 'string') throw new Error('panic');
  if (typeof salt !== 'string') throw new Error('panic');
  if (typeof v !== 'number' && v !== null) throw new Error('panic');
  if (typeof r !== 'string' && r !== null) throw new Error('panic');
  if (typeof s !== 'string' && s !== null) throw new Error('panic');
  if (typeof approved_on_chain !== 'boolean') throw new Error('panic');
  if (typeof cancelled !== 'boolean') throw new Error('panic');
  if (typeof finalized !== 'boolean') throw new Error('panic');
  if (typeof marked_invalid !== 'boolean') throw new Error('panic');
  return {
    asset: _asset,
    expiration_time,
    listing_time,
    exchange,
    maker: _maker,
    taker: _taker,
    current_price,
    maker_relayer_fee,
    taker_relayer_fee,
    maker_protocol_fee,
    taker_protocol_fee,
    fee_recipient: _fee_recipient,
    fee_method,
    side,
    sale_kind,
    target,
    how_to_call,
    calldata,
    replacement_pattern,
    static_target,
    static_extradata,
    payment_token,
    payment_token_contract: _payment_token_contract,
    base_price,
    extra,
    salt,
    v,
    r,
    s,
    approved_on_chain,
    cancelled,
    finalized,
    marked_invalid,
  };
}

function castListOpenseaOrdersResult(value: unknown): ListOpenseaOrdersResult {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'count')) throw new Error('panic');
  if (!hasProperty(value, 'orders')) throw new Error('panic');
  const {
    count,
    orders,
  } = value;
  if (typeof count !== 'number') throw new Error('panic');
  if (!(orders instanceof Array)) throw new Error('panic');
  const _orders = orders.map(castOpenseaOrder);
  return {
    count,
    orders: _orders,
  };
}

async function listOpenseaOrders(apiKey: string, params: Partial<ListOpenseaOrdersParams> = {}, testnet = false): Promise<ListOpenseaOrdersResult> {
  const DEFAULT_PARAMS: ListOpenseaOrdersParams = {
    bundled: false,
    include_bundled: true,
    include_invalid: false,
    limit: 50,
    offset: 0,
    order_by: 'created_date',
    order_direction: 'desc',
  };
  const _params: ListOpenseaOrdersParams = Object.assign({ ...DEFAULT_PARAMS }, params);
  const url = 'https://' + (testnet ? 'testnets-' : '') + 'api.opensea.io/wyvern/v1/orders?' + serialize(_params);
  const response = await httpGet(url, { 'X-API-KEY': apiKey });
  const result: unknown = JSON.parse(response);
  return castListOpenseaOrdersResult(result);
}

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const ZERO_BYTES32 = '0x0000000000000000000000000000000000000000000000000000000000000000';

const TOKEN_TRANSFER_PROXY: { [name: string]: string } = {
  '0x7be8076f4ea4a4ad08075c2508e481d6c946d12b': '0xe5c783ee536cf5e63e792988335c4255169be4e1', // mainnet
  '0x7f268357a8c2552623316e2562d90e642bb538e5': '0xe5c783ee536cf5e63e792988335c4255169be4e1', // mainnet
  '0x5206e78b21ce315ce284fb24cf05e0585a93b1d9': '0x82d102457854c985221249f86659c9d6cf12aa72', // rinkeby
  '0xdd54d660178b28f6033a953b0e55073cfa7e3744': '0xcdc9188485316bf6fa416d02b4f680227c50b89e', // rinkeby
}

function filterOrder(order: OpenseaOrder): boolean {
  return order.asset !== null
      && order.asset.asset_contract.schema_name === 'ERC721'
      && order.taker.address === ZERO_ADDRESS
      && /^\d*\.?\d*$/.test(order.current_price)
      && order.calldata.length === order.replacement_pattern.length
      && order.v !== null
      && order.r !== null
      && order.s !== null;
}

function validateOrder(order: OpenseaOrder, network: string): void {
  if (TOKEN_TRANSFER_PROXY[order.exchange] === undefined) throw new Error('Invalid exchange: ' + order.exchange);
  if (order.side !== 1) throw new Error('Invalid size: ' + order.side);
  if (order.cancelled) throw new Error('Invalid cancelled: ' + order.cancelled);
  if (order.finalized) throw new Error('Invalid finalized: ' + order.finalized);
  if (order.marked_invalid) throw new Error('Invalid marked_invalid: ' + order.marked_invalid);
}

function encodeCalldata(order: OpenseaOrder, acquirer: string, price: string, metadata: string): string {
  if (order.v === null) throw new Error('panic');
  if (order.r === null) throw new Error('panic');
  if (order.s === null) throw new Error('panic');
  const web3 = new Web3();
  const abi: AbiItem = {
      type: 'function',
      name: 'atomicMatch_',
      inputs: [
        { type: 'address[14]', name: '_addrs' },
        { type: 'uint256[18]', name: '_uints' },
        { type: 'uint8[8]', name: '_feeMethodsSidesKindsHowToCalls' },
        { type: 'bytes', name: '_calldataBuy' },
        { type: 'bytes', name: '_calldataSell' },
        { type: 'bytes', name: '_replacementPatternBuy' },
        { type: 'bytes', name: '_replacementPatternSell' },
        { type: 'bytes', name: '_staticExtradataBuy' },
        { type: 'bytes', name: '_staticExtradataSell' },
        { type: 'uint8[2]', name: '_vs' },
        { type: 'bytes32[5]', name: '_rssMetadata' },
      ],
  };
  const feeRecipient = order.fee_recipient.address === ZERO_ADDRESS ? acquirer : ZERO_ADDRESS;
  let calldata = order.calldata;
  let replacementPattern = order.replacement_pattern;
  const mask = 'f'.repeat(64);
  while (true) {
    const index = replacementPattern.indexOf(mask);
    if (index < 0) break;
    calldata = calldata.substring(0, index) + '0'.repeat(24) + acquirer.substring(2) + calldata.substring(index + 64);
    replacementPattern = replacementPattern.substring(0, index) + '0'.repeat(64) + replacementPattern.substring(index + 64);
  }
  type Param = number | string | (number | string)[];
  const params: Param[] = [
    [
      order.exchange,               // exchange
      acquirer,                     // maker
      order.maker.address,          // taker
      feeRecipient,                 // feeRecipient
      order.target,                 // target
      ZERO_ADDRESS,                 // staticTarget
      order.payment_token,          // paymentToken

      order.exchange,               // exchange
      order.maker.address,          // maker
      order.taker.address,          // taker
      order.fee_recipient.address,  // feeRecipient
      order.target,                 // target
      order.static_target,          // staticTarget
      order.payment_token,          // paymentToken
    ],
    [
      order.maker_relayer_fee,      // makerRelayerFee
      order.taker_relayer_fee,      // takerRelayerFee
      order.maker_protocol_fee,     // makerProtocolFee
      order.taker_protocol_fee,     // takerProtocolFee
      price,                        // price
      '0',                          // extra
      '0',                          // listimtime
      '0',                          // expirationTime
      '0',                          // salt

      order.maker_relayer_fee,      // makerRelayerFee
      order.taker_relayer_fee,      // takerRelayerFee
      order.maker_protocol_fee,     // makerProtocolFee
      order.taker_protocol_fee,     // takerProtocolFee
      order.base_price,             // basePrice
      order.extra,                  // extra
      order.listing_time,           // listimtime
      order.expiration_time,        // expirationTime
      order.salt,                   // salt
    ],
    [
      order.fee_method,             // feeMethod
      0,                            // side
      0,                            // saleKind
      order.how_to_call,            // howToCall

      order.fee_method,             // feeMethod
      order.side,                   // side
      order.sale_kind,              // saleKind
      order.how_to_call,            // howToCall
    ],
    calldata,                       // calldata
    order.calldata,                 // calldata
    '0x',                           // replacementPattern
    order.replacement_pattern,      // replacementPattern
    '0x',                           // staticExtradata
    order.static_extradata,         // staticExtradata
    [
      0,                            // v
      order.v,                      // v
    ],
    [
      ZERO_BYTES32,                 // r
      ZERO_BYTES32,                 // s
      order.r,                      // r
      order.s,                      // s
      metadata,                     // metadata
    ],
  ];
  const spender = TOKEN_TRANSFER_PROXY[order.exchange] || ZERO_ADDRESS;
  const target = order.exchange;
  const _calldata = web3.eth.abi.encodeFunctionCall(abi, params as any); // type is incorrect on Web3
  return web3.eth.abi.encodeParameters(['address', 'address', 'bytes'], [spender, target, _calldata]);
}

const EXTERNAL_ACQUIRER = '0xF7A63A68226463a722243B839D9ba4A373B8376E';

const OPENSEA_REFERRAL: { [name: string]: string } = {
  'mainnet': '0x1bf2ad2b8ba93dacd8b7b1686d7db71e9481e73f',
  'rinkeby': '0x3112eb8e651611fdb8c9a5b9f80222b090e36601',
};

export type NftData = {
  collection: string;
  tokenId: bigint;
  price: bigint;
  decimals: number;
  paymentToken: string;
  data: string;
};

function translateOrder(order: OpenseaOrder, network: string): NftData {
  if (order.asset === null) throw new Error('panic');
  const [floor, frac] = order.current_price.split('.');
  const price = BigInt(floor || '0') + (BigInt(frac || '0') > 0n ? 1n : 0n);
  const referral = OPENSEA_REFERRAL[network] || ZERO_ADDRESS;
  const metadata = '0x' + '0'.repeat(24) + referral.substring(2);
  return {
    collection: order.asset.asset_contract.address,
    tokenId: BigInt(order.asset.token_id),
    price,
    decimals: order.payment_token_contract.decimals,
    paymentToken: order.payment_token,
    data: encodeCalldata(order, EXTERNAL_ACQUIRER, String(price), metadata),
  };
}

export async function listNfts(apiKey: string, network = 'mainnet', validate = false, pageCount = 1, page = 0, pause = 1000): Promise<NftData[]> {
  if (!['mainnet', 'rinkeby'].includes(network)) throw new Error('Unsupported network: ' + network);
  const testnet = network === 'rinkeby';
  const items: NftData[] = [];
  const limit = 50;
  for (let offset = page * limit; offset < (page + pageCount) * limit; offset += limit) {
    const result = await listOpenseaOrders(apiKey, { side: 1, offset, limit }, testnet);
    const orders = result.orders.filter(filterOrder);
    if (validate) {
      orders.forEach((order) => validateOrder(order, network));
    }
    items.push(...orders.map((order) => translateOrder(order, network)));
    console.log('>', offset, result.orders.length, orders.length);
    if (result.orders.length < limit) break;
    await sleep(pause);
  }
  return items;
}

export async function fetchNft(apiKey: string, collection: string, tokenId: string, network = 'mainnet', validate = false): Promise<NftData | null> {
  if (!['mainnet', 'rinkeby'].includes(network)) throw new Error('Unsupported network: ' + network);
  const testnet = network === 'rinkeby';
  const result = await listOpenseaOrders(apiKey, { asset_contract_address: collection, token_id: tokenId, side: 1 }, testnet);
  //if (result.orders.length > 1) throw new Error('panic');
  const orders = result.orders.filter(filterOrder);
  if (validate) {
    orders.forEach((order) => validateOrder(order, network));
  }
  const items = orders.map((order) => translateOrder(order, network));
  return items[0] || null;
}
/*
async function main(args: string[]): Promise<void> {
  const network = args[2] || 'mainnet';
  const apiKey = args[3] || '2f6f419a083c46de9d83ce3dbe7db601';
  console.log(await listNfts(apiKey, network, true, Number.MAX_VALUE));
//  console.log(await fetchNft(apiKey, '0x46bef163d6c470a4774f9585f3500ae3b642e751', '12', network, true));
}

type MainFn = (args: string[]) => Promise<void>;

async function __entrypoint(main: MainFn): Promise<void> {
  try {
    await main(process.argv);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
  process.exit(0);
}

__entrypoint(main);
*/
