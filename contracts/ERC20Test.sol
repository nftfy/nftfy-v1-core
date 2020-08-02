// Blockies
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Test is ERC20
{
	constructor (address _owner, uint256 _supply) ERC20("ERC-20 Test", "TEST") public
	{
		_setupDecimals(2);
		_mint(_owner, _supply);
	}
}
