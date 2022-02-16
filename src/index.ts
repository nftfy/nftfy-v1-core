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
  console.log(url, headers);
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
  user: {
    username: string;
  } | null;
  profile_img_url: string;
  address: string;
  config: string;
};

type OpenseaAsset = {
  id: number;
  num_sales: number;
  background_color: null;
  image_url: string;
  image_preview_url: string;
  image_thumbnail_url: string;
  image_original_url: string;
  animation_url: string;
  animation_original_url: string;
  name: null;
  description: null;
  external_link: null;
  asset_contract: {
    address: string;
    asset_contract_type: string;
    created_date: string;
    name: string;
    nft_version: string;
    opensea_version: null;
    owner: number;
    schema_name: string;
    symbol: string;
    total_supply: string;
    description: string;
    external_link: string;
    image_url: string;
    default_to_fiat: boolean;
    dev_buyer_fee_basis_points: number;
    dev_seller_fee_basis_points: number;
    only_proxied_transfers: boolean;
    opensea_buyer_fee_basis_points: number;
    opensea_seller_fee_basis_points: number;
    buyer_fee_basis_points: number;
    seller_fee_basis_points: number;
    payout_address: string;
  };
  permalink: string;
  collection: {
    banner_image_url: string;
    chat_url: null;
    created_date: string;
    default_to_fiat: boolean;
    description: string;
    dev_buyer_fee_basis_points: string;
    dev_seller_fee_basis_points: string;
    discord_url: string;
    display_data: {
      card_display_style: string;
    };
    external_url: string;
    featured: boolean;
    featured_image_url: string;
    hidden: boolean;
    safelist_request_status: string;
    image_url: string;
    is_subject_to_whitelist: boolean;
    large_image_url: string;
    medium_username: null;
    name: string;
    only_proxied_transfers: boolean;
    opensea_buyer_fee_basis_points: string;
    opensea_seller_fee_basis_points: string;
    payout_address: string;
    require_email: boolean;
    short_description: null;
    slug: string;
    telegram_url: null;
    twitter_username: null;
    instagram_username: string;
    wiki_url: null;
  };
  decimals: 0;
  token_metadata: string;
  owner: OpenseaUser;
  token_id: string;
};

type OpenseaOrder = {
  id: number;
  asset: OpenseaAsset;
  asset_bundle: null;
  created_date: string;
  closing_date: string;
  closing_extendable: boolean;
  expiration_time: number;
  listing_time: number;
  order_hash: string;
  metadata: {
    asset: {
      id: string;
      address: string;
    };
    schema: string;
    referrerAddress: string;
  };
  exchange: string;
  maker: OpenseaUser;
  taker: OpenseaUser;
  current_price: string;
  current_bounty: string;
  bounty_multiple: string;
  maker_relayer_fee: string;
  taker_relayer_fee: string;
  maker_protocol_fee: string;
  taker_protocol_fee: string;
  maker_referrer_fee: string;
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
  payment_token_contract: {
    id: number;
    symbol: string;
    address: string;
    image_url: string;
    name: string;
    decimals: number;
    eth_price: string;
    usd_price: string;
  };
  base_price: string;
  extra: string;
  quantity: string;
  salt: string;
  v: number;
  r: string;
  s: string;
  approved_on_chain: boolean;
  cancelled: boolean;
  finalized: boolean;
  marked_invalid: boolean;
  prefixed_hash: string;
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
  console.log(params, _params);
  const API_KEY = '2f6f419a083c46de9d83ce3dbe7db601';
  const url = 'https://' + (testnet ? 'testnets-' : '') + 'api.opensea.io/wyvern/v1/orders?' + serialize(_params);
  const response = await httpGet(url, { 'X-API-KEY': API_KEY });
  const result: unknown = JSON.parse(response);
  return result as ListOpenseaOrdersResult;
}

type NftData = {
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

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const TRANSFER_FROM_SELECTOR = '0x23b872dd'; // transferFrom(address,address,uint256)

function _validateOrder(order: OpenseaOrder): void {
/*
      const { asset: { token_id }, exchange, maker: { address: seller },
        maker_relayer_fee, taker_relayer_fee, maker_protocol_fee, taker_protocol_fee,
        fee_recipient: { address: fee_recipient }, fee_method, side, sale_kind, how_to_call,
        calldata, replacement_pattern, static_target, static_extradata,
        approved_on_chain, cancelled, finalized, marked_invalid } = item;

      _calldata = '0x23b872dd'
        + seller.substring(2).padStart(64, '0')
        + ''.padStart(64, '0')
        + BigInt(token_id).toString(16).padStart(64, '0');

      if (exchange !== contract) throw new Error('Invalid exchange: ' + exchange);
      // if (!['0', '250', '251', '255', '350', '450', '500', '530', '540', '550', '600', '650', '700', '720', '750', '759', '800', '850', '900', '916', '940', '950', '1000', '1050', '1100', '1150', '1200', '1250'].includes(maker_relayer_fee)) throw new Error('Invalid maker_relayer_fee: ' + maker_relayer_fee);
      if (!['0'].includes(taker_relayer_fee)) throw new Error('Invalid taker_relayer_fee: ' + taker_relayer_fee);
      if (maker_protocol_fee !== '0') throw new Error('Invalid maker_protocol_fee: ' + maker_protocol_fee);
      if (taker_protocol_fee !== '0') throw new Error('Invalid taker_protocol_fee: ' + taker_protocol_fee);
      if (fee_recipient !== wallet) throw new Error('Invalid fee_recipient: ' + fee_recipient);
      if (![1].includes(fee_method)) throw new Error('Invalid fee_method: ' + fee_method);
      if (side !== 1) throw new Error('Invalid side: ' + side);
      if (![0, 1].includes(sale_kind)) throw new Error('Invalid sale_kind: ' + sale_kind);
      if (how_to_call !== 0) throw new Error('Invalid how_to_call: ' + how_to_call);
      if (calldata !== _calldata) throw new Error('Invalid calldata: ' + calldata);
      if (replacement_pattern !== '0x000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000') throw new Error('Invalid replacement_pattern: ' + replacement_pattern);
      if (!['0x0000000000000000000000000000000000000000'].includes(static_target)) throw new Error('Invalid static_target: ' + static_target);
      if (static_extradata !== '0x') throw new Error('Invalid static_extradata: ' + static_extradata);
      if (approved_on_chain) throw new Error('Invalid approved_on_chain: ' + approved_on_chain);
      if (cancelled) throw new Error('Invalid cancelled: ' + cancelled);
      if (finalized) throw new Error('Invalid finalized: ' + finalized);
      if (marked_invalid) throw new Error('Invalid marked_invalid: ' + marked_invalid);
*/
}

export async function listNfts(network = 'mainnet', page = 0, pageCount = 1, pause = 1000): Promise<NftData[]> {
  if (!['mainnet', 'rinkeby'].includes(network)) throw new Error('Unsupported network: ' + network);
  const testnet = network === 'rinkeby';
  const list: NftData[] = [];
  const limit = 50;
  for (let offset = page * limit; offset < (page + pageCount) * limit; offset += limit) {
    const params = {
      side: 1,
      offset,
      limit,
    };
    const result = await listOpenseaOrders(params, testnet);

    const orders = result.orders.filter(({ asset, taker_relayer_fee, fee_recipient: { address: fee_recipient }, calldata }) =>
      asset !== null
      && taker_relayer_fee === '0'
      && fee_recipient !== ZERO_ADDRESS
      && calldata.substring(0, 10) === TRANSFER_FROM_SELECTOR);

    for (const order of orders) {
      _validateOrder(order);
    }

    const items = orders.map((order) => ({
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
    }));

    list.push(...items);

    if (result.orders.length < limit) break;
    await sleep(pause);
  }
  return list;
}

/*
async function main() {
  const testnet = true;
  const contract = testnet ? '0x5206e78b21ce315ce284fb24cf05e0585a93b1d9' : '0x7be8076f4ea4a4ad08075c2508e481d6c946d12b';
  const wallet = '0x5b3256965e7c3cf26e11fcaf296dfc8807c01073';
  const selectors = [
    '0x23b872dd', // 721 / transferFrom(address,address,uint256)
    '0xf242432a', // 1155 / safeTransferFrom(address,address,uint256,uint256,bytes)
    '0x68f0bcaa', // ?
  ];

  const items = [];

  const limit = 50;
  for (offset = 0; ; offset += limit) {

    const data = await listOpenseaItems({ side: 1, offset, limit, order_direction: 'desc', asset_contract_address: '0x46bEF163D6C470a4774f9585F3500Ae3b642e751', token_id: 11 }, testnet);
    const filtered = data.filter(({ asset, taker_relayer_fee, fee_recipient: { address: fee_recipient }, calldata}) =>
      asset !== null &&
      taker_relayer_fee === '0'
      && fee_recipient !== '0x0000000000000000000000000000000000000000'
      && calldata.substring(0, 10) === '0x23b872dd');
    console.log(JSON.stringify(filtered, undefined, 2));

    for (const item of data) {
      const { calldata } = item;
      const selector = calldata.substring(0, 10);
      if (!selectors.includes(selector)) {
        selectors.push(selector);
        console.log(selector);
      }
    }

    for (const item of filtered) {
      const { asset: { token_id }, exchange, maker: { address: seller },
        maker_relayer_fee, taker_relayer_fee, maker_protocol_fee, taker_protocol_fee,
        fee_recipient: { address: fee_recipient }, fee_method, side, sale_kind, how_to_call,
        calldata, replacement_pattern, static_target, static_extradata,
        approved_on_chain, cancelled, finalized, marked_invalid } = item;

      _calldata = '0x23b872dd'
        + seller.substring(2).padStart(64, '0')
        + ''.padStart(64, '0')
        + BigInt(token_id).toString(16).padStart(64, '0');

      if (exchange !== contract) throw new Error('Invalid exchange: ' + exchange);
      // if (!['0', '250', '251', '255', '350', '450', '500', '530', '540', '550', '600', '650', '700', '720', '750', '759', '800', '850', '900', '916', '940', '950', '1000', '1050', '1100', '1150', '1200', '1250'].includes(maker_relayer_fee)) throw new Error('Invalid maker_relayer_fee: ' + maker_relayer_fee);
      if (!['0'].includes(taker_relayer_fee)) throw new Error('Invalid taker_relayer_fee: ' + taker_relayer_fee);
      if (maker_protocol_fee !== '0') throw new Error('Invalid maker_protocol_fee: ' + maker_protocol_fee);
      if (taker_protocol_fee !== '0') throw new Error('Invalid taker_protocol_fee: ' + taker_protocol_fee);
      if (fee_recipient !== wallet) throw new Error('Invalid fee_recipient: ' + fee_recipient);
      if (![1].includes(fee_method)) throw new Error('Invalid fee_method: ' + fee_method);
      if (side !== 1) throw new Error('Invalid side: ' + side);
      if (![0, 1].includes(sale_kind)) throw new Error('Invalid sale_kind: ' + sale_kind);
      if (how_to_call !== 0) throw new Error('Invalid how_to_call: ' + how_to_call);
      if (calldata !== _calldata) throw new Error('Invalid calldata: ' + calldata);
      if (replacement_pattern !== '0x000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000') throw new Error('Invalid replacement_pattern: ' + replacement_pattern);
      if (!['0x0000000000000000000000000000000000000000'].includes(static_target)) throw new Error('Invalid static_target: ' + static_target);
      if (static_extradata !== '0x') throw new Error('Invalid static_extradata: ' + static_extradata);
      if (approved_on_chain) throw new Error('Invalid approved_on_chain: ' + approved_on_chain);
      if (cancelled) throw new Error('Invalid cancelled: ' + cancelled);
      if (finalized) throw new Error('Invalid finalized: ' + finalized);
      if (marked_invalid) throw new Error('Invalid marked_invalid: ' + marked_invalid);
    }

    for (const item of data) {
      const { maker: { address: seller }, maker_relayer_fee, target: collection, expiration_time, listing_time, base_price, extra, payment_token, sale_kind, v, r, s, salt } = item;
      items.push({ seller, maker_relayer_fee, collection, base_price, payment_token, extra, listing_time, expiration_time, salt, sale_kind, v, r, s });
    }

    if (data.length < limit) break;

    await sleep(1000);
  }

  // console.log(JSON.stringify(items, undefined, 2));
}
*/

async function main(args: string[]): Promise<void> {
  const network = args[2] || 'mainnet';
  console.log(await listNfts(network));
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
