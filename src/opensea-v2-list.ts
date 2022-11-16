import { hasProperty } from './utils';
import { httpPost } from './urlfetch';
import { OpenseaOrder, OpenseaOrderParameters, castOpenseaOrder } from './opensea-v2';

const ORDER_DURATION = 30 * 24 * 60 * 60; // 30 days
const FEE: [bigint, bigint] = [975n, 1000n];
const FEE_COLLECTOR = '0x0000a26b00c1F0DF003000390027140000fAa719';

type CreateOpenseaOrderParams = {
  parameters: OpenseaOrderParameters;
  signature: string;
};

type CreateOpenseaOrderResult = {
  order: OpenseaOrder;
};

function castCreateOpenseaOrderResult(value: unknown): CreateOpenseaOrderResult {
  if (typeof value !== 'object' || value === null) throw new Error('panic');
  if (!hasProperty(value, 'order')) throw new Error('panic');
  const {
    order,
  } = value;
  if (typeof order !== 'object' || order === null) throw new Error('panic');
  const _order = castOpenseaOrder(order);
  return {
    order: _order,
  };
}

async function createOpenseaOrder(apiKey: string, params: Partial<CreateOpenseaOrderParams> = {}, testnet = false): Promise<CreateOpenseaOrderResult> {
  const url = 'https://' + (testnet ? 'testnets-' : '') + 'api.opensea.io/v2/orders/' + (testnet ? 'goerli' : 'ethereum') + '/seaport/listings';
  const response = await httpPost(url, JSON.stringify(params), { 'X-API-KEY': apiKey, 'Content-Type': 'application/json' });
  const result: unknown = JSON.parse(response);
  return castCreateOpenseaOrderResult(result);
}

export async function publishNft(apiKey: string, fractions: string, collection: string, tokenId: bigint, price: bigint, paymentToken: string, startTime: number, network = 'mainnet'): Promise<string> {
  if (!['mainnet', 'goerli'].includes(network)) throw new Error('Unsupported network: ' + network);
  const testnet = network === 'goerli';
  const endTime = startTime + ORDER_DURATION;
  const zone = '0x0000000000000000000000000000000000000000';
  const zoneHash = '0x0000000000000000000000000000000000000000000000000000000000000000';
  const conduitKey = '0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000';
  let fee = price * FEE[1] / FEE[0] - price;
  const parameters: OpenseaOrderParameters = {
    offerer: fractions,
    offer: [
      {
        itemType: 2,
        token: collection,
        identifierOrCriteria: String(tokenId),
        startAmount: '1',
        endAmount: '1',
      }
    ],
    consideration: [
      {
        itemType: 0,
        token: paymentToken,
        identifierOrCriteria: '0',
        startAmount: String(price),
        endAmount: String(price),
        recipient: fractions,
      },
      {
        itemType: 0,
        token: paymentToken,
        identifierOrCriteria: '0',
        startAmount: String(fee),
        endAmount: String(fee),
        recipient: FEE_COLLECTOR,
      }
    ],
    startTime: String(startTime),
    endTime: String(endTime),
    orderType: 0,
    zone,
    zoneHash,
    salt: '0',
    conduitKey,
    totalOriginalConsiderationItems: 2,
    counter: 0,
  };
  const result = await createOpenseaOrder(apiKey, { parameters, signature: '' }, testnet);
  return result.order.order_hash || '';
}
