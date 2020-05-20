# Uses http://dapp.tools/
# $ curl https://dapp.tools/install | sh
# $ . "$HOME/.nix-profile/etc/profile.d/nix.sh"
# $ make
# $ make deploy

export SOLC_FLAGS?=--optimize
export ETH_GAS?=4000000
export ETH_GAS_PRICE?=4000000000
export ETH_FROM?=0x294cbc8b329fed25909940d77296926162fe3ae8
export ETH_KEYSTORE?=.keystore
export ETH_PASSWORD?=.password
export ETH_RPC_URL?=https://rinkeby.infura.io/v3/8b3f1f9748aa4141b4af6c240af3f64d

all: build;
build:; dapp build
test:; dapp test
clean:; dapp clean
deploy: build; dapp create Nftfy
