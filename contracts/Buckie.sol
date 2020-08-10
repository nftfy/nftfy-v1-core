// Buckie
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Buckie is ERC20
{
	constructor () ERC20("Buckie", "BUK") public
	{
		_setupDecimals(18);
	}

	function faucet() public
	{
		address _target = msg.sender;
		_mint(_target, 10000_000000000000000000);
	}
}
