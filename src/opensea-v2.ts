import { NftData } from './common';
import { hasProperty } from './utils';
import { serialize, httpGet } from './urlfetch';

type OpenseaUser = {
  user: number | null;
  profile_img_url: string;
  address: string;
  config: string;
};

type OpenseaFee = {
  account: OpenseaUser;
  basis_points: string;
};

type OpenseaOffer = {
  itemType: number;
  token: string;
  identifierOrCriteria: string;
  startAmount: string;
  endAmount: string;
};

type OpenseaConsideration = {
  itemType: number;
  token: string;
  identifierOrCriteria: string;
  startAmount: string;
  endAmount: string;
  recipient: string;
};

type OpenseaProtocolDataParameters = {
  offerer: string;
  offer: OpenseaOffer[];
  consideration: OpenseaConsideration[],
  startTime: string;
  endTime: string;
  orderType: number;
  zone: string;
  zoneHash: string;
  salt: string;
  conduitKey: string;
  totalOriginalConsiderationItems: number;
  counter: number;
};

type OpenseaProtocolData = {
  parameters: OpenseaProtocolDataParameters;
  signature: string;
};

type OpenseaOrder = {
  created_date: string;
  closing_date: string;
  listing_time: number;
  expiration_time: number;
  order_hash: string;
  protocol_data: OpenseaProtocolData;
  protocol_address: string;
  maker: OpenseaUser | null,
  taker: OpenseaUser | null,
  current_price: string;
  maker_fees: OpenseaFee[];
  taker_fees: OpenseaFee[];
  side: string;
  order_type: string;
  cancelled: boolean;
  finalized: boolean;
  marked_invalid: boolean;
  client_signature: string;
  relay_id: string;
//  maker_asset_bundle: { ... };
//  taker_asset_bundle: { ... };
};

type ListOpenseaOrdersParams = {
  asset_contract_address?: string;
  limit: number;
  token_ids?: string;
};

type ListOpenseaOrdersResult = {
  next: string | null;
  previous: string | null;
  orders: OpenseaOrder[];
};

function castOpenseaUser(value: unknown): OpenseaUser {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'user')) throw new Error('panic');
  if (!hasProperty(value, 'profile_img_url')) throw new Error('panic');
  if (!hasProperty(value, 'address')) throw new Error('panic');
  if (!hasProperty(value, 'config')) throw new Error('panic');
  const {
    user,
    profile_img_url,
    address,
    config,
  } = value;
  if (typeof user !== 'number' && user !== null) throw new Error('panic');
  if (typeof profile_img_url !== 'string') throw new Error('panic');
  if (typeof address !== 'string') throw new Error('panic');
  if (typeof config !== 'string') throw new Error('panic');
  return {
    user,
    profile_img_url,
    address,
    config,
  };
}

function castOpenseaFee(value: unknown): OpenseaFee {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'account')) throw new Error('panic');
  if (!hasProperty(value, 'basis_points')) throw new Error('panic');
  const {
    account,
    basis_points,
  } = value;
  const _account = castOpenseaUser(account);
  if (typeof basis_points !== 'string') throw new Error('panic');
  return {
    account: _account,
    basis_points,
  };
}

function castOpenseaOffer(value: unknown): OpenseaOffer {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'itemType')) throw new Error('panic');
  if (!hasProperty(value, 'token')) throw new Error('panic');
  if (!hasProperty(value, 'identifierOrCriteria')) throw new Error('panic');
  if (!hasProperty(value, 'startAmount')) throw new Error('panic');
  if (!hasProperty(value, 'endAmount')) throw new Error('panic');
  const {
    itemType,
    token,
    identifierOrCriteria,
    startAmount,
    endAmount,
  } = value;
  if (typeof itemType !== 'number') throw new Error('panic');
  if (typeof token !== 'string') throw new Error('panic');
  if (typeof identifierOrCriteria !== 'string') throw new Error('panic');
  if (typeof startAmount !== 'string') throw new Error('panic');
  if (typeof endAmount !== 'string') throw new Error('panic');
  return {
    itemType,
    token,
    identifierOrCriteria,
    startAmount,
    endAmount,
  };
}

function castOpenseaConsideration(value: unknown): OpenseaConsideration {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'itemType')) throw new Error('panic');
  if (!hasProperty(value, 'token')) throw new Error('panic');
  if (!hasProperty(value, 'identifierOrCriteria')) throw new Error('panic');
  if (!hasProperty(value, 'startAmount')) throw new Error('panic');
  if (!hasProperty(value, 'endAmount')) throw new Error('panic');
  if (!hasProperty(value, 'recipient')) throw new Error('panic');
  const {
    itemType,
    token,
    identifierOrCriteria,
    startAmount,
    endAmount,
    recipient,
  } = value;
  if (typeof itemType !== 'number') throw new Error('panic');
  if (typeof token !== 'string') throw new Error('panic');
  if (typeof identifierOrCriteria !== 'string') throw new Error('panic');
  if (typeof startAmount !== 'string') throw new Error('panic');
  if (typeof endAmount !== 'string') throw new Error('panic');
  if (typeof recipient !== 'string') throw new Error('panic');
  return {
    itemType,
    token,
    identifierOrCriteria,
    startAmount,
    endAmount,
    recipient,
  };
}

function castOpenseaProtocolDataParameters(value: unknown): OpenseaProtocolDataParameters {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'offerer')) throw new Error('panic');
  if (!hasProperty(value, 'offer')) throw new Error('panic');
  if (!hasProperty(value, 'consideration')) throw new Error('panic');
  if (!hasProperty(value, 'startTime')) throw new Error('panic');
  if (!hasProperty(value, 'endTime')) throw new Error('panic');
  if (!hasProperty(value, 'orderType')) throw new Error('panic');
  if (!hasProperty(value, 'zone')) throw new Error('panic');
  if (!hasProperty(value, 'zoneHash')) throw new Error('panic');
  if (!hasProperty(value, 'salt')) throw new Error('panic');
  if (!hasProperty(value, 'conduitKey')) throw new Error('panic');
  if (!hasProperty(value, 'totalOriginalConsiderationItems')) throw new Error('panic');
  if (!hasProperty(value, 'counter')) throw new Error('panic');
  const {
    offerer,
    offer,
    consideration,
    startTime,
    endTime,
    orderType,
    zone,
    zoneHash,
    salt,
    conduitKey,
    totalOriginalConsiderationItems,
    counter,
  } = value;
  if (typeof offerer !== 'string') throw new Error('panic');
  if (typeof offer !== 'object' || offer === null || !(offer instanceof Array)) throw new Error('panic');
  const _offer = offer.map(castOpenseaOffer);
  if (typeof consideration !== 'object' || consideration === null || !(consideration instanceof Array)) throw new Error('panic');
  const _consideration = consideration.map(castOpenseaConsideration);
  if (typeof startTime !== 'string') throw new Error('panic');
  if (typeof endTime !== 'string') throw new Error('panic');
  if (typeof orderType !== 'number') throw new Error('panic');
  if (typeof zone !== 'string') throw new Error('panic');
  if (typeof zoneHash !== 'string') throw new Error('panic');
  if (typeof salt !== 'string') throw new Error('panic');
  if (typeof conduitKey !== 'string') throw new Error('panic');
  if (typeof totalOriginalConsiderationItems !== 'number') throw new Error('panic');
  if (typeof counter !== 'number') throw new Error('panic');
  return {
    offerer,
    offer: _offer,
    consideration: _consideration,
    startTime,
    endTime,
    orderType,
    zone,
    zoneHash,
    salt,
    conduitKey,
    totalOriginalConsiderationItems,
    counter,
  };
}

function castOpenseaProtocolData(value: unknown): OpenseaProtocolData {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'parameters')) throw new Error('panic');
  if (!hasProperty(value, 'signature')) throw new Error('panic');
  const {
    parameters,
    signature,
  } = value;
  const _parameters = castOpenseaProtocolDataParameters(parameters);
  if (typeof signature !== 'string') throw new Error('panic');
  return {
    parameters: _parameters,
    signature,
  };
}

function castOpenseaOrder(value: unknown): OpenseaOrder {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'created_date')) throw new Error('panic');
  if (!hasProperty(value, 'closing_date')) throw new Error('panic');
  if (!hasProperty(value, 'listing_time')) throw new Error('panic');
  if (!hasProperty(value, 'expiration_time')) throw new Error('panic');
  if (!hasProperty(value, 'order_hash')) throw new Error('panic');
  if (!hasProperty(value, 'protocol_data')) throw new Error('panic');
  if (!hasProperty(value, 'protocol_address')) throw new Error('panic');
  if (!hasProperty(value, 'maker')) throw new Error('panic');
  if (!hasProperty(value, 'taker')) throw new Error('panic');
  if (!hasProperty(value, 'current_price')) throw new Error('panic');
  if (!hasProperty(value, 'maker_fees')) throw new Error('panic');
  if (!hasProperty(value, 'taker_fees')) throw new Error('panic');
  if (!hasProperty(value, 'side')) throw new Error('panic');
  if (!hasProperty(value, 'order_type')) throw new Error('panic');
  if (!hasProperty(value, 'cancelled')) throw new Error('panic');
  if (!hasProperty(value, 'finalized')) throw new Error('panic');
  if (!hasProperty(value, 'marked_invalid')) throw new Error('panic');
  if (!hasProperty(value, 'client_signature')) throw new Error('panic');
  if (!hasProperty(value, 'relay_id')) throw new Error('panic');
  const {
    created_date,
    closing_date,
    listing_time,
    expiration_time,
    order_hash,
    protocol_data,
    protocol_address,
    maker,
    taker,
    current_price,
    maker_fees,
    taker_fees,
    side,
    order_type,
    cancelled,
    finalized,
    marked_invalid,
    client_signature,
    relay_id,
  } = value;
  if (typeof created_date !== 'string') throw new Error('panic');
  if (typeof closing_date !== 'string') throw new Error('panic');
  if (typeof listing_time !== 'number') throw new Error('panic');
  if (typeof expiration_time !== 'number') throw new Error('panic');
  if (typeof order_hash !== 'string') throw new Error('panic');
  const _protocol_data = castOpenseaProtocolData(protocol_data);
  if (typeof protocol_address !== 'string') throw new Error('panic');
  const _maker = maker === null ? null : castOpenseaUser(maker);
  const _taker = taker === null ? null : castOpenseaUser(taker);
  if (typeof current_price !== 'string') throw new Error('panic');
  if (typeof maker_fees !== 'object' || maker_fees === null || !(maker_fees instanceof Array)) throw new Error('panic');
  const _maker_fees = maker_fees.map(castOpenseaFee);
  if (typeof taker_fees !== 'object' || taker_fees === null || !(taker_fees instanceof Array)) throw new Error('panic');
  const _taker_fees = taker_fees.map(castOpenseaFee);
  if (typeof side !== 'string') throw new Error('panic');
  if (typeof order_type !== 'string') throw new Error('panic');
  if (typeof cancelled !== 'boolean') throw new Error('panic');
  if (typeof finalized !== 'boolean') throw new Error('panic');
  if (typeof marked_invalid !== 'boolean') throw new Error('panic');
  if (typeof client_signature !== 'string') throw new Error('panic');
  if (typeof relay_id !== 'string') throw new Error('panic');
  return {
    created_date,
    closing_date,
    listing_time,
    expiration_time,
    order_hash,
    protocol_data: _protocol_data,
    protocol_address,
    maker: _maker,
    taker: _taker,
    current_price,
    maker_fees: _maker_fees,
    taker_fees: _taker_fees,
    side,
    order_type,
    cancelled,
    finalized,
    marked_invalid,
    client_signature,
    relay_id,
  };
}

function castListOpenseaOrdersResult(value: unknown): ListOpenseaOrdersResult {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'next')) throw new Error('panic');
  if (!hasProperty(value, 'previous')) throw new Error('panic');
  if (!hasProperty(value, 'orders')) throw new Error('panic');
  const {
    next,
    previous,
    orders,
  } = value;
  if (typeof next !== 'string' && next !== null) throw new Error('panic');
  if (typeof previous !== 'string' && previous !== null) throw new Error('panic');
  if (!(orders instanceof Array)) throw new Error('panic');
  const _orders = orders.map(castOpenseaOrder);
  return {
    next,
    previous,
    orders: _orders,
  };
}

async function listOpenseaOrders(apiKey: string, params: Partial<ListOpenseaOrdersParams> = {}, testnet = false): Promise<ListOpenseaOrdersResult> {
  const DEFAULT_PARAMS: ListOpenseaOrdersParams = {
    limit: 50,
  };
  const _params: ListOpenseaOrdersParams = Object.assign({ ...DEFAULT_PARAMS }, params);
  const url = 'https://' + (testnet ? 'testnets-' : '') + 'api.opensea.io/v2/orders/' + (testnet ? 'rinkeby' : 'ethereum') + '/seaport/listings?' + serialize(_params);
  const response = await httpGet(url, { 'X-API-KEY': apiKey });
  const result: unknown = JSON.parse(response);
  return castListOpenseaOrdersResult(result);
}

export async function fetchNft(apiKey: string, collection: string, tokenId: bigint, network = 'mainnet', validate = false): Promise<NftData | null> {
  if (!['mainnet', 'rinkeby'].includes(network)) throw new Error('Unsupported network: ' + network);
  const testnet = network === 'rinkeby';
  const result = await listOpenseaOrders(apiKey, { asset_contract_address: collection, token_ids: String(tokenId) }, testnet);
  console.log(JSON.stringify(result, undefined, 2));
  //if (result.orders.length > 1) throw new Error('panic');
//  const orders = result.orders.filter(filterOrder);
//  if (validate) {
//    orders.forEach((order) => validateOrder(order, network));
//  }
//  const items = orders.map((order) => translateOrder(order, network));
//  return items[0] || null;
  return null;
}
