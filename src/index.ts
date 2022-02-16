import 'source-map-support/register';
import axios from 'axios';

function serialize(params: { [name: string]: string[] | string | number | boolean }): string {
  return Object.keys(params)
    .filter((name) => params[name] !== undefined)
    .map((name) => {
      const value = params[name];
      if (value === undefined) throw new Error('panic');
      if (typeof value === 'object') {
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
//  asset_contract: {
//    address: string;
//    asset_contract_type: string;
//    created_date: string;
//    name: string;
//    nft_version: string;
//    opensea_version: null;
//    owner: number;
//    schema_name: string;
//    symbol: string;
//    total_supply: string;
//    description: string;
//    external_link: string;
//    image_url: string;
//    default_to_fiat: boolean;
//    dev_buyer_fee_basis_points: number;
//    dev_seller_fee_basis_points: number;
//    only_proxied_transfers: boolean;
//    opensea_buyer_fee_basis_points: number;
//    opensea_seller_fee_basis_points: number;
//    buyer_fee_basis_points: number;
//    seller_fee_basis_points: number;
//    payout_address: string;
//  };
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

type OpenseaOrder = {
//  id: number;
  asset: OpenseaAsset;
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
//  taker: OpenseaUser;
//  current_price: string;
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
//  payment_token_contract: {
//    id: number;
//    symbol: string;
//    address: string;
//    image_url: string;
//    name: string;
//    decimals: number;
//    eth_price: string;
//    usd_price: string;
//  };
  base_price: string;
  extra: string;
//  quantity: string;
  salt: string;
  v: number;
  r: string;
  s: string;
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

async function listOpenseaOrders(params: Partial<ListOpenseaOrdersParams> = {}, testnet = false): Promise<ListOpenseaOrdersResult> {
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
  const API_KEY = '2f6f419a083c46de9d83ce3dbe7db601';
  const url = 'https://' + (testnet ? 'testnets-' : '') + 'api.opensea.io/wyvern/v1/orders?' + serialize(_params);
  const response = await httpGet(url, { 'X-API-KEY': API_KEY });
  const result: unknown = JSON.parse(response);
  return result as ListOpenseaOrdersResult;
}

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const ZERO_SELECTOR = '0x00000000';
const TRANSFER_FROM_SELECTOR = '0x23b872dd'; // transferFrom(address,address,uint256)

const OPENSEA_WALLET = '0x5b3256965e7c3cf26e11fcaf296dfc8807c01073';
const OPENSEA_CONTRACT: { [name: string]: string } = {
  'mainnet': '0x7be8076f4ea4a4ad08075c2508e481d6c946d12b',
  'rinkeby': '0x5206e78b21ce315ce284fb24cf05e0585a93b1d9',
};

function _filterOrder(order: OpenseaOrder): boolean {
  return order.asset !== null
      && order.taker_relayer_fee === '0'
      && order.fee_recipient.address !== ZERO_ADDRESS
      && order.calldata.substring(0, 10) === TRANSFER_FROM_SELECTOR;
}

function _validateOrder(order: OpenseaOrder, network: string): void {
  const contract = OPENSEA_CONTRACT[network];
  const calldata = TRANSFER_FROM_SELECTOR
    + order.maker.address.substring(2).padStart(64, '0')
    + ''.padStart(64, '0')
    + BigInt(order.asset.token_id).toString(16).padStart(64, '0');
  const replacementPattern = ZERO_SELECTOR
    + ''.padStart(64, '0')
    + ''.padStart(64, 'f')
    + ''.padStart(64, '0');
  if (order.exchange !== contract) throw new Error('Invalid exchange: ' + order.exchange);
  if (order.taker_relayer_fee !== '0') throw new Error('Invalid taker_relayer_fee: ' + order.taker_relayer_fee);
  if (order.maker_protocol_fee !== '0') throw new Error('Invalid maker_protocol_fee: ' + order.maker_protocol_fee);
  if (order.taker_protocol_fee !== '0') throw new Error('Invalid taker_protocol_fee: ' + order.taker_protocol_fee);
  if (order.fee_recipient.address !== OPENSEA_WALLET) throw new Error('Invalid fee_recipient: ' + order.fee_recipient.address);
  if (order.fee_method !== 1) throw new Error('Invalid fee_method: ' + order.fee_method);
  if (![0, 1].includes(order.side)) throw new Error('Invalid side: ' + order.side);
  if (![0, 1].includes(order.sale_kind)) throw new Error('Invalid sale_kind: ' + order.sale_kind);
  if (order.how_to_call !== 0) throw new Error('Invalid how_to_call: ' + order.how_to_call);
  if (order.calldata !== calldata) throw new Error('Invalid calldata: ' + order.calldata);
  if (order.replacement_pattern !== replacementPattern) throw new Error('Invalid replacement_pattern: ' + order.replacement_pattern);
  if (order.static_target !== ZERO_ADDRESS) throw new Error('Invalid static_target: ' + order.static_target);
  if (order.static_extradata !== '0x') throw new Error('Invalid static_extradata: ' + order.static_extradata);
  if (order.approved_on_chain) throw new Error('Invalid approved_on_chain: ' + order.approved_on_chain);
  if (order.cancelled) throw new Error('Invalid cancelled: ' + order.cancelled);
  if (order.finalized) throw new Error('Invalid finalized: ' + order.finalized);
  if (order.marked_invalid) throw new Error('Invalid marked_invalid: ' + order.marked_invalid);
}

export type NftData = {
  collection: string;
  tokenId: string;
  paymentToken: string;

  seller: string;
  saleKind: number;
  basePrice: string;
  makerRelayerFee: string;
  listingTime: number;
  expirationTime: number;
  extra: string;

  salt: string;
  v: number;
  r: string;
  s: string;
};

function _translateOrder(order: OpenseaOrder): NftData {
  return {
    collection: order.target,
    tokenId: order.asset.token_id,
    paymentToken: order.payment_token,

    seller: order.maker.address,
    saleKind: order.sale_kind,
    basePrice: order.base_price,
    makerRelayerFee: order.maker_relayer_fee,
    listingTime: order.listing_time,
    expirationTime: order.expiration_time,
    extra: order.extra,

    salt: order.salt,
    v: order.v,
    r: order.r,
    s: order.s,
  };
}

export async function listNfts(network = 'mainnet', validate = false, pageCount = 1, page = 0, pause = 1000): Promise<NftData[]> {
  if (!['mainnet', 'rinkeby'].includes(network)) throw new Error('Unsupported network: ' + network);
  const testnet = network === 'rinkeby';
  const items: NftData[] = [];
  const limit = 50;
  for (let offset = page * limit; offset < (page + pageCount) * limit; offset += limit) {
    const result = await listOpenseaOrders({ side: 1, offset, limit }, testnet);
    const orders = result.orders.filter(_filterOrder);
    if (validate) {
      orders.forEach((order) => _validateOrder(order, network));
    }
    items.push(...orders.map(_translateOrder));
    console.log('>', offset, result.orders.length, orders.length);
    if (result.orders.length < limit) break;
    await sleep(pause);
  }
  return items;
}

export async function fetchNft(collection: string, tokenId: string, network = 'mainnet', validate = false): Promise<NftData | null> {
  if (!['mainnet', 'rinkeby'].includes(network)) throw new Error('Unsupported network: ' + network);
  const testnet = network === 'rinkeby';
  const result = await listOpenseaOrders({ asset_contract_address: collection, token_id: tokenId, side: 1 }, testnet);
  if (result.orders.length > 1) throw new Error('panic');
  const orders = result.orders.filter(_filterOrder);
  if (validate) {
    orders.forEach((order) => _validateOrder(order, network));
  }
  const items = orders.map(_translateOrder);
  return items[0] || null;
}

async function main(args: string[]): Promise<void> {
  const network = args[2] || 'mainnet';
  console.log(await listNfts(network, true, Number.MAX_VALUE));
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
