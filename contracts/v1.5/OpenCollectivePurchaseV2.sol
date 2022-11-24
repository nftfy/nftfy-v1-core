// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { FlashAcquireCallee } from "./FlashAcquireCallee.sol";
import { IAuctionFractionalizer } from "./IAuctionFractionalizer.sol";
import { SafeERC721 } from "./SafeERC721.sol";

contract OpenCollectivePurchaseV2 is ERC721Holder, Ownable, ReentrancyGuard
{
	using SafeERC20 for IERC20;
	using SafeERC721 for IERC721;

	enum State { Created, Acquired, Ended }

	struct BuyerInfo {
		uint256 amount;
	}

	struct ListingInfo {
		State state;
		address payable seller;
		address collection;
		uint256 tokenId;
		bool listed;
		address paymentToken;
		uint256 reservePrice;
		uint256 priceMultiplier;
		bytes extra;
		uint256 amount;
		uint256 fractionsCount;
		address fractions;
		uint256 fee;
		bool any;
		mapping (address => BuyerInfo) buyers;
	}

	struct CreatorInfo {
		address payable creator;
		uint256 fee;
	}

	uint8 constant public FRACTIONS_DECIMALS = 6;
	uint256 constant public FRACTIONS_COUNT = 100000e6;

	uint256 public fee;
	address payable public immutable vault;
	mapping (bytes32 => address) public fractionalizers;

	mapping (address => uint256) private balances;
	mapping (address => mapping (uint256 => bool)) private items;
	ListingInfo[] public listings;
	CreatorInfo[] public creators;

	modifier inState(uint256 _listingId, State _state)
	{
		ListingInfo storage _listing = listings[_listingId];
		require(_state == _listing.state, "not available");
		_;
	}

	modifier onlyCreator(uint256 _listingId)
	{
		CreatorInfo storage _creator = creators[_listingId];
		require(msg.sender == _creator.creator, "not available");
		_;
	}

	constructor (uint256 _fee, address payable _vault) public
	{
		require(_fee <= 100e16, "invalid fee");
		require(_vault != address(0), "invalid address");
		fee = _fee;
		vault = _vault;
	}

	function listingCount() external view returns (uint256 _count)
	{
		return listings.length;
	}

	function buyers(uint256 _listingId, address _buyer) external view returns (uint256 _amount)
	{
		ListingInfo storage _listing = listings[_listingId];
		BuyerInfo storage _info = _listing.buyers[_buyer];
		return _info.amount;
	}

	function status(uint256 _listingId) external view returns (string memory _status)
	{
		ListingInfo storage _listing = listings[_listingId];
		if (_listing.state == State.Created) return "CREATED";
		if (_listing.state == State.Acquired) return "ACQUIRED";
		return "ENDED";
	}

	function buyerFractionsCount(uint256 _listingId, address _buyer) external view inState(_listingId, State.Ended) returns (uint256 _fractionsCount)
	{
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.buyers[_buyer].amount;
		_fractionsCount = (_amount * _listing.fractionsCount) / _listing.reservePrice;
		return _fractionsCount;
	}

	function sellerPayout(uint256 _listingId) external view returns (uint256 _netAmount, uint256 _feeAmount, uint256 _creatorFeeAmount)
	{
		ListingInfo storage _listing = listings[_listingId];
		CreatorInfo storage _creator = creators[_listingId];
		uint256 _amount = _listing.amount;
		_feeAmount = (_amount * _listing.fee) / 1e18;
		_creatorFeeAmount = (_amount * _creator.fee) / 1e18;
		_netAmount = _amount - (_feeAmount + _creatorFeeAmount);
	}

	function setFee(uint256 _fee) external onlyOwner
	{
		require(_fee <= 100e16, "invalid fee");
		fee = _fee;
		emit UpdateFee(_fee);
	}

	function setCreatorFee(uint256 _listingId, uint256 _fee) external onlyCreator(_listingId) inState(_listingId, State.Created)
	{
		ListingInfo storage _listing = listings[_listingId];
		CreatorInfo storage _creator = creators[_listingId];
		require(_listing.fee + _fee <= 100e16, "invalid fee");
		_creator.fee = _fee;
		emit UpdateCreatorFee(_listingId, _fee);
	}

	function addFractionalizer(bytes32 _type, address _fractionalizer) external onlyOwner
	{
		require(fractionalizers[_type] == address(0), "already defined");
		fractionalizers[_type] = _fractionalizer;
		emit AddFractionalizer(_type, _fractionalizer);
	}

	function list(address payable _creator, address _collection, bool any, uint256 _tokenId, bool _listed, uint256 _fee, address _paymentToken, uint256 _priceMultiplier, bytes memory _extra) public nonReentrant returns (uint256 _listingId)
	{
		if (any) {
			require(_tokenId == 0, "invalid tokenId");
		}
		require(fee + _fee <= 100e16, "invalid fee");
		require(0 < _priceMultiplier && _priceMultiplier <= 10000, "invalid multiplier"); // from 1% up to 100x
		_validate(_extra);
		_listingId = listings.length;
		listings.push(ListingInfo({
			state: State.Created,
			seller: address(0),
			collection: _collection,
			tokenId: _tokenId,
			listed: _listed,
			paymentToken: _paymentToken,
			reservePrice: 0,
			priceMultiplier: _priceMultiplier,
			extra: _extra,
			amount: 0,
			fractionsCount: 0,
			fractions: address(0),
			fee: fee,
			any: any
		}));
		creators.push(CreatorInfo({
			creator: _creator,
			fee: _fee
		}));
		emit Listed(_listingId, _creator);
		return _listingId;
	}

	function join(uint256 _listingId, uint256 _amount, uint256 _maxReservePrice) public payable nonReentrant inState(_listingId, State.Created)
	{
		address payable _buyer = msg.sender;
		uint256 _value = msg.value;
		ListingInfo storage _listing = listings[_listingId];
		require(_listing.reservePrice <= _maxReservePrice, "price slippage");
		_safeTransferFrom(_listing.paymentToken, _buyer, _value, payable(address(this)), _amount);
		balances[_listing.paymentToken] += _amount;
		_listing.amount += _amount;
		_listing.buyers[_buyer].amount += _amount;
		_listing.reservePrice = _listing.amount;
		emit Join(_listingId, _buyer, _amount);
	}

	function leave(uint256 _listingId) public nonReentrant inState(_listingId, State.Created)
	{
		address payable _buyer = msg.sender;
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.buyers[_buyer].amount;
		require(_amount > 0, "insufficient balance");
		_listing.buyers[_buyer].amount = 0;
		_listing.amount -= _amount;
		_listing.reservePrice = _listing.amount;
		balances[_listing.paymentToken] -= _amount;
		_safeTransfer(_listing.paymentToken, _buyer, _amount);
		emit Leave(_listingId, _buyer, _amount);
	}

	function acquire(uint256 _listingId, uint256 _tokenId, uint256 _minReservePrice) public nonReentrant inState(_listingId, State.Created)
	{
		address payable _seller = msg.sender;
		ListingInfo storage _listing = listings[_listingId];
		require(_tokenId == _listing.tokenId || _listing.any, "invalid tokenId");
		require(_listing.reservePrice >= _minReservePrice, "price slippage");
		IERC721(_listing.collection).transferFrom(_seller, address(this), _tokenId);
		items[_listing.collection][_listing.tokenId] = true;
		_listing.state = State.Acquired;
		_listing.tokenId = _tokenId;
		_listing.seller = _seller;
		emit Acquired(_listingId);
	}

	function flashAcquire(uint256 _listingId, uint256 _minReservePrice, address payable _to, bytes calldata _data) external inState(_listingId, State.Created)
	{
		ListingInfo storage _listing = listings[_listingId];
		require(_listing.reservePrice >= _minReservePrice, "price slippage");
		_listing.state = State.Ended;
		_listing.seller = _to;
		payout(_listingId);
		_listing.state = State.Created;
		_listing.seller = address(0);
		FlashAcquireCallee(_to).flashAcquireCall(msg.sender, _listingId, _data);
		require(_listing.state == State.Acquired, "not acquired");
		require(_listing.seller == _to, "unexpected seller");
	}

	function relist(uint256 _listingId) public nonReentrant inState(_listingId, State.Acquired)
	{
		ListingInfo storage _listing = listings[_listingId];
		uint256 _fractionPrice = (_listing.reservePrice + (FRACTIONS_COUNT - 1)) / FRACTIONS_COUNT;
		uint256 _relistFractionPrice = (_listing.priceMultiplier * _fractionPrice + 99) / 100;
		_listing.state = State.Ended;
		_listing.fractions = _fractionalize(_listingId, _relistFractionPrice);
		_listing.fractionsCount = _balanceOf(_listing.fractions);
		items[_listing.collection][_listing.tokenId] = false;
		balances[_listing.fractions] = _listing.fractionsCount;
		emit Relisted(_listingId);
	}

	function payout(uint256 _listingId) public nonReentrant inState(_listingId, State.Ended)
	{
		ListingInfo storage _listing = listings[_listingId];
		CreatorInfo storage _creator = creators[_listingId];
		uint256 _amount = _listing.amount;
		require(_amount > 0, "insufficient balance");
		uint256 _feeAmount = (_amount * _listing.fee) / 1e18;
		uint256 _creatorFeeAmount = (_amount * _creator.fee) / 1e18;
		uint256 _netAmount = _amount - (_feeAmount + _creatorFeeAmount);
		_listing.amount = 0;
		balances[_listing.paymentToken] -= _amount;
		_safeTransfer(_listing.paymentToken, _creator.creator, _creatorFeeAmount);
		_safeTransfer(_listing.paymentToken, vault, _feeAmount);
		_safeTransfer(_listing.paymentToken, _listing.seller, _netAmount);
		emit Payout(_listingId, _listing.seller, _netAmount, _feeAmount, _creatorFeeAmount);
	}

	function claim(uint256 _listingId, address payable _buyer) public nonReentrant inState(_listingId, State.Ended)
	{
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.buyers[_buyer].amount;
		require(_amount > 0, "insufficient balance");
		uint256 _fractionsCount = (_amount * _listing.fractionsCount) / _listing.reservePrice;
		_listing.buyers[_buyer].amount = 0;
		balances[_listing.fractions] -= _fractionsCount;
		_safeTransfer(_listing.fractions, _buyer, _fractionsCount);
		emit Claim(_listingId, _buyer, _amount, _fractionsCount);
	}

	function relistPayoutAndClaim(uint256 _listingId, address payable[] calldata _buyers) external
	{
		ListingInfo storage _listing = listings[_listingId];
		if (_listing.state != State.Ended) {
			relist(_listingId);
		}
		if (_listing.amount > 0) {
			payout(_listingId);
		}
		for (uint256 _i = 0; _i < _buyers.length; _i++) {
			address payable _buyer = _buyers[_i];
			if (_listing.buyers[_buyer].amount > 0) {
				claim(_listingId, _buyer);
			}
		}
	}

	function recoverLostFunds(address _token, address payable _to) external onlyOwner nonReentrant
	{
		uint256 _balance = balances[_token];
		uint256 _current = _balanceOf(_token);
		if (_current > _balance) {
			uint256 _excess = _current - _balance;
			_safeTransfer(_token, _to, _excess);
		}
	}
/*
	function recoverLostItem(address _collection, uint256 _tokenId, address _to) external onlyOwner nonReentrant
	{
		if (items[_collection][_tokenId]) return;
		IERC721(_collection).safeTransfer(_to, _tokenId);
	}
*/
	function _validate(bytes memory _extra) internal view
	{
		(bytes32 _type,,, uint256 _duration, uint256 _fee) = abi.decode(_extra, (bytes32, string, string, uint256, uint256));
		require(fractionalizers[_type] != address(0), "unsupported type");
		require(30 minutes <= _duration && _duration <= 731 days, "invalid duration");
		require(_fee <= 100e16, "invalid fee");
	}

	function _issuing(bytes storage _extra) internal pure returns (uint256 _fractionsCount)
	{
		(,,,, uint256 _fee) = abi.decode(_extra, (bytes32, string, string, uint256, uint256));
		return FRACTIONS_COUNT - (FRACTIONS_COUNT * _fee / 1e18);
	}

	function _fractionalize(uint256 _listingId, uint256 _fractionPrice) internal returns (address _fractions)
	{
		ListingInfo storage _listing = listings[_listingId];
		(bytes32 _type, string memory _name, string memory _symbol, uint256 _duration, uint256 _fee) = abi.decode(_listing.extra, (bytes32, string, string, uint256, uint256));
		IERC721(_listing.collection).approve(fractionalizers[_type], _listing.tokenId);
		return IAuctionFractionalizer(fractionalizers[_type]).fractionalize(_listing.collection, _listing.tokenId, _name, _symbol, FRACTIONS_DECIMALS, FRACTIONS_COUNT, _fractionPrice, _listing.paymentToken, 0, _duration, _fee);
	}

	function _balanceOf(address _token) internal view returns (uint256 _balance)
	{
		if (_token == address(0)) {
			return address(this).balance;
		} else {
			return IERC20(_token).balanceOf(address(this));
		}
	}

	function _safeTransfer(address _token, address payable _to, uint256 _amount) internal
	{
		if (_token == address(0)) {
			_to.transfer(_amount);
		} else {
			IERC20(_token).safeTransfer(_to, _amount);
		}
	}

	function _safeTransferFrom(address _token, address payable _from, uint256 _value, address payable _to, uint256 _amount) internal
	{
		if (_token == address(0)) {
			require(_value == _amount, "invalid value");
			if (_to != address(this)) _to.transfer(_amount);
		} else {
			require(_value == 0, "invalid value");
			IERC20(_token).safeTransferFrom(_from, _to, _amount);
		}
	}

	event UpdateFee(uint256 _fee);
	event UpdateCreatorFee(uint256 indexed _listingId, uint256 _fee);
	event AddFractionalizer(bytes32 indexed _type, address indexed _fractionalizer);
	event Listed(uint256 indexed _listingId, address indexed _creator);
	event Acquired(uint256 indexed _listingId);
	event Relisted(uint256 indexed _listingId);
	event Join(uint256 indexed _listingId, address indexed _buyer, uint256 _amount);
	event Leave(uint256 indexed _listingId, address indexed _buyer, uint256 _amount);
	event Payout(uint256 indexed _listingId, address indexed _seller, uint256 _netAmount, uint256 _feeAmount, uint256 _creatorFeeAmount);
	event Claim(uint256 indexed _listingId, address indexed _buyer, uint256 _amount, uint256 _fractionsCount);
}
