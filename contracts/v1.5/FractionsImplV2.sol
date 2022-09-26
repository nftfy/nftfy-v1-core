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
import { LibSeaport } from "./LibSeaport.sol";

contract FractionsImplV2 is ERC721Holder, ERC20, ReentrancyGuard
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

	function initialize(address _from, address _target, uint256 _tokenId, string memory _name, string memory _symbol, uint8 _decimals, uint256 _fractionsCount, uint256 _fractionPrice, address _paymentToken) external
	{
		require(target == address(0), "already initialized");
		require(IERC721(_target).ownerOf(_tokenId) == address(this), "token not staked");
		require(_fractionsCount > 0, "invalid fraction count");
		require(_fractionsCount * _fractionPrice / _fractionsCount == _fractionPrice, "invalid fraction price");
		require(_paymentToken != address(this), "invalid token");
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

	function status() external view returns (string memory _status)
	{
		return released ? "SOLD" : "OFFER";
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

	function _balanceOf(address _token, address _account) internal view returns (uint256 _balance)
	{
		if (_token == address(0)) {
			return _account.balance;
		} else {
			return IERC20(_token).balanceOf(_account);
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

	address constant OPENSEA_SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

	bytes4 constant MAGICVALUE = 0x1626ba7e;

	bytes32 public openseaOrderHash;

	function listOnOpensea() external nonReentrant
	{
		require(!released, "token already redeemed");
		require(openseaOrderHash == bytes32(0), "unavailable");
		IERC721(target).approve(OPENSEA_SEAPORT, tokenId);
		openseaOrderHash = LibSeaport._hash(address(this), target, tokenId, reservePrice(), paymentToken, block.timestamp, uint256(-1), 0);
	}

	function checkExternalReedeem() external nonReentrant
	{
		require(!released, "token already redeemed");
		uint256 _reservePrice = reservePrice();
		require(IERC721(target).ownerOf(tokenId) != address(this) && _balanceOf(paymentToken, address(this)) >= _reservePrice, "token not redeemed");
		released = true;
		emit Redeem(OPENSEA_SEAPORT, 0, _reservePrice);
		_cleanup();
	}

	function isValidSignature(bytes32 _hash, bytes calldata /*_signature*/) external view returns (bytes4 _magicValue)
	{
		require(!released, "token already redeemed");
		require(_hash == openseaOrderHash, "invalid hash");
		return MAGICVALUE;
	}
}
