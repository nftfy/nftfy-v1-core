// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

interface FlashAcquireCallee
{
	function flashAcquireCall(address _sender, uint256 _listingId, bytes calldata _data) external;
}
