// Nftfy
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
	function create(ERC721Wrapper _wrapper, uint256 _tokenId, address _owner, uint256 _shareCount, uint8 _decimals, uint256 _sharePrice, IERC20 _paymentToken, bool _remnant) public returns (ERC721Shares _shares)
	{
		return new ERC721Shares(_wrapper, _tokenId, _owner, _shareCount, _decimals, _sharePrice, _paymentToken, _remnant);
	}
}

contract ERC721Shares is ERC721Holder, ERC20
{
	using Strings for uint256;
	using SafeERC20 for IERC20;

	ERC721Wrapper public wrapper;
	uint256 public tokenId;
	uint256 public shareCount;
	uint256 public sharePrice;
	IERC20 public paymentToken;
	bool remnant;
	bool claimable;

	function n(ERC721Wrapper _wrapper, uint256 _tokenId) internal view returns (string memory _name)
	{
		address _target = address(_wrapper.target());
		return string(abi.encodePacked(IERC721Metadata(_target).name(), " #", _tokenId.toString(), " Shares"));
	}

	function s(ERC721Wrapper _wrapper, uint256 _tokenId) internal view returns (string memory _symbol)
	{
		address _target = address(_wrapper.target());
		return string(abi.encodePacked(IERC721Metadata(_target).symbol(), _tokenId.toString()));
	}

	constructor (ERC721Wrapper _wrapper, uint256 _tokenId, address _owner, uint256 _shareCount, uint8 _decimals, uint256 _sharePrice, IERC20 _paymentToken, bool _remnant) ERC20(n(_wrapper, _tokenId), s(_wrapper, _tokenId)) public
	{
		wrapper = _wrapper;
		tokenId = _tokenId;
		shareCount = _shareCount;
		sharePrice = _sharePrice;
		paymentToken = _paymentToken;
		remnant = _remnant;
		claimable = false;
		_setupDecimals(_decimals);
		_mint(_owner, _shareCount);
	}

	function exitPrice() public view returns (uint256 _exitPrice)
	{
		return shareCount * sharePrice;
	}

	function isClaimable() public view returns (bool _redeemable)
	{
		return claimable;
	}

	function redeem() public payable
	{
		require(!claimable);
		address payable _from = msg.sender;
		uint256 _exitPrice = exitPrice();
		uint256 _balance = balanceOf(_from);
		uint256 _value2 = sharePrice * _balance;
		if (paymentToken == IERC20(0)) {
			uint256 _value1 = msg.value;
			uint256 _total = _value1 + _value2;
			require(_total >= _exitPrice);
			uint256 _change = _total - _exitPrice;
			if (_change > 0) _from.transfer(_change);
		} else {
			uint256 _value1 = _exitPrice - _value2;
			if (_value1 > 0) paymentToken.safeTransferFrom(_from, address(this), _value1);
		}
		claimable = true;
		_burn(_from, _balance);
		wrapper._remove(_from, tokenId, remnant);
		wrapper.target().safeTransferFrom(address(this), _from, tokenId);
		uint256 _supply = totalSupply();
		if (_supply == 0) selfdestruct(_from);
	}

	function claim() public
	{
		require(claimable);
		address payable _from = msg.sender;
		uint256 _balance = balanceOf(_from);
		require(_balance > 0);
		_burn(_from, _balance);
		uint256 _amount = _balance * sharePrice;
		if (paymentToken == IERC20(0)) _from.transfer(_amount);
		else paymentToken.safeTransfer(_from, _amount);
		uint256 _supply = totalSupply();
		if (_supply == 0) selfdestruct(_from);
	}
}
