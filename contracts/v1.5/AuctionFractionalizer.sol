// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { AuctionFractions } from "./AuctionFractions.sol";
import { AuctionFractionsImpl } from "./AuctionFractionsImpl.sol";

contract AuctionFractionalizer is ReentrancyGuard
{
	uint256 public immutable fee;
	address payable public immutable vault;

	constructor (uint256 _fee, address payable _vault) public
	{
		require(_fee <= 1e18, "invalid fee");
		require(_vault != address(0), "invalid address");
		fee = _fee;
		vault = _vault;
	}

	function fractionalize(address _target, uint256 _tokenId, string memory _name, string memory _symbol, uint8 _decimals, uint256 _fractionsCount, uint256 _fractionPrice, address _paymentToken) external nonReentrant
	{
		address _from = msg.sender;
		address _fractions = address(new AuctionFractions());
		IERC721(_target).transferFrom(_from, _fractions, _tokenId);
		AuctionFractionsImpl(_fractions).initialize(_from, _target, _tokenId, _name, _symbol, _decimals, _fractionsCount, _fractionPrice, _paymentToken, fee, vault);
		emit Fractionalize(_from, _target, _tokenId, _fractions);
	}

	event Fractionalize(address indexed _from, address indexed _target, uint256 indexed _tokenId, address _fractions);
}
