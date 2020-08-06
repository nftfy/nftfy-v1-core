const Nftfy = artifacts.require('Nftfy');
const Wrapper = artifacts.require('Wrapper');
const Shares = artifacts.require('Shares');

module.exports = function(deployer) {
  deployer.deploy(Wrapper);
  deployer.deploy(Shares);
  deployer.link(Wrapper, Nftfy);
  deployer.link(Shares, Nftfy);
  deployer.deploy(Nftfy);
};
