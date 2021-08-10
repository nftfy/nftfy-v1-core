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

	function safeTransfer(IERC721 _token, address _to, uint256 _tokenId) internal
	{
		address _from = address(this);
		try _token.transferFrom(_from, _to, _tokenId) { return; } catch {}
		// attempts to handle non-conforming ERC721 contracts
		_token.approve(_from, _tokenId);
		_token.transferFrom(_from, _to, _tokenId);
	}
}

contract Fractionalizer is ReentrancyGuard
{
	function fractionalize(address _target, uint256 _tokenId, string memory _name, string memory _symbol, uint8 _decimals, uint256 _fractionsCount, uint256 _fractionPrice, address _paymentToken) external nonReentrant
	{
		address _from = msg.sender;
		address _fractions = address(new Fractions());
		IERC721(_target).transferFrom(_from, _fractions, _tokenId);
		FractionsImpl(_fractions).initialize(_from, _target, _tokenId, _name, _symbol, _decimals, _fractionsCount, _fractionPrice, _paymentToken);
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
	uint256 public fractionsCount;
	uint256 public fractionPrice;
	address public paymentToken;

	bool public released;

	string private name_;
	string private symbol_;

	constructor () ERC20("Fractions", "FRAC") public
	{
		target = address(-1); // prevents proxy code from misuse
	}

	function __name() public view /*override*/ returns (string memory _name) // change ERC20 name() to virtual on deploy
	{
		if (bytes(name_).length != 0) return name_;
		return string(abi.encodePacked(IERC721Metadata(target).safeName(), " #", tokenId.toString(), " Fractions"));
	}

	function __symbol() public view /*override*/ returns (string memory _symbol) // change ERC20 name() to virtual on deploy
	{
		if (bytes(symbol_).length != 0) return symbol_;
		return string(abi.encodePacked(IERC721Metadata(target).safeSymbol(), tokenId.toString()));
	}

	function initialize(address _from, address _target, uint256 _tokenId, string memory _name, string memory _symbol, uint8 _decimals, uint256 _fractionsCount, uint256 _fractionPrice, address _paymentToken) external
	{
		require(target == address(0), "already initialized");
		require(IERC721(_target).ownerOf(_tokenId) == address(this), "token not staked");
		require(_fractionsCount  > 0, "invalid fraction count");
		require(_fractionsCount * _fractionPrice / _fractionsCount == _fractionPrice, "invalid fraction price");
		target = _target;
		tokenId = _tokenId;
		fractionsCount = _fractionsCount;
		fractionPrice = _fractionPrice;
		paymentToken = _paymentToken;
		released = false;
		name_ = _name;
		symbol_ = _symbol;
		_setupDecimals(_decimals);
		_mint(_from, _fractionsCount);
	}

	function reservePrice() public view returns (uint256 _reservePrice)
	{
		return fractionsCount * fractionPrice;
	}

	function redeemAmountOf(address _from) public view returns (uint256 _redeemAmount)
	{
		require(!released, "token already redeemed");
		uint256 _fractionsCount = balanceOf(_from);
		uint256 _reservePrice = reservePrice();
		return _reservePrice - _fractionsCount * fractionPrice;
	}

	function vaultBalance() external view returns (uint256 _vaultBalance)
	{
		if (!released) return 0;
		uint256 _fractionsCount = totalSupply();
		return _fractionsCount * fractionPrice;
	}

	function vaultBalanceOf(address _from) public view returns (uint256 _vaultBalanceOf)
	{
		if (!released) return 0;
		uint256 _fractionsCount = balanceOf(_from);
		return _fractionsCount * fractionPrice;
	}

	function redeem() external payable nonReentrant
	{
		address payable _from = msg.sender;
		uint256 _value = msg.value;
		require(!released, "token already redeemed");
		uint256 _fractionsCount = balanceOf(_from);
		uint256 _redeemAmount = redeemAmountOf(_from);
		released = true;
		if (_fractionsCount > 0) _burn(_from, _fractionsCount);
		_safeTransferFrom(paymentToken, _from, _value, payable(address(this)), _redeemAmount);
		IERC721(target).safeTransfer(_from, tokenId);
		emit Redeem(_from, _fractionsCount, _redeemAmount);
		_cleanup();
	}

	function claim() external nonReentrant
	{
		address payable _from = msg.sender;
		require(released, "token not redeemed");
		uint256 _fractionsCount = balanceOf(_from);
		require(_fractionsCount > 0, "nothing to claim");
		uint256 _claimAmount = vaultBalanceOf(_from);
		_burn(_from, _fractionsCount);
		_safeTransfer(paymentToken, _from, _claimAmount);
		emit Claim(_from, _fractionsCount, _claimAmount);
		_cleanup();
	}

	function _cleanup() internal
	{
		uint256 _fractionsCount = totalSupply();
		if (_fractionsCount == 0) {
			selfdestruct(address(0));
		}
	}

	function _safeTransfer(address _token, address payable _to, uint256 _amount) internal
	{
		if (_token == address(0)) {
			_to.transfer(_amount);
		} else {
			IERC20(_token).safeTransfer(_to, _amount);
		}
	}

	function _safeTransferFrom(address _token, address payable _from, uint256 _value, address payable _to, uint256 _amount) internal
	{
		if (_token == address(0)) {
			require(_value == _amount, "invalid value");
			if (_to != address(this)) _to.transfer(_amount);
		} else {
			require(_value == 0, "invalid value");
			IERC20(_token).safeTransferFrom(_from, _to, _amount);
		}
	}

	event Redeem(address indexed _from, uint256 _fractionsCount, uint256 _redeemAmount);
	event Claim(address indexed _from, uint256 _fractionsCount, uint256 _claimAmount);
}
