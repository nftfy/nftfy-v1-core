// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface LegacyFractionalizer
{
	function fractionalize(address _target, uint256 _tokenId, string memory _name, string memory _symbol, uint8 _decimals, uint256 _fractionsCount, uint256 _fractionPrice, address _paymentToken) external;
}

library LibCreate
{
	function computeAddress(address _account, uint256 _nonce) internal pure returns (address _address)
	{
		bytes memory _data;
		if (_nonce == 0x00) {
			_data = abi.encodePacked(byte(0xd6), byte(0x94), _account, byte(0x80));
		}
		else
		if (_nonce <= 0x7f) {
			_data = abi.encodePacked(byte(0xd6), byte(0x94), _account, uint8(_nonce));
		}
		else
		if (_nonce <= 0xff) {
			_data = abi.encodePacked(byte(0xd7), byte(0x94), _account, byte(0x81), uint8(_nonce));
		}
		else
		if (_nonce <= 0xffff) {
			_data = abi.encodePacked(byte(0xd8), byte(0x94), _account, byte(0x82), uint16(_nonce));
		}
		else
		if (_nonce <= 0xffffff) {
			_data = abi.encodePacked(byte(0xd9), byte(0x94), _account, byte(0x83), uint24(_nonce));
		}
		else {
			_data = abi.encodePacked(byte(0xda), byte(0x94), _account, byte(0x84), uint32(_nonce));
		}
		return address(uint256(keccak256(_data)));
	}
}

contract CompatibilityFractionalizer is ERC721Holder, Ownable, ReentrancyGuard
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

	function fractionalize(address _target, uint256 _tokenId, string memory _name, string memory _symbol, uint8 _decimals, uint256 _fractionsCount, uint256 _fractionPrice, address _paymentToken) external nonReentrant returns (address _fractions)
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
