export const EXTERNAL_ACQUIRER = '0x8eD69629B8fA69eEf1b019a3a427C08DC24Dd35f';
export const EXTERNAL_ACQUIRER_V2 = '0x6E01D12295f796E9D1dE6D68Dec5ce862cd55e9C'; // goerli

export type NftData = {
  collection: string;
  tokenId: bigint;
  price: bigint;
  decimals: number;
  paymentToken: string;
  source: 'opensea' | 'looksrare';
  data: string;
  dataV2: string;
};
