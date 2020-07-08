const { TruffleProvider } = require('@harmony-js/core');

const LOCAL_MNEMONIC = process.env.LOCAL_MNEMONIC;
const LOCAL_PRIVATE_KEY = process.env.LOCAL_PRIVATE_KEY;
const LOCAL_URL = process.env.LOCAL_URL;

const TESTNET_MNEMONIC = process.env.TESTNET_MNEMONIC;
const TESTNET_PRIVATE_KEY = process.env.TESTNET_PRIVATE_KEY;
const TESTNET_URL = process.env.TESTNET_URL;

const MAINNET_MNEMONIC = process.env.MAINNET_MNEMONIC;
const MAINNET_PRIVATE_KEY = process.env.MAINNET_PRIVATE_KEY;
const MAINNET_URL = process.env.MAINNET_URL;

const GAS_LIMIT = process.env.GAS_LIMIT;
const GAS_PRICE = process.env.GAS_PRICE;

module.exports = {
  networks: {
    local: {
      network_id: '2',
      provider: () => {
        const provider = new TruffleProvider(LOCAL_URL, {memonic: LOCAL_MNEMONIC}, {shardID: 0, chainId: 2}, {gasLimit: GAS_LIMIT, gasPrice: GAS_PRICE});
        const account = provider.addByPrivateKey(LOCAL_PRIVATE_KEY);
        provider.setSigner(account);
        return provider;
      },
    },
    testnet: {
      network_id: '2', // Any network (default: none)
      provider: () => {
        const provider = new TruffleProvider(TESTNET_URL, {memonic: TESTNET_MNEMONIC}, {shardID: 0, chainId: 2}, {gasLimit: GAS_LIMIT, gasPrice: GAS_PRICE});
        const account = provider.addByPrivateKey(TESTNET_PRIVATE_KEY);
        provider.setSigner(account);
        return provider;
      },
    },
    mainnet: {
      network_id: '1',
      provider: () => {
        const provider = new TruffleProvider(MAINNET_URL, {memonic: MAINNET_MNEMONIC}, {shardID: 0, chainId: 1}, {gasLimit: GAS_LIMIT, gasPrice: GAS_PRICE});
        const account = provider.addByPrivateKey(MAINNET_PRIVATE_KEY);
        provider.setSigner(account);
        return provider;
      },
    },
  },
}
