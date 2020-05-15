# Uses http://dapp.tools/
# $ curl https://dapp.tools/install | sh
# $ . "$HOME/.nix-profile/etc/profile.d/nix.sh"
# $ make

SHELL=bash

export SOLC_FLAGS?=--optimize
#export ETH_GAS?=4000000
#export ETH_GAS_PRICE?=4000000000
#export ETH_FROM?=$(shell seth rpc eth_coinbase)

all: build;
build:; dapp build
test:; dapp test
clean:; dapp clean
deploy: build; dapp create Niftfy
