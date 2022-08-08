// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

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
