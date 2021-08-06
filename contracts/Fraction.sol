// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { SafeERC721Metadata } from "./SafeERC721Metadata.sol";

library SafeERC721
{
	function safeApprove(IERC721 _token, address _to, uint256 _tokenId) internal
	{
		try IERC721(_token).approve(_to, _tokenId) {
		} catch (bytes memory /* _data */) {
		}
	}
}

contract Fractionalizer
{
	function securitize(address _target, uint256 _tokenId, uint256 _sharesCount, uint8 _decimals, uint256 _sharePrice, address _paymentToken) external
	{
		address _from = msg.sender;
		address _fractions = address(new Fraction());
		FractionImpl(_fractions).initialize(_target, _tokenId, _from, _sharesCount, _decimals, _sharePrice, _paymentToken);
		IERC721(_target).transferFrom(_from, _fractions, _tokenId);
	}
}

contract Fraction
{
	fallback () external payable
	{
		assembly {
			calldatacopy(0, 0, calldatasize())
			let result := delegatecall(gas(), 0, 0, calldatasize(), 0, 0) // replace 2nd parameter by FractionImpl address
			returndatacopy(0, 0, returndatasize())
			switch result
			case 0 { revert(0, returndatasize()) }
			default { return(0, returndatasize()) }
		}
	}
}

contract FractionImpl is ERC721Holder, ERC20, ReentrancyGuard
{
	using SafeERC20 for IERC20;
	using SafeERC721 for IERC721;
	using Strings for uint256;
	using SafeERC721Metadata for IERC721Metadata;

	address public target;
	uint256 public tokenId;
	uint256 public sharesCount;
	uint256 public sharePrice;
	address public paymentToken;

	bool public released;

	constructor () ERC20("", "") public {}

	function __name() public view /*override*/ returns (string memory _name) // change ERC20 name() to virtual on deploy
	{
		return string(abi.encodePacked(IERC721Metadata(target).safeName(), " #", tokenId.toString(), " Shares"));
	}

	function __symbol() public view /*override*/ returns (string memory _symbol) // change ERC20 name() to virtual on deploy
	{
		return string(abi.encodePacked(IERC721Metadata(target).safeSymbol(), tokenId.toString()));
	}

	function initialize(address _target, uint256 _tokenId, address _from, uint256 _sharesCount, uint8 _decimals, uint256 _sharePrice, address _paymentToken) external
	{
		require(target == address(0), "already initialized");
		target = _target;
		tokenId = _tokenId;
		sharesCount = _sharesCount;
		sharePrice = _sharePrice;
		paymentToken = _paymentToken;
		// released = false;
		_setupDecimals(_decimals);
		_mint(_from, _sharesCount);
		emit Securitize(_from, _target, _tokenId, address(this));
	}

	function exitPrice() public view returns (uint256 _exitPrice)
	{
		return sharesCount * sharePrice;
	}

	function redeemAmountOf(address _from) public view returns (uint256 _redeemAmount)
	{
		require(!released, "token already redeemed");
		uint256 _sharesCount = balanceOf(_from);
		uint256 _exitPrice = exitPrice();
		return _exitPrice - _sharesCount * sharePrice;
	}

	function vaultBalance() external view returns (uint256 _vaultBalance)
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

	function redeem() external payable nonReentrant
	{
		require(!released, "token already redeemed");
		address payable _from = msg.sender;
		uint256 _paymentAmount = msg.value;
		uint256 _sharesCount = balanceOf(_from);
		uint256 _redeemAmount = redeemAmountOf(_from);
		if (paymentToken == address(0)) {
			require(_paymentAmount >= _redeemAmount, "insufficient payment amount");
			uint256 _changeAmount = _paymentAmount - _redeemAmount;
			if (_changeAmount > 0) _from.transfer(_changeAmount);
		} else {
			if (_paymentAmount > 0) _from.transfer(_paymentAmount);
			if (_redeemAmount > 0) IERC20(paymentToken).safeTransferFrom(_from, address(this), _redeemAmount);
		}
		released = true;
		if (_sharesCount > 0) _burn(_from, _sharesCount);
		IERC721(target).safeApprove(address(this), tokenId);
		IERC721(target).transferFrom(address(this), _from, tokenId);
		emit Redeem(_from, target, tokenId, address(this));
		_cleanup();
	}

	function claim() external nonReentrant
	{
		require(released, "token not redeemed");
		address payable _from = msg.sender;
		uint256 _sharesCount = balanceOf(_from);
		require(_sharesCount > 0, "nothing to claim");
		uint256 _claimAmount = vaultBalanceOf(_from);
		assert(_claimAmount > 0);
		_burn(_from, _sharesCount);
		if (paymentToken == address(0)) _from.transfer(_claimAmount);
		else IERC20(paymentToken).safeTransfer(_from, _claimAmount);
		emit Claim(_from, target, tokenId, address(this), _sharesCount);
		_cleanup();
	}

	function _cleanup() internal
	{
		uint256 _sharesLeft = totalSupply();
		if (_sharesLeft == 0) {
			selfdestruct(address(0));
		}
	}

	event Securitize(address indexed _from, address indexed _target, uint256 indexed _tokenId, address _shares);
	event Redeem(address indexed _from, address indexed _target, uint256 indexed _tokenId, address _shares);
	event Claim(address indexed _from, address indexed _target, uint256 indexed _tokenId, address _shares, uint256 _sharesCount);
}
