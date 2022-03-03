require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');
const gasLimit = process.env['GAS_LIMIT'];
const gasPrice = process.env['GAS_PRICE'];
const privateKey = process.env['PRIVATE_KEY'];
const infuraProjectId = process.env['INFURA_PROJECT_ID'];

module.exports = {
  compilers: {
    solc: {
      version: '0.6.12',
      optimizer: {
        enabled: false,
        runs: 200,
      },
    },
  },
  networks: {
    mainnet: {
      network_id: 1,
      gasPrice,
      provider: () => new HDWalletProvider(privateKey, 'https://mainnet.infura.io/v3/' + infuraProjectId),
    },
    ropsten: {
      network_id: 3,
      gasPrice,
      provider: () => new HDWalletProvider(privateKey, 'https://ropsten.infura.io/v3/' + infuraProjectId),
      skipDryRun: true,
    },
    rinkeby: {
      network_id: 4,
      gasPrice,
      provider: () => new HDWalletProvider(privateKey, 'https://rinkeby.infura.io/v3/' + infuraProjectId),
      skipDryRun: true,
    },
    kovan: {
      network_id: 42,
      gasPrice,
      provider: () => new HDWalletProvider(privateKey, 'https://kovan.infura.io/v3/' + infuraProjectId),
      skipDryRun: true,
    },
    goerli: {
      network_id: 5,
      gasPrice,
      provider: () => new HDWalletProvider(privateKey, 'https://goerli.infura.io/v3/' + infuraProjectId),
      skipDryRun: true,
    },
    bscmain: {
      network_id: 56,
      gasPrice,
      provider: () => new HDWalletProvider(privateKey, 'https://bsc-dataseed.binance.org/'),
    },
    bsctest: {
      network_id: 97,
      gasPrice,
      provider: () => new HDWalletProvider(privateKey, 'https://data-seed-prebsc-1-s1.binance.org:8545/'),
      skipDryRun: true,
    },
    maticmain: {
      network_id: 137,
      gasPrice,
      provider: () => new HDWalletProvider(privateKey, 'https://rpc-mainnet.maticvigil.com/'),
    },
    matictest: {
      network_id: 80001,
      provider: () => new HDWalletProvider(privateKey, 'https://rpc-mumbai.maticvigil.com/'),
      skipDryRun: true,
    },
    avaxmain: {
      network_id: 43114,
      gasPrice,
      provider: () => new HDWalletProvider(privateKey, 'https://api.avax.network/ext/bc/C/rpc'),
    },
    avaxtest: {
      network_id: 43113,
      provider: () => new HDWalletProvider(privateKey, 'https://api.avax-test.network/ext/bc/C/rpc'),
      skipDryRun: true,
    },
    ftmmain: {
      network_id: 250,
      gasPrice,
      provider: () => new HDWalletProvider(privateKey, 'https://rpcapi.fantom.network/'),
    },
    ftmtest: {
      network_id: 4002,
      provider: () => new HDWalletProvider(privateKey, 'https://rpc.testnet.fantom.network/'),
      skipDryRun: true,
    },
    development: {
      network_id: '*',
      gas: gasLimit,
      host: 'localhost',
      port: 8545,
      skipDryRun: true,
    },
  },
};
