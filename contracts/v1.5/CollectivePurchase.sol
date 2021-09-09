// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { SafeERC721 } from "./SafeERC721.sol";

import { AuctionFractionalizer } from "./AuctionFractionalizer.sol";

contract CollectivePurchase is ReentrancyGuard
{
	using SafeERC20 for IERC20;
	using SafeERC721 for IERC721;
	using SafeMath for uint256;

	enum State { Created, Funded, Started, Ended }

	struct BuyerInfo {
		uint256 amount;
	}

	struct ListingInfo {
		State state;
		address payable seller;
		address collection;
		uint256 tokenId;
		address paymentToken;
		uint256 reservePrice;
		uint256 limitPrice;
		uint256 extension;
		uint256 amount;
		uint256 cutoff;
		uint256 fractionsCount;
		address fractions;
		mapping (address => BuyerInfo) buyers;
	}

	uint256 public immutable fee;
	address payable public immutable vault;
	address public immutable fractionalizer;

	mapping (address => uint256) private balances;
	mapping (address => mapping (uint256 => bool)) private items;

	ListingInfo[] public listings;

	modifier onlySeller(uint256 _listingId)
	{
		ListingInfo storage _listing = listings[_listingId];
		require(msg.sender == _listing.seller, "access denied");
		_;
	}

	modifier inState(uint256 _listingId, State _state)
	{
		ListingInfo storage _listing = listings[_listingId];
		require(_state == _listing.state, "not available");
		_;
	}

	modifier notInState(uint256 _listingId, State _state)
	{
		ListingInfo storage _listing = listings[_listingId];
		require(_state != _listing.state, "not available");
		_;
	}

	constructor (uint256 _fee, address payable _vault, address _fractionalizer) public
	{
		require(_fee <= 1e18, "invalid fee");
		require(_vault != address(0), "invalid address");
		fee = _fee;
		vault = _vault;
		fractionalizer = _fractionalizer;
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
		if (_listing.state == State.Funded) return "FUNDED";
		if (_listing.state == State.Started) return now <= _listing.cutoff ? "STARTED" : "ENDING";
		return "ENDED";
	}

	function maxJoinAmount(uint256 _listingId) external view returns (uint256 _amount)
	{
		ListingInfo storage _listing = listings[_listingId];
		return _listing.limitPrice - _listing.amount;
	}

	function buyerFractionsCount(uint256 _listingId, address _buyer) external view inState(_listingId, State.Ended) returns (uint256 _fractionsCount)
	{
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.buyers[_buyer].amount;
		_fractionsCount = (_amount * _listing.fractionsCount) / _listing.reservePrice;
		return _fractionsCount;
	}

	function list(address _collection, uint256 _tokenId, address _paymentToken, uint256 _reservePrice, uint256 _limitPrice, uint256 _extension) external nonReentrant returns (uint256 _listingId)
	{
		address payable _seller = msg.sender;
		require(_limitPrice * 1e18 / _limitPrice == 1e18, "price overflow");
		require(0 < _reservePrice && _reservePrice <= _limitPrice, "invalid price");
		require(30 minutes <= _extension && _extension <= 731 days, "invalid duration");
		IERC721(_collection).transferFrom(_seller, address(this), _tokenId);
		items[_collection][_tokenId] = true;
		_listingId = listings.length;
		listings.push(ListingInfo({
			state: State.Created,
			seller: _seller,
			collection: _collection,
			tokenId: _tokenId,
			paymentToken: _paymentToken,
			reservePrice: _reservePrice,
			limitPrice: _limitPrice,
			extension: _extension,
			amount: 0,
			cutoff: uint256(-1),
			fractionsCount: 0,
			fractions: address(0)
		}));
		emit Listed(_listingId);
		return _listingId;
	}

	function cancel(uint256 _listingId) external nonReentrant onlySeller(_listingId) inState(_listingId, State.Created)
	{
		ListingInfo storage _listing = listings[_listingId];
		_listing.state = State.Ended;
		items[_listing.collection][_listing.tokenId] = false;
		IERC721(_listing.collection).safeTransfer(_listing.seller, _listing.tokenId);
		emit Canceled(_listingId);
	}

	function updatePrice(uint256 _listingId, uint256 _newReservePrice, uint256 _newLimitPrice) external onlySeller(_listingId) inState(_listingId, State.Created)
	{
		require(_newLimitPrice * 1e18 / _newLimitPrice == 1e18, "price overflow");
		require(0 < _newReservePrice && _newReservePrice <= _newLimitPrice, "invalid price");
		ListingInfo storage _listing = listings[_listingId];
		uint256 _oldReservePrice = _listing.reservePrice;
		uint256 _oldLimitPrice = _listing.limitPrice;
		_listing.reservePrice = _newReservePrice;
		_listing.limitPrice = _newLimitPrice;
		emit UpdatePrice(_listingId, _oldReservePrice, _oldLimitPrice, _newReservePrice, _newLimitPrice);
	}

	function accept(uint256 _listingId) external onlySeller(_listingId) inState(_listingId, State.Funded)
	{
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.reservePrice - _listing.amount;
		uint256 _feeAmount = (_amount * fee) / 1e18;
		uint256 _netAmount = _amount - _feeAmount;
		_listing.state = State.Started;
		_listing.cutoff = now - 1;
		_listing.buyers[vault].amount += _feeAmount;
		_listing.buyers[_listing.seller].amount += _netAmount;
		emit Sold(_listingId);
	}

	function join(uint256 _listingId, uint256 _amount) external payable nonReentrant notInState(_listingId, State.Ended)
	{
		address payable _buyer = msg.sender;
		uint256 _value = msg.value;
		ListingInfo storage _listing = listings[_listingId];
		require(now <= _listing.cutoff, "not available");
		uint256 _leftAmount = _listing.limitPrice - _listing.amount;
		require(_amount <= _leftAmount, "limit exceeded");
		_safeTransferFrom(_listing.paymentToken, _buyer, _value, payable(address(this)), _amount);
		balances[_listing.paymentToken] += _amount;
		_listing.amount += _amount;
		_listing.buyers[_buyer].amount += _amount;
		if (_listing.state == State.Created) _listing.state = State.Funded;
		if (_listing.state == State.Funded) {
			if (_listing.amount >= _listing.reservePrice) {
				_listing.state = State.Started;
				_listing.cutoff = now + _listing.extension;
				emit Sold(_listingId);
			}
		}
		if (_listing.state == State.Started) _listing.reservePrice = _listing.amount;
		emit Join(_listingId, _buyer, _amount);
	}

	function leave(uint256 _listingId) external nonReentrant inState(_listingId, State.Funded)
	{
		address payable _buyer = msg.sender;
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.buyers[_buyer].amount;
		require(_amount > 0, "insufficient balance");
		_listing.buyers[_buyer].amount = 0;
		_listing.amount -= _amount;
		balances[_listing.paymentToken] -= _amount;
		if (_listing.amount == 0) _listing.state = State.Created;
		_safeTransfer(_listing.paymentToken, _buyer, _amount);
		emit Leave(_listingId, _buyer, _amount);
	}

	function relist(uint256 _listingId) external nonReentrant inState(_listingId, State.Started)
	{
		ListingInfo storage _listing = listings[_listingId];
		require(now > _listing.cutoff, "not available");
		uint256 _fractionsCount = 100e6;
		uint256 _fractionPrice = (_listing.reservePrice + _fractionsCount - 1) / _fractionsCount;
		_listing.state = State.Ended;
		_listing.fractionsCount = _fractionsCount;
		items[_listing.collection][_listing.tokenId] = false;
		IERC721(_listing.collection).approve(fractionalizer, _listing.tokenId);
		_listing.fractions = AuctionFractionalizer(fractionalizer).fractionalize(_listing.collection, _listing.tokenId, "", "", 6, _fractionsCount, 5 * _fractionPrice, _listing.paymentToken, 0, 24 hours, 1e18);
		balances[_listing.fractions] += _fractionsCount;
		emit Relisted(_listingId);
	}

	function payout(uint256 _listingId) external nonReentrant inState(_listingId, State.Ended)
	{
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.amount;
		require(_amount > 0, "insufficient balance");
		uint256 _feeAmount = (_amount * fee) / 1e18;
		uint256 _netAmount = _amount - _feeAmount;
		_listing.amount = 0;
		balances[_listing.paymentToken] -= _amount;
		_safeTransfer(_listing.paymentToken, vault, _feeAmount);
		_safeTransfer(_listing.paymentToken, _listing.seller, _netAmount);
		emit Payout(_listingId, _listing.seller, _netAmount, _feeAmount);
	}

	function claim(uint256 _listingId, address payable _buyer) external nonReentrant inState(_listingId, State.Ended)
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

	function recoverLostFunds(address _token, address payable _to) external nonReentrant
	{
		uint256 _balance = balances[_token];
		uint256 _current = _balanceOf(_token);
		if (_current > _balance) {
			uint256 _excess = _current - _balance;
			_safeTransfer(_token, _to, _excess);
		}
	}

	function recoverLostItem(address _collection, uint256 _tokenId, address _to) external nonReentrant
	{
		if (items[_collection][_tokenId]) return;
		IERC721(_collection).safeTransfer(_to, _tokenId);
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

	event Listed(uint256 indexed _listingId);
	event Sold(uint256 indexed _listingId);
	event Relisted(uint256 indexed _listingId);
	event Canceled(uint256 indexed _listingId);
	event UpdatePrice(uint256 indexed _listingId, uint256 _oldReservePrice, uint256 _oldLimitPrice, uint256 _newReservePrice, uint256 _newLimitPrice);
	event Join(uint256 indexed _listingId, address indexed _buyer, uint256 _amount);
	event Leave(uint256 indexed _listingId, address indexed _buyer, uint256 _amount);
	event Payout(uint256 indexed _listingId, address indexed _seller, uint256 _netAmount, uint256 _feeAmount);
	event Claim(uint256 indexed _listingId, address indexed _buyer, uint256 _amount, uint256 _fractionsCount);
}
