const NFY = artifacts.require('NFY');
const Distribution = artifacts.require('Distribution');

module.exports = async (deployer) => {
  await deployer.deploy(NFY);
  const token = await NFY.deployed();
  await deployer.deploy(Distribution, token.address);
};
