import hardhat from 'hardhat';

function _throw(message: string): never { throw new Error(message); }

async function verifyContract(address: string, contract: string, ...constructorArguments: unknown[]): Promise<boolean> {
  try {
    await hardhat.run('verify:verify', { address, contract, constructorArguments });
  } catch (e) {
    if (String(e).toLowerCase().indexOf('already verified') >= 0) return false;
    throw e;
  }
  return true;
}

const NETWORK_CONFIG: { [chainId: number]: [string, string, string] } = {
  // mainnets
  1: ['0xc718E5a5b06ce7FEd722B128C0C0Eb9c5c902D92', '0x3112eb8e651611Fdb8C9a5b9f80222b090e36601', '0x2fE2000660e1Bf9BAe5411dD42bbC8A46ac04903'], // ethereum
  43114: ['0x4748d173d1A8becFB9afC0aB2262EcDDf6822294', '0x3112eb8e651611Fdb8C9a5b9f80222b090e36601', '0x96239600f07C43222D4793E00a4E5086DF01e27B'], // avalanche
  56: ['0x4e9cA8ca6A113FC3Db72677aa04C8DE028618377', '0x3112eb8e651611Fdb8C9a5b9f80222b090e36601', '0xDD5AE1081F189fafFe4B6bB214a51B58D8062549'], // bnb smart chain
  250: ['0x8CBA65A8780e9887a51E77258b701db1e7aBAC05', '0x3112eb8e651611Fdb8C9a5b9f80222b090e36601', '0x96239600f07C43222D4793E00a4E5086DF01e27B'], // fantom
  137: ['0xB41bbAEAd46042a229C6870207eB072aBb4FC18a', '0x3112eb8e651611Fdb8C9a5b9f80222b090e36601', '0xBAB15cb2e1f41D657Eff58C46FBB917ED9947d43'], // polygon
  // testnets
  3: ['0x3112eb8e651611Fdb8C9a5b9f80222b090e36601', '0xFDf35F1Bfe270e636f535a45Ce8D02457676e050', '0x3112eb8e651611Fdb8C9a5b9f80222b090e36601'], // ropsten
  4: ['0x3112eb8e651611Fdb8C9a5b9f80222b090e36601', '0xFDf35F1Bfe270e636f535a45Ce8D02457676e050', '0x3112eb8e651611Fdb8C9a5b9f80222b090e36601'], // rinkeby
  42: ['0x3112eb8e651611Fdb8C9a5b9f80222b090e36601', '0xFDf35F1Bfe270e636f535a45Ce8D02457676e050', '0x3112eb8e651611Fdb8C9a5b9f80222b090e36601'], // kovan
  5: ['0x3112eb8e651611Fdb8C9a5b9f80222b090e36601', '0xFDf35F1Bfe270e636f535a45Ce8D02457676e050', '0x3112eb8e651611Fdb8C9a5b9f80222b090e36601'], // goerli
  43113: ['0x3112eb8e651611Fdb8C9a5b9f80222b090e36601', '0xFDf35F1Bfe270e636f535a45Ce8D02457676e050', '0x3112eb8e651611Fdb8C9a5b9f80222b090e36601'], // fuji
  97: ['0x3112eb8e651611Fdb8C9a5b9f80222b090e36601', '0xFDf35F1Bfe270e636f535a45Ce8D02457676e050', '0x3112eb8e651611Fdb8C9a5b9f80222b090e36601'], // chapel
  4002: ['0x3112eb8e651611Fdb8C9a5b9f80222b090e36601', '0xFDf35F1Bfe270e636f535a45Ce8D02457676e050', '0x3112eb8e651611Fdb8C9a5b9f80222b090e36601'], // fantom testnet
  80001: ['0x3112eb8e651611Fdb8C9a5b9f80222b090e36601', '0xFDf35F1Bfe270e636f535a45Ce8D02457676e050', '0x3112eb8e651611Fdb8C9a5b9f80222b090e36601'], // mumbai
};

async function main(args: string[]): Promise<void> {

  const { chainId } = await hardhat.ethers.provider.getNetwork();
  console.log('chainId ' + chainId);

  const signers = await hardhat.ethers.getSigners();
  if (signers.length !== 1) throw new Error('panic');
  const [signer] = signers;
  if (signer === undefined) throw new Error('panic');
  const FROM = await signer.getAddress();
  console.log('FROM=' + FROM);

  const [ADMIN, FUNDING, VAULT] = NETWORK_CONFIG[chainId] || _throw('Unknown chainId: ' + chainId);
  console.log('ADMIN=' + ADMIN);
  console.log('FUNDING=' + FUNDING);
  console.log('VAULT=' + VAULT);

  const FEE = 50000000000000000n;
  console.log('FEE=' + FEE);

  const PERPETUAL_OPEN_COLLECTIVE_PURCHASE_V2 = '0xC841052b1C22059beF16A216a7488b39393B1126';
  const EXTERNAL_ACQUIRER_V2 = '0xCa05bB38f014622119eb8d59Ec6115ea64762836';

  await verifyContract(PERPETUAL_OPEN_COLLECTIVE_PURCHASE_V2, 'contracts/v1.5/PerpetualOpenCollectivePurchaseV2.sol:PerpetualOpenCollectivePurchaseV2', FEE, VAULT);
  await verifyContract(EXTERNAL_ACQUIRER_V2, 'contracts/v1.5/ExternalAcquirerV2.sol:ExternalAcquirerV2', PERPETUAL_OPEN_COLLECTIVE_PURCHASE_V2);

}

main(process.argv)
  .then(() => process.exit(0))
  .catch((e) => process.exit((console.error(e), 1)));
