// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { OpenCollectivePurchaseV2 } from "./OpenCollectivePurchaseV2.sol";

contract PerpetualOpenCollectivePurchaseV2 is OpenCollectivePurchaseV2
{
	struct PerpetualInfo {
		uint256 listingId;
		uint256 priceMultiplier;
	}

	uint256 constant DEFAULT_PRICE_MULTIPLIER = 140; // 140%

	uint256 public priceMultiplier = DEFAULT_PRICE_MULTIPLIER;

	mapping (address => mapping (address => PerpetualInfo)) public perpetuals;

	constructor (uint256 _fee, address payable _vault) public
		OpenCollectivePurchaseV2(_fee, _vault)
	{
		// must be called after fractionalizer config
		// list(address(0), false, 0, false, fee, address(0), 100, abi.encode(bytes32("SET_PRICE"), "Perpetual Fractions", "PFRAC", 30 minutes, 0e18));
	}

	function _defaultCreator() internal view override returns (address payable _creator)
	{
		return payable(0);
	}

	function setDefaultPriceMultiplier(uint256 _priceMultiplier) external onlyOwner
	{
		require(0 < _priceMultiplier && _priceMultiplier <= 10000, "invalid multiplier"); // from 1% up to 100x
		priceMultiplier = _priceMultiplier;
		emit UpdateDefaultPriceMultiplier(_priceMultiplier);
	}

	function setPriceMultiplier(address _collection, address _paymentToken, uint256 _priceMultiplier) external onlyOwner
	{
		require(0 < _priceMultiplier && _priceMultiplier <= 10000, "invalid multiplier"); // from 1% up to 100x
		PerpetualInfo storage _perpetual = perpetuals[_collection][_paymentToken];
		_perpetual.priceMultiplier = _priceMultiplier;
		ListingInfo storage _listing = listings[_perpetual.listingId];
		if (_perpetual.listingId != 0 && _listing.state == State.Created) {
			_listing.priceMultiplier = _priceMultiplier;
		}
		emit UpdatePriceMultiplier(_collection, _paymentToken, _priceMultiplier);
	}

	function perpetualJoin(address _collection, address _paymentToken, uint256 _amount, uint256 _maxReservePrice, bytes32 _referralId) external payable
	{
		PerpetualInfo storage _perpetual = perpetuals[_collection][_paymentToken];
		ListingInfo storage _listing = listings[_perpetual.listingId];
		if (_perpetual.listingId == 0 || _listing.state != State.Created) {
			uint256 _priceMultiplier = _perpetual.priceMultiplier;
			if (_priceMultiplier == 0) _priceMultiplier = priceMultiplier;
			_perpetual.listingId = list(_collection, true, 0, true, fee, _paymentToken, _priceMultiplier, abi.encode(bytes32("SET_PRICE"), string("Perpetual Fractions"), string("PFRAC"), uint256(30 minutes), uint256(0)));
		}
		join(_perpetual.listingId, _amount, _maxReservePrice);
		emit Referral(msg.sender, _paymentToken, _amount, _referralId);
	}

	function perpetualLeave(address _collection, address _paymentToken) external
	{
		PerpetualInfo storage _perpetual = perpetuals[_collection][_paymentToken];
		require(_perpetual.listingId != 0, "invalid listing");
		leave(_perpetual.listingId);
	}

	event UpdateDefaultPriceMultiplier(uint256 _priceMultiplier);
	event UpdatePriceMultiplier(address indexed _collection, address indexed _paymentToken, uint256 _priceMultiplier);
	event Referral(address indexed _account, address indexed _paymentToken, uint256 _amount, bytes32 indexed _referralId);
}
