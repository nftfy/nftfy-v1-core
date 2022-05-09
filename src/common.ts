export type NftData = {
  collection: string;
  tokenId: bigint;
  price: bigint;
  decimals: number;
  paymentToken: string;
  source: 'opensea' | 'looksrare';
  data: string;
};
