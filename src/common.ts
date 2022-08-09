export const EXTERNAL_ACQUIRER = '0x8eD69629B8fA69eEf1b019a3a427C08DC24Dd35f';
export const EXTERNAL_ACQUIRER_V2 = '0xD8a54c455c9e902569B88bBEC574686FC65BB977'; // rinkeby

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
