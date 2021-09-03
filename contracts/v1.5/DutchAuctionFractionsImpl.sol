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

import { IFractions } from "./IFractions.sol";
import { SafeERC721 } from "./SafeERC721.sol";

contract DutchAuctionFractionsImpl is IFractions, ERC721Holder, ERC20, ReentrancyGuard
{
	using SafeERC20 for IERC20;
	using SafeERC721 for IERC721;
	using SafeERC721 for IERC721Metadata;
	using Strings for uint256;

	address public override target;
	uint256 public override tokenId;
	uint256 public override fractionsCount;
	uint256 public fractionPrice;
	address public paymentToken;
	uint256 public kickoff;
	uint256 public duration;
	uint256 public fee;
	address public vault;

	bool public released;

	uint256 private lockedFractions_;
	uint256 private lockedAmount_;

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
		require(isOwner(msg.sender), "access denied");
		_;
	}

	modifier onlyHolder()
	{
		require(balanceOf(msg.sender) > 0, "access denied");
		_;
	}

	modifier inAuction()
	{
		require(now >= kickoff && !released, "not available");
		_;
	}

	modifier afterAuction()
	{
		require(released, "not available");
		_;
	}

	function initialize(address _from, address _target, uint256 _tokenId, string memory _name, string memory _symbol, uint8 _decimals, uint256 _fractionsCount, uint256 _fractionPrice, address _paymentToken, uint256 _kickoff, uint256 _duration, uint256 _fee, address _vault) external
	{
		require(target == address(0), "already initialized");
		require(IERC721(_target).ownerOf(_tokenId) == address(this), "missing token");
		require(_fractionsCount > 0, "invalid count");
		require(_fractionsCount * _fractionPrice / _fractionsCount == _fractionPrice, "price overflow");
		require(_paymentToken != address(this), "invalid token");
		require(_kickoff <= now + 731 days, "invalid kickoff");
		require(30 minutes <= _duration && _duration <= 731 days, "invalid duration");
		require(_fee <= 1e18, "invalid fee");
		require(_vault != address(0), "invalid address");
		target = _target;
		tokenId = _tokenId;
		fractionsCount = _fractionsCount;
		fractionPrice = _fractionPrice;
		paymentToken = _paymentToken;
		kickoff = _kickoff;
		duration = _duration;
		fee = _fee;
		vault = _vault;
		released = false;
		name_ = _name;
		symbol_ = _symbol;
		_setupDecimals(_decimals);
		uint256 _feeFractionsCount = _fractionsCount.mul(_fee) / 1e18;
		uint256 _netFractionsCount = _fractionsCount - _feeFractionsCount;
		_mint(_from, _netFractionsCount);
		_mint(address(this), _feeFractionsCount);
		lockedFractions_ = _feeFractionsCount;
		lockedAmount_ = 0;
	}

	function status() external view returns (string memory _status)
	{
		return released ? "SOLD" : now >= kickoff ? "AUCTION" : "PAUSE";
	}

	function isOwner(address _from) public view returns (bool _soleOwner)
	{
		return !released && balanceOf(_from) + lockedFractions_ == fractionsCount;
	}

	function reservePrice() external view returns (uint256 _reservePrice)
	{
		return fractionsCount * fractionPrice;
	}

	function bidFractionPrice() external view inAuction returns (uint256 _bidFractionPrice)
	{
		uint256 _ellapsed = now - kickoff;
		if (_ellapsed >= duration) return fractionPrice;
		return fractionPrice.mul(duration) / _ellapsed;
	}

	function bidAmountOf(address _from, uint256 _newFractionPrice) external view inAuction returns (uint256 _bidAmount)
	{
		uint256 _fractionsCount = balanceOf(_from);
		return (fractionsCount - _fractionsCount) * _newFractionPrice;
	}

	function vaultBalance() external view returns (uint256 _vaultBalance)
	{
		if (!released) return 0;
		uint256 _fractionsCount = totalSupply();
		return _fractionsCount * fractionPrice;
	}

	function vaultBalanceOf(address _from) external view returns (uint256 _vaultBalanceOf)
	{
		if (!released) return 0;
		uint256 _fractionsCount = balanceOf(_from);
		return _fractionsCount * fractionPrice;
	}

	function updatePrice(uint256 _newFractionPrice) external onlyOwner
	{
		address _from = msg.sender;
		require(fractionsCount * _newFractionPrice / fractionsCount == _newFractionPrice, "price overflow");
		uint256 _oldFractionPrice = fractionPrice;
		fractionPrice = _newFractionPrice;
		emit UpdatePrice(_from, _oldFractionPrice, _newFractionPrice);
	}

	function cancel() external nonReentrant onlyOwner
	{
		address _from = msg.sender;
		released = true;
		_burn(_from, balanceOf(_from));
		_burn(address(this), lockedFractions_);
		IERC721(target).safeTransfer(_from, tokenId);
		emit Cancel(_from);
		_cleanup();
	}

	function redeem(uint256 _newFractionPrice) external payable nonReentrant inAuction
	{
		address payable _from = msg.sender;
		uint256 _value = msg.value;
		uint256 _ellapsed = now - kickoff;
		uint256 _bidFractionPrice = _ellapsed >= duration ? fractionPrice : fractionPrice.mul(duration) / _ellapsed;
		require(_newFractionPrice >= _bidFractionPrice, "invalid price");
		_transfer(address(this), vault, lockedFractions_);
		uint256 _fractionsCount = balanceOf(_from);
		uint256 _bidAmount = (fractionsCount - _fractionsCount) * _newFractionPrice;
		released = true;
		fractionPrice = _newFractionPrice;
		if (_fractionsCount > 0) _burn(_from, _fractionsCount);
		_safeTransferFrom(paymentToken, _from, _value, payable(address(this)), _bidAmount);
		IERC721(target).safeTransfer(_from, tokenId);
		emit Redeem(_from, _newFractionPrice, _fractionsCount, _bidAmount);
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

	event UpdatePrice(address indexed _from, uint256 _oldFractionPrice, uint256 _newFractionPrice);
	event Cancel(address indexed _from);
	event Redeem(address indexed _from, uint256 _newFractionPrice, uint256 _fractionsCount, uint256 _bidAmount);
	event Claim(address indexed _from, uint256 _fractionsCount, uint256 _claimAmount);
}
