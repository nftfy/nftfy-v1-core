export const EXTERNAL_ACQUIRER = '0x8eD69629B8fA69eEf1b019a3a427C08DC24Dd35f';
export const EXTERNAL_ACQUIRER_V2 = '0x0E59da47900cC881cB39A15A090cB0cD15cCCae1'; // goerli

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
