// Shares / ERC721Shares
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { SafeERC721Metadata } from "./SafeERC721Metadata.sol";
import { ERC721Wrapper } from "./Wrapper.sol";

library Shares
{
	using Strings for uint256;
	using SafeERC721Metadata for IERC721Metadata;

	function create(ERC721Wrapper _wrapper, uint256 _tokenId, address _from, uint256 _sharesCount, uint8 _decimals, uint256 _sharePrice, IERC20 _paymentToken, bool _remnant) public returns (ERC721Shares _shares)
	{
		IERC721 _target = _wrapper.target();
		IERC721Metadata _metadata = IERC721Metadata(address(_target));
		string memory _name = string(abi.encodePacked(_metadata.safeName(), " #", _tokenId.toString(), " Shares"));
		string memory _symbol = string(abi.encodePacked(_metadata.safeSymbol(), _tokenId.toString()));
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
		emit Securitize(_from, address(wrapper.target()), tokenId, address(this));
	}

	function exitPrice() public view returns (uint256 _exitPrice)
	{
		return sharesCount * sharePrice;
	}

	function redeemAmountOf(address _from) public view returns (uint256 _redeemAmount)
	{
		require(!released);
		uint256 _sharesCount = balanceOf(_from);
		uint256 _exitPrice = exitPrice();
		return _exitPrice - _sharesCount * sharePrice;
	}

	function vaultBalance() public view returns (uint256 _vaultBalance)
	{
		if (!released) return 0;
		uint256 _sharesCount = totalSupply();
		return _sharesCount * sharePrice;
	}

	function vaultBalanceOf(address _from) public view returns (uint256 _vaultBalanceOf)
	{
		if (!released) return 0;
		uint256 _sharesCount = balanceOf(_from);
		return _sharesCount * sharePrice;
	}

	function redeem() public payable
	{
		require(!released);
		address payable _from = msg.sender;
		uint256 _paymentAmount = msg.value;
		uint256 _sharesCount = balanceOf(_from);
		uint256 _redeemAmount = redeemAmountOf(_from);
		if (paymentToken == IERC20(0)) {
			require(_paymentAmount >= _redeemAmount);
			uint256 _changeAmount = _paymentAmount - _redeemAmount;
			if (_changeAmount > 0) _from.transfer(_changeAmount);
		} else {
			if (_paymentAmount > 0) _from.transfer(_paymentAmount);
			if (_redeemAmount > 0) paymentToken.safeTransferFrom(_from, address(this), _redeemAmount);
		}
		released = true;
		if (_sharesCount > 0) _burn(_from, _sharesCount);
		wrapper._remove(_from, tokenId, remnant);
		wrapper.target().safeTransferFrom(address(this), _from, tokenId);
		_cleanup();
		emit Redeem(_from, address(wrapper.target()), tokenId, address(this));
	}

	function claim() public
	{
		require(released);
		address payable _from = msg.sender;
		uint256 _sharesCount = balanceOf(_from);
		require(_sharesCount > 0);
		uint256 _claimAmount = vaultBalanceOf(_from);
		assert(_claimAmount > 0);
		_burn(_from, _sharesCount);
		if (paymentToken == IERC20(0)) _from.transfer(_claimAmount);
		else paymentToken.safeTransfer(_from, _claimAmount);
		_cleanup();
		emit Claim(_from, address(wrapper.target()), tokenId, address(this), _sharesCount);
	}

	function _cleanup() internal
	{
		uint256 _sharesLeft = totalSupply();
		if (_sharesLeft == 0) {
			wrapper._forget();
			selfdestruct(address(0));
		}
	}

	event Securitize(address indexed _from, address indexed _target, uint256 indexed _tokenId, address _shares);
	event Redeem(address indexed _from, address indexed _target, uint256 indexed _tokenId, address _shares);
	event Claim(address indexed _from, address indexed _target, uint256 indexed _tokenId, address _shares, uint256 _sharesCount);
}
