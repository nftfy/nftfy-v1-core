// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IAuctionFractionalizer } from "./IAuctionFractionalizer.sol";
import { LibCreate } from "./LibCreate.sol";

interface LegacyFractionalizer
{
	function fractionalize(address _target, uint256 _tokenId, string memory _name, string memory _symbol, uint8 _decimals, uint256 _fractionsCount, uint256 _fractionPrice, address _paymentToken) external;
}

contract CompatibilityFractionalizer is IAuctionFractionalizer, ERC721Holder, Ownable, ReentrancyGuard
{
	using Address for address;
	using SafeERC20 for IERC20;
	using LibCreate for address;

	address public immutable fractionalizer;
	uint256 public nonce = 1;

	constructor (address _fractionalizer) public
	{
		fractionalizer = _fractionalizer;
	}

	function updateNonce(uint256 _nonce) external onlyOwner
	{
		nonce = _nonce;
	}

	function fractionalize(address _target, uint256 _tokenId, string memory _name, string memory _symbol, uint8 _decimals, uint256 _fractionsCount, uint256 _fractionPrice, address _paymentToken, uint256 /*_kickoff*/, uint256 /*_duration*/, uint256 /*_fee*/) external override nonReentrant returns (address _fractions)
	{
		address _from = msg.sender;
		IERC721(_target).transferFrom(_from, address(this), _tokenId);
		IERC721(_target).approve(fractionalizer, _tokenId);
		while (true) {
			_fractions = fractionalizer.computeAddress(nonce);
			if (!_fractions.isContract()) break;
			nonce++;
		}
		LegacyFractionalizer(fractionalizer).fractionalize(_target, _tokenId, _name, _symbol, _decimals, _fractionsCount, _fractionPrice, _paymentToken);
		require(_fractions.isContract(), "invalid nonce");
		IERC20(_fractions).safeTransfer(_from, _fractionsCount);
		return _fractions;
	}
}
