import 'source-map-support/register';

import { fetchNft } from './index';

async function main(args: string[]): Promise<void> {
  const network = args[2] || 'mainnet';
  const apiKey = args[3] || '694676881cda4c15a326d69f2b603e47';
//  console.log(await listNfts(apiKey, network, true, Number.MAX_VALUE));
  console.log(await fetchNft(apiKey, '0x60e4d786628fea6478f785a6d7e704777c86a7c6', 12412n, network, true));
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
