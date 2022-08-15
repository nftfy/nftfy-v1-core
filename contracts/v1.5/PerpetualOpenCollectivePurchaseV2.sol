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
		listings.push(ListingInfo({
			state: State.Ended,
			seller: address(0),
			collection: address(0),
			tokenId: 0,
			listed: false,
			paymentToken: address(0),
			reservePrice: 0,
			priceMultiplier: 0,
			extra: new bytes(0),
			amount: 0,
			fractionsCount: 0,
			fractions: address(0),
			fee: 0,
			any: false
		}));
		creators.push(CreatorInfo({
			creator: address(0),
			fee: 0
		}));
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
		if (_listing.state == State.Created) {
			_listing.priceMultiplier = _priceMultiplier;
		}
		emit UpdatePriceMultiplier(_collection, _paymentToken, _priceMultiplier);
	}

	function perpetualOpen(address _collection, address _paymentToken) public returns (uint256 _listingId)
	{
		PerpetualInfo storage _perpetual = perpetuals[_collection][_paymentToken];
		ListingInfo storage _listing = listings[_perpetual.listingId];
		if (_listing.state != State.Created) {
			uint256 _priceMultiplier = _perpetual.priceMultiplier;
			if (_priceMultiplier == 0) _priceMultiplier = priceMultiplier;
			_perpetual.listingId = list(address(0), _collection, true, 0, true, fee, _paymentToken, _priceMultiplier, abi.encode(bytes32("SET_PRICE"), string("Perpetual Fractions"), string("PFRAC"), uint256(30 minutes), uint256(0)));
		}
		emit PerpetualOpen(_collection, _paymentToken, _perpetual.listingId);
		return _perpetual.listingId;
	}

	function perpetualJoin(address _collection, address _paymentToken, uint256 _amount, uint256 _maxReservePrice, bytes32 _referralId) external payable returns (uint256 _listingId)
	{
		_listingId = perpetualOpen(_collection, _paymentToken);
		join(_listingId, _amount, _maxReservePrice);
		if (_referralId != bytes32(0)) {
			emit Referral(msg.sender, _paymentToken, _amount, _referralId);
		}
		return _listingId;
	}

	function perpetualLeave(address _collection, address _paymentToken) external returns (uint256 _listingId)
	{
		_listingId = perpetualOpen(_collection, _paymentToken);
		leave(_listingId);
		return _listingId;
	}

	event UpdateDefaultPriceMultiplier(uint256 _priceMultiplier);
	event UpdatePriceMultiplier(address indexed _collection, address indexed _paymentToken, uint256 _priceMultiplier);
	event PerpetualOpen(address indexed _collection, address indexed _paymentToken, uint256 indexed _listingId);
	event Referral(address indexed _account, address indexed _paymentToken, uint256 _amount, bytes32 indexed _referralId);
}
