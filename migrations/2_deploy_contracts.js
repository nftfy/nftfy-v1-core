const Nftfy = artifacts.require('Nftfy');
const Wrapper = artifacts.require('Wrapper');
const Shares = artifacts.require('Shares');
const SafeERC721Metadata = artifacts.require('SafeERC721Metadata');

module.exports = function(deployer) {
  deployer.deploy(SafeERC721Metadata);
  deployer.link(SafeERC721Metadata, Wrapper);
  deployer.deploy(Wrapper);
  deployer.link(SafeERC721Metadata, Shares);
  deployer.deploy(Shares);
  deployer.link(Wrapper, Nftfy);
  deployer.link(Shares, Nftfy);
  deployer.deploy(Nftfy);
};
