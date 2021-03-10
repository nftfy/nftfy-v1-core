const Migrations = artifacts.require('Migrations');

module.exports = async (deployer, network, [account]) => {
  await deployer.deploy(Migrations);
};
