import 'source-map-support/register';

import { fetchNft } from './index';

async function main(args: string[]): Promise<void> {
  const network = args[2] || 'mainnet';
  const apiKey = args[3] || '2f6f419a083c46de9d83ce3dbe7db601';
//  console.log(await listNfts(apiKey, network, true, Number.MAX_VALUE));
  console.log(await fetchNft(apiKey, '0xE4B3363827962982fab7d9d255d9aE248e80db6c', 23n, network, true));
}

type MainFn = (args: string[]) => Promise<void>;

async function __entrypoint(main: MainFn): Promise<void> {
  try {
    await main(process.argv);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
  process.exit(0);
}

__entrypoint(main);
