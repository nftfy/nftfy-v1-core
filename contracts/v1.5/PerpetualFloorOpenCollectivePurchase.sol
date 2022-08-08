// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { OpenCollectivePurchase } from "./OpenCollectivePurchase.sol";

contract PerpetualFloorCollectivePurchase is OpenCollectivePurchase
{
	mapping (address => mapping (address => uint256)) perpetuals;

	constructor (uint256 _fee, address payable _vault) public
		OpenCollectivePurchase(_fee, _vault)
	{
		list(address(0), false, 0, false, fee, address(0), 0, new bytes(0));
	}

	function perpetualJoin(address _collection, address _paymentToken, uint256 _amount, uint256 _maxReservePrice, bytes32 _referralId) external payable
	{
		uint256 _listingId = perpetuals[_collection][_paymentToken];
		ListingInfo storage _listing = listings[_listingId];
		if (_listingId == 0 || _listing.state != State.Created) {
			_listingId = list(_collection, true, 0, true, fee, _paymentToken, 40, _listing.extra);
		}
		join(_listingId, _amount, _maxReservePrice);
		emit Referral(msg.sender, _paymentToken, _amount, _referralId);
	}

	event Referral(address indexed _account, address indexed _paymentToken, uint256 _amount, bytes32 indexed _referralId);
}
