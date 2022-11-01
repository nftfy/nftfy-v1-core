// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

interface IAuctionFractionalizer
{
	function fractionalize(address _target, uint256 _tokenId, string memory _name, string memory _symbol, uint8 _decimals, uint256 _fractionsCount, uint256 _fractionPrice, address _paymentToken, uint256 _kickoff, uint256 _duration, uint256 _fee) external returns (address _fractions);
}
