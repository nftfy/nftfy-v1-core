// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { OpenCollectivePurchaseV2 } from "./OpenCollectivePurchaseV2.sol";

contract PerpetualOpenCollectivePurchaseV2 is OpenCollectivePurchaseV2
{
	struct PerpetualInfo {
		uint256 listingId;
		uint256 priceMultiplier;
		bytes extra;
		uint256 fee;
	}

	uint256 constant DEFAULT_PRICE_MULTIPLIER = 140; // 140%
	bytes constant DEFAULT_EXTRA = abi.encode(bytes32("SET_PRICE_SEAPORT"), string("Perpetual Fractions"), string("PFRAC"), uint256(30 minutes), uint256(0));

	uint256 public priceMultiplier = DEFAULT_PRICE_MULTIPLIER;

	bytes public extra = DEFAULT_EXTRA;

	mapping (address => mapping (address => mapping (address => PerpetualInfo))) public perpetuals;

	constructor (uint256 _fee, address payable _vault) public
		OpenCollectivePurchaseV2(_fee, _vault)
	{
		// reserves index 0
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

	function setDefaultExtra(bytes memory _extra) external onlyOwner
	{
		_validate(_extra);
		extra = _extra;
		emit UpdateDefaultExtra(_extra);
	}

	function setPriceMultiplier(address payable _creator, address _collection, address _paymentToken, uint256 _priceMultiplier) external
	{
		require(msg.sender == _creator || _creator == address(0) && msg.sender == owner(), "access denied");
		require(0 < _priceMultiplier && _priceMultiplier <= 10000, "invalid multiplier"); // from 1% up to 100x
		PerpetualInfo storage _perpetual = perpetuals[_creator][_collection][_paymentToken];
		require(_perpetual.listingId != 0, "invalid perpetual");
		_perpetual.priceMultiplier = _priceMultiplier;
		ListingInfo storage _listing = listings[_perpetual.listingId];
		if (_listing.state == State.Created) {
			_listing.priceMultiplier = _priceMultiplier;
		}
		emit UpdatePriceMultiplierPerpetual(_creator, _collection, _paymentToken, _priceMultiplier);
	}

	function setExtra(address payable _creator, address _collection, address _paymentToken, bytes memory _extra) external
	{
		require(msg.sender == _creator || _creator == address(0) && msg.sender == owner(), "access denied");
		_validate(_extra);
		PerpetualInfo storage _perpetual = perpetuals[_creator][_collection][_paymentToken];
		require(_perpetual.listingId != 0, "invalid perpetual");
		_perpetual.extra = _extra;
		ListingInfo storage _listing = listings[_perpetual.listingId];
		if (_listing.state == State.Created) {
			_listing.extra = _extra;
		}
		emit UpdateExtraPerpetual(_creator, _collection, _paymentToken, _extra);
	}

	function setCreatorFee(address _collection, address _paymentToken, uint256 _fee) external
	{
		PerpetualInfo storage _perpetual = perpetuals[msg.sender][_collection][_paymentToken];
		require(fee + _fee <= 100e16, "invalid fee");
		require(_perpetual.listingId != 0, "invalid perpetual");
		_perpetual.fee = _fee;
		ListingInfo storage _listing = listings[_perpetual.listingId];
		if (_listing.state == State.Created) {
			require(_listing.fee + _fee <= 100e16, "invalid fee");
			creators[_perpetual.listingId].fee = _fee;
		}
		emit UpdateCreatorFeePerpetual(msg.sender, _collection, _paymentToken, _fee);
	}

	function perpetualCreate(address _collection, uint256 _fee, address _paymentToken, uint256 _priceMultiplier, bytes memory _extra) external returns (uint256 _listingId)
	{
		PerpetualInfo storage _perpetual = perpetuals[msg.sender][_collection][_paymentToken];
		require(_perpetual.listingId == 0, "invalid perpetual");
		_perpetual.listingId = list(msg.sender, _collection, true, 0, false, _fee, _paymentToken, _priceMultiplier, _extra);
		_perpetual.priceMultiplier = priceMultiplier;
		_perpetual.extra = extra;
		_perpetual.fee = _fee;
		emit PerpetualCreate(msg.sender, _collection, _paymentToken, _perpetual.listingId);
		return _perpetual.listingId;
	}

	function perpetualOpen(address payable _creator, address _collection, address _paymentToken) public returns (uint256 _listingId)
	{
		PerpetualInfo storage _perpetual = perpetuals[_creator][_collection][_paymentToken];
		if (_perpetual.listingId == 0) {
			require(_creator == address(0), "invalid creator");
			_perpetual.listingId = list(address(0), _collection, true, 0, true, 0, _paymentToken, priceMultiplier, extra);
			_perpetual.priceMultiplier = priceMultiplier;
			_perpetual.extra = extra;
			_perpetual.fee = 0;
		} else {
			ListingInfo storage _listing = listings[_perpetual.listingId];
			if (_listing.state == State.Created) return _perpetual.listingId;
			_perpetual.listingId = list(_creator, _collection, true, 0, _listing.listed, _perpetual.fee, _paymentToken, _perpetual.priceMultiplier, _perpetual.extra);
		}
		emit PerpetualOpen(_creator, _collection, _paymentToken, _perpetual.listingId);
		return _perpetual.listingId;
	}

	function perpetualJoin(address payable _creator, address _collection, address _paymentToken, uint256 _amount, uint256 _maxReservePrice, bytes32 _referralId) external payable returns (uint256 _listingId)
	{
		_listingId = perpetualOpen(_creator, _collection, _paymentToken);
		join(_listingId, _amount, _maxReservePrice);
		if (_referralId != bytes32(0)) {
			emit Referral(msg.sender, _paymentToken, _amount, _referralId);
		}
		return _listingId;
	}

	function perpetualLeave(address payable _creator, address _collection, address _paymentToken) external returns (uint256 _listingId)
	{
		_listingId = perpetualOpen(_creator, _collection, _paymentToken);
		leave(_listingId);
		return _listingId;
	}

	event UpdateDefaultPriceMultiplier(uint256 _priceMultiplier);
	event UpdateDefaultExtra(bytes _extra);
	event UpdatePriceMultiplierPerpetual(address indexed _creator, address indexed _collection, address indexed _paymentToken, uint256 _priceMultiplier);
	event UpdateExtraPerpetual(address indexed _creator, address indexed _collection, address indexed _paymentToken, bytes _extra);
	event UpdateCreatorFeePerpetual(address indexed _creator, address indexed _collection, address indexed _paymentToken, uint256 _fee);
	event PerpetualCreate(address indexed _creator, address indexed _collection, address _paymentToken, uint256 indexed _listingId);
	event PerpetualOpen(address indexed _creator, address indexed _collection, address _paymentToken, uint256 indexed _listingId);
	event Referral(address indexed _account, address indexed _paymentToken, uint256 _amount, bytes32 indexed _referralId);
}
