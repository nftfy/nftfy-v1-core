// Blockies
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Blockies is ERC721
{
	constructor () ERC721("Blockies", "KIE") public
	{
		_setBaseURI("https://blockies.tk/");
	}

	function faucet() public
	{
		address _target = msg.sender;
		uint256 _tokenId = totalSupply() + 1;
		_safeMint(_target, _tokenId);
	}
}
