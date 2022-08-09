import { NftData } from './common';
import { fetchNft as fetchOpenseaV1Nft } from './opensea-v1';
import { fetchNft as fetchOpenseaV2Nft } from './opensea-v2';
import { fetchNft as fetchLooksrareNft } from './looksrare';

export { NftData } from './common';

async function safePromise<T>(promise: Promise<T | null>): Promise<T | null> {
  try {
    return await promise;
  } catch (e) {
    console.log(e);
  }
  return null;
}

export async function fetchNft(apiKey: string, collection: string, tokenId: bigint, network = 'mainnet', validate = false): Promise<NftData | null> {
  const [nft1, nft2, nft3] = await Promise.all([
    safePromise(fetchOpenseaV2Nft(apiKey, collection, tokenId, network, validate)),
    safePromise(fetchOpenseaV1Nft(apiKey, collection, tokenId, network, validate)),
    safePromise(fetchLooksrareNft('', collection, tokenId, network, validate)),
  ]);
  return nft1 || nft2 || nft3 || null;
}
