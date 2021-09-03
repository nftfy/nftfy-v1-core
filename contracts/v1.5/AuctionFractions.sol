// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

contract AuctionFractions
{
	fallback () external payable
	{
		assembly {
			calldatacopy(0, 0, calldatasize())
			let result := delegatecall(gas(), 0x8fCD445E86ecF0C79355C5dF257A4E5A32C73AfE, 0, calldatasize(), 0, 0) // replace 2nd parameter by AuctionFractionsImpl address on deploy
			returndatacopy(0, 0, returndatasize())
			switch result
			case 0 { revert(0, returndatasize()) }
			default { return(0, returndatasize()) }
		}
	}
}
