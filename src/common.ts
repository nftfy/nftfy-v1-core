export const EXTERNAL_ACQUIRER = '0x485294A18ebbBB143081c7bD05F4c96d28472F84';

export type NftData = {
  collection: string;
  tokenId: bigint;
  price: bigint;
  decimals: number;
  paymentToken: string;
  source: 'opensea' | 'looksrare';
  data: string;
};
