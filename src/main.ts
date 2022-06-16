import 'source-map-support/register';

import { fetchNft } from './index';

async function main(args: string[]): Promise<void> {
  const network = args[2] || 'mainnet';
  const apiKey = args[3] || '2f6f419a083c46de9d83ce3dbe7db601';
//  console.log(await listNfts(apiKey, network, true, Number.MAX_VALUE));
  console.log(await fetchNft(apiKey, '0x46bEF163D6C470a4774f9585F3500Ae3b642e751', 24n, network, true));
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
