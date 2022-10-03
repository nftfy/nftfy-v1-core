import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";

function _throw(message: string): never { throw new Error(message); }

const keystore: { [key: string]: string } = require('./keystore.json');
const etherscan: { [key: string]: string } = require('./etherscan.json');

const privateKeyId: string = process.env['PRIVATE_KEY_ID'] || 'default';
const privateKey: string = process.env['PRIVATE_KEY'] || keystore[privateKeyId] || _throw('Unknown privateKeyId: ' + privateKeyId);
const network: string = process.env['NETWORK'] || 'mainnet';
const balance: string = process.env['BALANCE'] || '1000000000000000000000';
const infuraProjectId: string = process.env['INFURA_PROJECT_ID'] || '';

const NETWORK_CONFIG: { [name: string]: [number, string] } = {
  // mainnets
  'mainnet': [1, 'https://mainnet.infura.io/v3/' + infuraProjectId], // ethereum
  'avaxmain': [43114, 'https://api.avax.network/ext/bc/C/rpc'], // avalanche
  'bscmain': [56, 'https://bsc-dataseed.binance.org'], // bnb smart chain
  'ftmmain': [250, 'https://rpc.ftm.tools'], // fantom
  'maticmain': [137, 'https://polygon-rpc.com'], // polygon
  // testnets
  'ropsten': [3, 'https://ropsten.infura.io/v3/' + infuraProjectId], // ropsten
  'rinkeby': [4, 'https://rinkeby.infura.io/v3/' + infuraProjectId], // rinkeby
  'kovan': [42, 'https://kovan.infura.io/v3/' + infuraProjectId], // kovan
  'goerli': [5, 'https://goerli.infura.io/v3/' + infuraProjectId], // goerli
  'avaxtest': [43113, 'https://api.avax-test.network/ext/bc/C/rpc'], // fuji
  'bsctest': [97, 'https://data-seed-prebsc-1-s1.binance.org:8545'], // chapel
  'ftmtest': [4002, 'https://rpc.testnet.fantom.network'], // fantom testnet
  'matictest': [80001, 'https://matic-mumbai.chainstacklabs.com'], // mumbai
};

const [chainId, url] = NETWORK_CONFIG[network] || _throw('Unknown network: ' + network);

export default {
  solidity: {
    version: '0.6.12',
    settings: {
      optimizer: {
        enabled: true,
        runs: 88888,
      },
    },
  },
  networks: {
    livenet: { url, accounts: [privateKey] },
    hardhat: { chainId, forking: { url }, accounts: [{ privateKey, balance }] },
  },
  etherscan: {
    apiKey: {
      // mainnets
      mainnet: etherscan['mainnet'], // ethereum
      avalanche: etherscan['avaxmain'], // avalanche
      bsc: etherscan['bscmain'], // bnb smart chain
      opera: etherscan['ftmmain'], // fantom
      polygon: etherscan['maticmain'], // polygon
      // testnets
      ropsten: etherscan['mainnet'], // ropsten
      rinkeby: etherscan['mainnet'], // rinkeby
      kovan: etherscan['mainnet'], // kovan
      goerli: etherscan['mainnet'], // goerli
      avalancheFujiTestnet: etherscan['avaxmain'], // fuji
      bscTestnet: etherscan['bscmain'], // chapel
      ftmTestnet: etherscan['ftmmain'], // fantom testnet
      polygonMumbai: etherscan['maticmain'], // mumbai
    },
  },
};
