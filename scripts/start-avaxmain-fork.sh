#!/bin/bash

source .env

CHAIN_ID=43114
GAS_LIMIT=281474976710655
FORK_URL='https://api.avax.network/ext/bc/C/rpc'

BALANCE=100000000000000000000000

npx ganache-cli \
	-q \
	-h 0.0.0.0 \
	-i $CHAIN_ID \
	--chainId $CHAIN_ID \
	-l $GAS_LIMIT \
	-f $FORK_URL \
	--account $PRIVATE_KEY,$BALANCE
