// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library ConvertLib
{
	function convert(uint _amount, uint _conversionRate) public pure returns (uint256 _convertedAmount)
	{
		return _amount * _conversionRate;
	}
}
