import { NftData } from './common';
import { fetchNft as fetchOpenseaV1Nft } from './opensea-v1';
import { fetchNft as fetchOpenseaV2Nft } from './opensea-v2';
import { fetchNft as fetchLooksrareNft } from './looksrare';

export { NftData } from './common';

export async function fetchNft(apiKey: string, collection: string, tokenId: bigint, network = 'mainnet', validate = false): Promise<NftData | null> {
  const [nft1, nft2, nft3] = await Promise.all([
    fetchOpenseaV2Nft(apiKey, collection, tokenId, network, validate),
    fetchOpenseaV1Nft(apiKey, collection, tokenId, network, validate),
    fetchLooksrareNft('', collection, tokenId, network, validate),
  ]);
  return nft1 || nft2 || nft3 || null;
}
