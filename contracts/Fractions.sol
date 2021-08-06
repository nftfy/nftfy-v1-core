// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

library SafeERC721
{
	function safeName(IERC721Metadata _metadata) internal view returns (string memory _name)
	{
		try _metadata.name() returns (string memory _n) { return _n; } catch {}
	}

	function safeSymbol(IERC721Metadata _metadata) internal view returns (string memory _symbol)
	{
		try _metadata.symbol() returns (string memory _s) { return _s; } catch {}
	}

	function safeTokenURI(IERC721Metadata _metadata, uint256 _tokenId) internal view returns (string memory _tokenURI)
	{
		try _metadata.tokenURI(_tokenId) returns (string memory _t) { return _t; } catch {}
	}

	function safeApprove(IERC721 _token, address _to, uint256 _tokenId) internal
	{
		try _token.approve(_to, _tokenId) {} catch {}
	}
}

contract Fractionalizer is ReentrancyGuard
{
	function securitize(address _target, uint256 _tokenId, uint256 _sharesCount, uint8 _decimals, uint256 _sharePrice, address _paymentToken) external nonReentrant
	{
		address _from = msg.sender;
		address _fractions = address(new Fractions());
		IERC721(_target).transferFrom(_from, _fractions, _tokenId);
		FractionsImpl(_fractions).initialize(_from, _target, _tokenId, _sharesCount, _decimals, _sharePrice, _paymentToken);
		emit Fractionalize(_from, _target, _tokenId, _fractions);
	}

	event Fractionalize(address indexed _from, address indexed _target, uint256 indexed _tokenId, address _fractions);
}

contract Fractions
{
	fallback () external payable
	{
		assembly {
			calldatacopy(0, 0, calldatasize())
			let result := delegatecall(gas(), 0, 0, calldatasize(), 0, 0) // replace 2nd parameter by FractionsImpl address on deploy
			returndatacopy(0, 0, returndatasize())
			switch result
			case 0 { revert(0, returndatasize()) }
			default { return(0, returndatasize()) }
		}
	}
}

contract FractionsImpl is ERC721Holder, ERC20, ReentrancyGuard
{
	using SafeERC20 for IERC20;
	using SafeERC721 for IERC721;
	using SafeERC721 for IERC721Metadata;
	using Strings for uint256;

	address public target;
	uint256 public tokenId;
	uint256 public sharesCount;
	uint256 public sharePrice;
	address public paymentToken;

	bool public released;

	constructor () ERC20("Fractions", "FRAC") public
	{
		target = address(-1); // prevents proxy code from misuse
	}

	function __name() public view /*override*/ returns (string memory _name) // change ERC20 name() to virtual on deploy
	{
		return string(abi.encodePacked(IERC721Metadata(target).safeName(), " #", tokenId.toString(), " Fractions"));
	}

	function __symbol() public view /*override*/ returns (string memory _symbol) // change ERC20 name() to virtual on deploy
	{
		return string(abi.encodePacked(IERC721Metadata(target).safeSymbol(), tokenId.toString()));
	}

	function initialize(address _from, address _target, uint256 _tokenId, uint256 _sharesCount, uint8 _decimals, uint256 _sharePrice, address _paymentToken) external
	{
		require(target == address(0), "already initialized");
		require(IERC721(_target).ownerOf(_tokenId) == address(this), "token not staked");
		target = _target;
		tokenId = _tokenId;
		sharesCount = _sharesCount;
		sharePrice = _sharePrice;
		paymentToken = _paymentToken;
		released = false;
		_setupDecimals(_decimals);
		_mint(_from, _sharesCount);
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

	event Redeem(address indexed _from, address indexed _target, uint256 indexed _tokenId, address _fractions);
	event Claim(address indexed _from, address indexed _target, uint256 indexed _tokenId, address _fractions, uint256 _sharesCount);
}
