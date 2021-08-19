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

import { SafeERC721 } from "./SafeERC721.sol";

contract AuctionFractionsImpl is ERC721Holder, ERC20, ReentrancyGuard
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
	uint256 public fee;
	address public vault;

	bool public released;
	uint256 public cutoff;
	address payable public bidder;

	string private name_;
	string private symbol_;

	constructor () ERC20("Fractions", "FRAC") public
	{
		target = address(-1); // prevents proxy code from misuse
	}

	function __name() public view /*override*/ returns (string memory _name) // rename to name() and change name() on ERC20 to virtual to be able to override on deploy
	{
		if (bytes(name_).length != 0) return name_;
		return string(abi.encodePacked(IERC721Metadata(target).safeName(), " #", tokenId.toString(), " Fractions"));
	}

	function __symbol() public view /*override*/ returns (string memory _symbol) // rename to name() and change name() on ERC20 to virtual to be able to override on deploy
	{
		if (bytes(symbol_).length != 0) return symbol_;
		return string(abi.encodePacked(IERC721Metadata(target).safeSymbol(), tokenId.toString()));
	}

	modifier onlyOwner()
	{
		require(balanceOf(msg.sender) + balanceOf(address(this)) == fractionsCount, "access denied");
		_;
	}

	modifier onlyHolder()
	{
		require(balanceOf(msg.sender) > 0, "access denied");
		_;
	}

	modifier onlyBidder()
	{
		require(msg.sender == bidder, "access denied");
		_;
	}

	modifier beforeAuction()
	{
		require(bidder == address(0), "not available");
		_;
	}

	modifier beforeOrInAuction()
	{
		require(now <= cutoff, "not available");
		_;
	}

	modifier afterAuction()
	{
		require(now > cutoff, "not available");
		_;
	}

	function initialize(address _from, address _target, uint256 _tokenId, string memory _name, string memory _symbol, uint8 _decimals, uint256 _fractionsCount, uint256 _fractionPrice, address _paymentToken, uint256 _fee, address _vault) external
	{
		require(target == address(0), "already initialized");
		require(IERC721(_target).ownerOf(_tokenId) == address(this), "missing token");
		require(_fractionsCount  > 0, "invalid count");
		uint256 _newReservePrice = _fractionsCount * _fractionPrice;
		require(_newReservePrice / _fractionsCount == _fractionPrice, "price overflow");
		target = _target;
		tokenId = _tokenId;
		fractionsCount = _fractionsCount;
		fractionPrice = _fractionPrice;
		paymentToken = _paymentToken;
		fee = _fee;
		vault = _vault;
		released = false;
		cutoff = uint256(-1);
		bidder = address(0);
		name_ = _name;
		symbol_ = _symbol;
		_setupDecimals(_decimals);
		uint256 _feeFractionsCount = _fractionsCount.mul(_fee) / 1e18;
		uint256 _netFractionsCount = _fractionsCount - _feeFractionsCount;
		_mint(_from, _netFractionsCount);
		_mint(address(this), _feeFractionsCount);
	}

	function reservePrice() external view returns (uint256 _reservePrice)
	{
		return fractionsCount * fractionPrice;
	}

	function vaultBalance() external view returns (uint256 _vaultBalance)
	{
		if (now <= cutoff) return 0;
		uint256 _fractionsCount = totalSupply();
		return _fractionsCount * fractionPrice;
	}

	function vaultBalanceOf(address _from) external view returns (uint256 _vaultBalanceOf)
	{
		if (now <= cutoff) return 0;
		uint256 _fractionsCount = balanceOf(_from);
		return _fractionsCount * fractionPrice;
	}

	function updatePrice(uint256 _newFractionPrice) external onlyOwner beforeAuction
	{
		address _from = msg.sender;
		uint256 _newReservePrice = fractionsCount * _newFractionPrice;
		require(_newReservePrice / fractionsCount == _newFractionPrice, "price overflow");
		uint256 _oldFractionPrice = fractionPrice;
		fractionPrice = _newFractionPrice;
		emit UpdatePrice(_from, _oldFractionPrice, _newFractionPrice);
	}

	function cancel() external nonReentrant onlyOwner beforeAuction
	{
		address _from = msg.sender;
		released = true;
		_burn(_from, balanceOf(_from));
		_burn(address(this), balanceOf(address(this)));
		IERC721(target).safeTransfer(_from, tokenId);
		emit Cancel(_from);
		_cleanup();
	}

	function bid(uint256 _newFractionPrice) external payable nonReentrant beforeOrInAuction
	{
		address payable _from = msg.sender;
		uint256 _value = msg.value;
		uint256 _newReservePrice = fractionsCount * _newFractionPrice;
		require(_newReservePrice / fractionsCount == _newFractionPrice, "price overflow");
		uint256 _oldFractionPrice = fractionPrice;
		if (bidder == address(0)) {
			require(_newFractionPrice >= _oldFractionPrice, "below minimum");
			_transfer(address(this), vault, balanceOf(address(this)));
			cutoff = now + 24 hours;
		} else {
			uint256 _oldReservePrice = fractionsCount * _oldFractionPrice;
			require(_newReservePrice / 11 >= _oldReservePrice / 10, "below minimum"); // 10% increase
			_safeTransfer(paymentToken, bidder, _oldReservePrice);
			if (cutoff < now + 15 minutes) cutoff = now + 15 minutes;
		}
		bidder = _from;
		fractionPrice = _newFractionPrice;
		_safeTransferFrom(paymentToken, _from, _value, payable(address(this)), _newReservePrice);
		emit Bid(_from, _oldFractionPrice, _newFractionPrice);
	}

	function redeem() external nonReentrant onlyBidder afterAuction
	{
		address _from = msg.sender;
		require(!released, "missing token");
		released = true;
		IERC721(target).safeTransfer(_from, tokenId);
		emit Redeem(_from);
		_cleanup();
	}

	function claim() external nonReentrant onlyHolder afterAuction
	{
		address payable _from = msg.sender;
		uint256 _fractionsCount = balanceOf(_from);
		uint256 _claimAmount = _fractionsCount * fractionPrice;
		_burn(_from, _fractionsCount);
		_safeTransfer(paymentToken, _from, _claimAmount);
		emit Claim(_from, _fractionsCount, _claimAmount);
		_cleanup();
	}

	function _cleanup() internal
	{
		uint256 _fractionsCount = totalSupply();
		if (released && _fractionsCount == 0) {
			selfdestruct(address(0));
		}
	}

	function _balanceOf(address _token) internal view returns (uint256 _balance)
	{
		if (_token == address(0)) {
			return address(this).balance;
		} else {
			return IERC20(_token).balanceOf(address(this));
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

	event UpdatePrice(address indexed _from, uint256 _oldFractionPrice, uint256 _newFractionPrice);
	event Cancel(address indexed _from);
	event Bid(address indexed _from, uint256 _oldFractionPrice, uint256 _newFractionPrice);
	event Redeem(address indexed _from);
	event Claim(address indexed _from, uint256 _fractionsCount, uint256 _claimAmount);
}
