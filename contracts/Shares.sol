// Shares / ERC721Shares
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ERC721Wrapper } from "./Wrapper.sol";

library Shares
{
	using Strings for uint256;

	function create(IERC721Metadata _metadata, ERC721Wrapper _wrapper, uint256 _tokenId, address _from, uint256 _sharesCount, uint8 _decimals, uint256 _sharePrice, IERC20 _paymentToken, bool _remnant) public returns (ERC721Shares _shares)
	{
		string memory _name = string(abi.encodePacked(_metadata.name(), " #", _tokenId.toString(), " Shares"));
		string memory _symbol = string(abi.encodePacked(_metadata.symbol(), _tokenId.toString()));
		return new ERC721Shares(_name, _symbol, _wrapper, _tokenId, _from, _sharesCount, _decimals, _sharePrice, _paymentToken, _remnant);
	}
}

contract ERC721Shares is ERC721Holder, ERC20
{
	using SafeERC20 for IERC20;

	ERC721Wrapper public wrapper;
	uint256 public tokenId;
	uint256 public sharesCount;
	uint256 public sharePrice;
	IERC20 public paymentToken;
	bool public remnant;

	bool public released;

	constructor (string memory _name, string memory _symbol, ERC721Wrapper _wrapper, uint256 _tokenId, address _from, uint256 _sharesCount, uint8 _decimals, uint256 _sharePrice, IERC20 _paymentToken, bool _remnant) ERC20(_name, _symbol) public
	{
		wrapper = _wrapper;
		tokenId = _tokenId;
		sharesCount = _sharesCount;
		sharePrice = _sharePrice;
		paymentToken = _paymentToken;
		remnant = _remnant;
		released = false;
		_setupDecimals(_decimals);
		_mint(_from, _sharesCount);
	}

	function exitPrice() public view returns (uint256 _exitPrice)
	{
		return sharesCount * sharePrice;
	}

	function redeem() public payable
	{
		require(!released);
		address payable _from = msg.sender;
		uint256 _exitPrice = exitPrice();
		uint256 _sharesCount = balanceOf(_from);
		uint256 _claimAmount = _sharesCount * sharePrice;
		if (paymentToken == IERC20(0)) {
			uint256 _paymentAmount = msg.value;
			uint256 _totalAmount = _paymentAmount + _claimAmount;
			require(_totalAmount >= _exitPrice);
			uint256 _changeAmount = _totalAmount - _exitPrice;
			if (_changeAmount > 0) _from.transfer(_changeAmount);
		} else {
			uint256 _remainingAmount = _exitPrice - _claimAmount;
			if (_remainingAmount > 0) paymentToken.safeTransferFrom(_from, address(this), _remainingAmount);
		}
		released = true;
		_burn(_from, _sharesCount);
		wrapper._remove(_from, tokenId, remnant);
		wrapper.target().safeTransferFrom(address(this), _from, tokenId);
		uint256 _sharesLeft = totalSupply();
		if (_sharesLeft == 0) selfdestruct(_from);
	}

	function claim() public
	{
		require(released);
		address payable _from = msg.sender;
		uint256 _sharesCount = balanceOf(_from);
		require(_sharesCount > 0);
		_burn(_from, _sharesCount);
		uint256 _claimAmount = _sharesCount * sharePrice;
		if (paymentToken == IERC20(0)) _from.transfer(_claimAmount);
		else paymentToken.safeTransfer(_from, _claimAmount);
		uint256 _sharesLeft = totalSupply();
		if (_sharesLeft == 0) selfdestruct(_from);
	}
}
