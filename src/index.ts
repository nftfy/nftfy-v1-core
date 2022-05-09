import { NftData } from './common';
import { fetchNft as fetchOpenseaNft } from './opensea';
import { fetchNft as fetchLooksrareNft } from './looksrare';

export { NftData } from './common';

export async function fetchNft(apiKey: string, collection: string, tokenId: bigint, network = 'mainnet', validate = false): Promise<NftData | null> {
  const [nft1, nft2] = await Promise.all([
    fetchOpenseaNft(apiKey, collection, tokenId, network, validate),
    fetchLooksrareNft('', collection, tokenId, network, validate),
  ]);
  return nft1 || nft2 || null;
}
