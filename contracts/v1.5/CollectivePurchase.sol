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

	modifier onlyBuyer(uint256 _listingId)
	{
		ListingInfo storage _listing = listings[_listingId];
		require(_listing.buyers[msg.sender].amount > 0, "access denied");
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

	function list(address _collection, uint256 _tokenId, address _paymentToken, uint256 _reservePrice, uint256 _limitPrice) external nonReentrant returns (uint256 _listingId)
	{
		address payable _from = msg.sender;
		require(0 < _reservePrice && _reservePrice <= _limitPrice, "invalid price");
		IERC721(_collection).transferFrom(_from, address(this), _tokenId);
		items[_collection][_tokenId] = true;
		_listingId = listings.length;
		listings.push(ListingInfo({
			state: State.Created,
			seller: _from,
			collection: _collection,
			tokenId: _tokenId,
			paymentToken: _paymentToken,
			reservePrice: _reservePrice,
			limitPrice: _limitPrice,
			amount: 0,
			cutoff: uint256(-1),
			fractionsCount: 100e6,
			fractions: address(0)
		}));
		return _listingId;
	}

	function cancel(uint256 _listingId) external nonReentrant onlySeller(_listingId) inState(_listingId, State.Created)
	{
		ListingInfo storage _listing = listings[_listingId];
		_listing.state = State.Ended;
		items[_listing.collection][_listing.tokenId] = false;
		IERC721(_listing.collection).safeTransfer(_listing.seller, _listing.tokenId);
		emit Cancel(_listingId);
	}

	function updatePrice(uint256 _listingId, uint256 _newReservePrice, uint256 _newLimitPrice) external onlySeller(_listingId) inState(_listingId, State.Created)
	{
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
		uint256 _leftAmount = _listing.reservePrice - _listing.amount;
		_listing.state == State.Started;
		_listing.cutoff = now - 1;
		_listing.buyers[_listing.seller].amount += _leftAmount;
		emit Sold(_listingId);
	}

	function join(uint256 _listingId, uint256 _amount) external payable nonReentrant notInState(_listingId, State.Ended)
	{
		address payable _from = msg.sender;
		uint256 _value = msg.value;
		ListingInfo storage _listing = listings[_listingId];
		uint256 _leftAmount = _listing.limitPrice - _listing.amount;
		require(_amount <= _leftAmount, "limit exceeded");
		_safeTransferFrom(_listing.paymentToken, _from, _value, payable(address(this)), _amount);
		balances[_listing.paymentToken] += _amount;
		_listing.amount += _amount;
		_listing.buyers[_from].amount += _amount;
		if (_listing.state == State.Created) _listing.state == State.Funded;
		if (_listing.state == State.Funded) {
			if (_listing.amount >= _listing.reservePrice) {
				_listing.state == State.Started;
				_listing.cutoff = now + 7 days;
				emit Sold(_listingId);
			}
		}
		if (_listing.state == State.Started) _listing.reservePrice = _listing.amount;
		emit Join(_from, _listingId, _amount);
	}

	function leave(uint256 _listingId) external nonReentrant onlyBuyer(_listingId) inState(_listingId, State.Funded)
	{
		address payable _from = msg.sender;
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.buyers[_from].amount;
		_listing.buyers[_from].amount = 0;
		_listing.amount -= _amount;
		balances[_listing.paymentToken] -= _amount;
		if (_listing.amount == 0) _listing.state == State.Created;
		_safeTransfer(_listing.paymentToken, _from, _amount);
		emit Leave(_from, _listingId, _amount);
	}

	function relist(uint256 _listingId) external nonReentrant inState(_listingId, State.Started)
	{
		ListingInfo storage _listing = listings[_listingId];
		require(now > _listing.cutoff, "not available");
		uint256 _fractionsCount = _listing.fractionsCount;
		uint256 _fractionPrice = (_listing.reservePrice + _fractionsCount - 1) / _fractionsCount;
		_listing.state = State.Ended;
		items[_listing.collection][_listing.tokenId] = false;
		IERC721(_listing.collection).approve(fractionalizer, _listing.tokenId);
		_listing.fractions = AuctionFractionalizer(fractionalizer).fractionalize(_listing.collection, _listing.tokenId, "", "", 6, _fractionsCount, 5 * _fractionPrice, _listing.paymentToken, 0, 24 hours, 1e18);
		emit Ended(_listingId);
	}

	function payout(uint256 _listingId) external nonReentrant inState(_listingId, State.Ended)
	{
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.amount;
		uint256 _feeAmount = (_amount * fee) / 1e18;
		uint256 _netAmount = _amount - _feeAmount;
		_listing.amount = 0;
		balances[_listing.paymentToken] -= _amount;
		_safeTransfer(_listing.paymentToken, vault, _feeAmount);
		_safeTransfer(_listing.paymentToken, _listing.seller, _netAmount);
		emit Payout(_listing.seller, _listingId, _netAmount, _feeAmount);
	}

	function claim(uint256 _listingId) external nonReentrant onlyBuyer(_listingId) inState(_listingId, State.Ended)
	{
		address payable _from = msg.sender;
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.buyers[_from].amount;
		uint256 _fractionsCount = (_amount * _listing.fractionsCount) / _listing.reservePrice;
		_listing.buyers[_from].amount = 0;
		_safeTransfer(_listing.fractions, _from, _fractionsCount);
		emit Claim(_from, _listingId, _amount, _fractionsCount);
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

	event UpdatePrice(uint256 indexed _listingId, uint256 _oldReservePrice, uint256 _oldLimitPrice, uint256 _newReservePrice, uint256 _newLimitPrice);
	event Cancel(uint256 indexed _listingId);
	event Join(address indexed _buyer, uint256 indexed _listingId, uint256 _amount);
	event Leave(address indexed _buyer, uint256 indexed _listingId, uint256 _amount);
	event Payout(address indexed _seller, uint256 indexed _listingId, uint256 _netAmount, uint256 _feeAmount);
	event Claim(address indexed _buyer, uint256 indexed _listingId, uint256 _amount, uint256 _fractionsCount);
	event Sold(uint256 indexed _listingId);
	event Ended(uint256 indexed _listingId);
}
