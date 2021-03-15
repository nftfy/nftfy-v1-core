const Nftfy = artifacts.require('Nftfy');
const Wrapper = artifacts.require('Wrapper');
const Shares = artifacts.require('Shares');
const SafeERC721Metadata = artifacts.require('SafeERC721Metadata');

module.exports = async (deployer, network, [account]) => {
  await deployer.deploy(SafeERC721Metadata);
  deployer.link(SafeERC721Metadata, Wrapper);
  await deployer.deploy(Wrapper);
  deployer.link(SafeERC721Metadata, Shares);
  await deployer.deploy(Shares);
  deployer.link(Wrapper, Nftfy);
  deployer.link(Shares, Nftfy);
  await deployer.deploy(Nftfy);
};
