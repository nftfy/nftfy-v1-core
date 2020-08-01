# Uses http://dapp.tools/
# $ curl https://dapp.tools/install | sh
# $ . "$HOME/.nix-profile/etc/profile.d/nix.sh"
# $ make
# $ make deploy

export SOLC_FLAGS?=--optimize
export ETH_GAS?=4000000
export ETH_GAS_PRICE?=4000000000
export ETH_FROM?=0x31020647f221876fee508143a0df139192ab9da7
export ETH_KEYSTORE?=.keystore
export ETH_PASSWORD?=.password
export ETH_RPC_URL?=https://rinkeby.infura.io/v3/8b3f1f9748aa4141b4af6c240af3f64d

all: build;
build:; dapp --use solc:0.5.15 build
test:; dapp test
clean:; dapp clean
deploy: build; dapp create Nftfy
#deploy: build; dapp create ERC20Test 0x58F28D1FD246dA5F6a34cAB3794A0A3C82372C69 100000000000
