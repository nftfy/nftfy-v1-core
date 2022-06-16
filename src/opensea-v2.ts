import { NftData } from './common';
import { hasProperty } from './utils';
import { serialize, httpGet } from './urlfetch';

type OpenseaAccount = {
  user: number | null;
  profile_img_url: string;
  address: string;
  config: string;
};

type OpenseaFees = {
  account: OpenseaAccount;
  basis_points: string;
};

type OpenseaOfferItem = {
  itemType: number;
  token: string;
  identifierOrCriteria: string;
  startAmount: string;
  endAmount: string;
};

type OpenseaConsiderationItem = {
  itemType: number;
  token: string;
  identifierOrCriteria: string;
  startAmount: string;
  endAmount: string;
  recipient: string;
};

type OpenseaOrderParameters = {
  offerer: string;
  offer: OpenseaOfferItem[];
  consideration: OpenseaConsiderationItem[],
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
  parameters: OpenseaOrderParameters;
  signature: string;
};

type OpenseaOrder = {
  created_date: string;
  closing_date: string | null;
  listing_time: number;
  expiration_time: number;
  order_hash: string | null;
  protocol_data: OpenseaProtocolData;
  protocol_address: string | null;
  maker: OpenseaAccount,
  taker: OpenseaAccount | null,
  current_price: string;
  maker_fees: OpenseaFees[];
  taker_fees: OpenseaFees[];
  side: string;
  order_type: string;
  cancelled: boolean;
  finalized: boolean;
  marked_invalid: boolean;
  client_signature: string | null;
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

function castOpenseaAccount(value: unknown): OpenseaAccount {
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

function castOpenseaFees(value: unknown): OpenseaFees {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'account')) throw new Error('panic');
  if (!hasProperty(value, 'basis_points')) throw new Error('panic');
  const {
    account,
    basis_points,
  } = value;
  const _account = castOpenseaAccount(account);
  if (typeof basis_points !== 'string') throw new Error('panic');
  return {
    account: _account,
    basis_points,
  };
}

function castOpenseaOfferItem(value: unknown): OpenseaOfferItem {
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

function castOpenseaConsiderationItem(value: unknown): OpenseaConsiderationItem {
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

function castOpenseaOrderParameters(value: unknown): OpenseaOrderParameters {
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
  const _offer = offer.map(castOpenseaOfferItem);
  if (typeof consideration !== 'object' || consideration === null || !(consideration instanceof Array)) throw new Error('panic');
  const _consideration = consideration.map(castOpenseaConsiderationItem);
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
  const _parameters = castOpenseaOrderParameters(parameters);
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
  if (typeof closing_date !== 'string' && closing_date !== null) throw new Error('panic');
  if (typeof listing_time !== 'number') throw new Error('panic');
  if (typeof expiration_time !== 'number') throw new Error('panic');
  if (typeof order_hash !== 'string' && order_hash !== null) throw new Error('panic');
  const _protocol_data = castOpenseaProtocolData(protocol_data);
  if (typeof protocol_address !== 'string' && protocol_address !== null) throw new Error('panic');
  const _maker = castOpenseaAccount(maker);
  const _taker = taker === null ? null : castOpenseaAccount(taker);
  if (typeof current_price !== 'string') throw new Error('panic');
  if (typeof maker_fees !== 'object' || maker_fees === null || !(maker_fees instanceof Array)) throw new Error('panic');
  const _maker_fees = maker_fees.map(castOpenseaFees);
  if (typeof taker_fees !== 'object' || taker_fees === null || !(taker_fees instanceof Array)) throw new Error('panic');
  const _taker_fees = taker_fees.map(castOpenseaFees);
  if (typeof side !== 'string') throw new Error('panic');
  if (typeof order_type !== 'string') throw new Error('panic');
  if (typeof cancelled !== 'boolean') throw new Error('panic');
  if (typeof finalized !== 'boolean') throw new Error('panic');
  if (typeof marked_invalid !== 'boolean') throw new Error('panic');
  if (typeof client_signature !== 'string' && client_signature !== null) throw new Error('panic');
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

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

function filterOrder(order: OpenseaOrder): boolean {
  const parameters = order.protocol_data.parameters;
  const [offerItem] = parameters.offer;
  const [considerationItem] = parameters.consideration;
  return parameters.offer.length === 1
    && offerItem?.itemType === 2
    && BigInt(offerItem?.startAmount) === 1n
    && BigInt(offerItem?.endAmount) === 1n
    && parameters.consideration.length >= 1
    && (considerationItem?.itemType === 0 && considerationItem?.token === ZERO_ADDRESS || considerationItem?.itemType === 1)
    && BigInt(considerationItem?.identifierOrCriteria) === 0n
    && parameters.offerer.toLowerCase() === considerationItem?.recipient.toLowerCase()
    && parameters.consideration.filter(({ itemType, token, identifierOrCriteria }) => !(itemType === considerationItem?.itemType && token === considerationItem?.token && identifierOrCriteria === considerationItem?.identifierOrCriteria)).length === 0
    && parameters.consideration.filter(({ startAmount, endAmount }) => !(BigInt(startAmount) === BigInt(endAmount))).length === 0;
}

function validateOrder(order: OpenseaOrder, network: string): void {
  const parameters = order.protocol_data.parameters;
  const [considerationItem] = parameters.consideration;
  const payItems = parameters.consideration.filter(({ token }) => token === considerationItem?.token);
  const amounts = payItems.map(({ startAmount }) => BigInt(startAmount));
  const sum = amounts.reduce((sum, amount) => sum + amount, 0n);
  if (sum !== BigInt(order.current_price)) throw new Error('Invalid price: ' + order.current_price);
}

function encodeCalldata(order: OpenseaOrder/*, acquirer: string, price: string, metadata: string*/): string {
  return '';
}

function translateOrder(order: OpenseaOrder, network: string): NftData {
  const [offerItem] = order.protocol_data.parameters.offer;
  if (offerItem === undefined) throw new Error('panic');
  const [considerationItem] = order.protocol_data.parameters.consideration;
  if (considerationItem === undefined) throw new Error('panic');
  const collection = offerItem.token;
  const tokenId = BigInt(offerItem.identifierOrCriteria);
  const price = BigInt(order.current_price);
  const paymentToken = considerationItem.token;
  return {
    collection,
    tokenId,
    price,
    decimals: 18, // TODO
    paymentToken,
    source: 'opensea',
    data: encodeCalldata(order/*, EXTERNAL_ACQUIRER, String(price), metadata*/),
  };
}

export async function fetchNft(apiKey: string, collection: string, tokenId: bigint, network = 'mainnet', validate = false): Promise<NftData | null> {
  if (!['mainnet', 'rinkeby'].includes(network)) throw new Error('Unsupported network: ' + network);
  const testnet = network === 'rinkeby';
  const result = await listOpenseaOrders(apiKey, { asset_contract_address: collection, token_ids: String(tokenId) }, testnet);
  console.log(JSON.stringify(result, undefined, 2));
  //if (result.orders.length > 1) throw new Error('panic');
  const orders = result.orders.filter(filterOrder);
  if (validate) {
    orders.forEach((order) => validateOrder(order, network));
  }
  const items = orders.map((order) => translateOrder(order, network));
  return items[0] || null;
}
