// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { SafeERC721 } from "./SafeERC721.sol";

import { Fractionalizer } from "./Fractionalizer.sol";

contract CollectivePurchase is ReentrancyGuard
{
	using SafeERC20 for IERC20;
	using SafeERC721 for IERC721;
	using SafeMath for uint256;

	enum State { Created, Funded, Started, Finalized }

	struct BuyerInfo {
		uint256 amount;
	}

	struct ListingInfo {
		State state;
		address seller;
		address collection;
		uint256 tokenId;
		uint256 reservePrice;
		address paymentToken;
		uint256 amount;
		uint256 cutoff;
		address fractionalizer;
		bytes params;
		uint256 fractionsCount;
		address fractions;
		mapping (address => BuyerInfo) buyers;
	}

	address public immutable defaultFractionalizer;

	mapping (address => uint256) private balances;
	mapping (address => mapping (uint256 => bool)) private items;

	ListingInfo[] public listings;

	modifier onlySeller(uint256 _listingId)
	{
		ListingInfo storage _listingInfo = listings[_listingId];
		require(msg.sender == _listingInfo.seller, "access denied");
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

	constructor (address _defaultFractionalizer) public
	{
		defaultFractionalizer = _defaultFractionalizer;
	}

	function listingCount() external view returns (uint256 _count)
	{
		return listings.length;
	}

	function list(address _collection, uint256 _tokenId, uint256 _reservePrice, address _paymentToken, address _fractionalizer, bytes calldata _params) external nonReentrant returns (uint256 _listingId)
	{
		address _from = msg.sender;
		require(_reservePrice > 0, "invalid price");
		IERC721(_collection).transferFrom(_from, address(this), _tokenId);
		items[_collection][_tokenId] = true;
		_listingId = listings.length;
		listings.push(ListingInfo({
			state: State.Created,
			seller: _from,
			collection: _collection,
			tokenId: _tokenId,
			reservePrice: _reservePrice,
			paymentToken: _paymentToken,
			amount: 0,
			cutoff: uint256(-1),
			fractionalizer: _fractionalizer,
			params: _params,
			fractionsCount: 0,
			fractions: address(0)
		}));
		return _listingId;
	}

	function cancel(uint256 _listingId) external nonReentrant onlySeller(_listingId) inState(_listingId, State.Created)
	{
		address _from = msg.sender;
		ListingInfo storage _listing = listings[_listingId];
		_listing.state = State.Finalized;
		items[_listing.collection][_listing.tokenId] = false;
		IERC721(_listing.collection).safeTransfer(_from, _listing.tokenId);
		emit Cancel(_from, _listingId);
	}

	function updatePrice(uint256 _listingId, uint256 _newReservePrice) external onlySeller(_listingId) inState(_listingId, State.Created)
	{
		address _from = msg.sender;
		require(_newReservePrice > 0, "invalid price");
		ListingInfo storage _listing = listings[_listingId];
		uint256 _oldReservePrice = _listing.reservePrice;
		_listing.reservePrice = _newReservePrice;
		emit UpdatePrice(_from, _listingId, _oldReservePrice, _newReservePrice);
	}

	function accept(uint256 _listingId) external onlySeller(_listingId) inState(_listingId, State.Funded)
	{
		ListingInfo storage _listing = listings[_listingId];
		_listing.state == State.Started;
		_listing.reservePrice = _listing.amount;
		_listing.cutoff = now;
		emit Sold(_listingId);
	}

	function deposit(uint256 _listingId, uint256 _amount) external payable nonReentrant notInState(_listingId, State.Finalized)
	{
		address payable _from = msg.sender;
		uint256 _value = msg.value;
		ListingInfo storage _listing = listings[_listingId];
		_listing.amount += _amount;
		_listing.buyers[_from].amount += _amount;
		balances[_listing.paymentToken] += _amount;
		_safeTransferFrom(_listing.paymentToken, _from, _value, payable(address(this)), _amount);
		if (_listing.state == State.Created) _listing.state == State.Funded;
		if (_listing.state == State.Funded) {
			if (_listing.amount >= _listing.reservePrice) {
				_listing.state == State.Started;
				_listing.cutoff = now + 7 days;
				emit Sold(_listingId);
			}
		}
		if (_listing.state == State.Started) _listing.reservePrice = _listing.amount;
		emit Deposit(_from, _listingId, _amount);
	}

	function withdraw(uint256 _listingId, uint256 _amount) external nonReentrant inState(_listingId, State.Funded)
	{
		address payable _from = msg.sender;
		ListingInfo storage _listing = listings[_listingId];
		require(_amount <= _listing.buyers[_from].amount, "insufficient balance");
		_listing.buyers[_from].amount -= _amount;
		_listing.amount -= _amount;
		balances[_listing.paymentToken] -= _amount;
		if (_listing.amount == 0) _listing.state == State.Created;
		_safeTransfer(_listing.paymentToken, _from, _amount);
		emit Withdrawal(_from, _listingId, _amount);
	}

	function relist(uint256 _listingId) external nonReentrant inState(_listingId, State.Started)
	{
		ListingInfo storage _listing = listings[_listingId];
		require(now > _listing.cutoff, "not available");
		_listing.state = State.Finalized;
		items[_listing.collection][_listing.tokenId] = false;
		_listing.fractionsCount = 100e6;
		uint256 _fractionPrice = (_listing.amount + _listing.fractionsCount - 1) / _listing.fractionsCount;
		IERC721(_listing.collection).approve(defaultFractionalizer, _listing.tokenId);
		_listing.fractions = Fractionalizer(defaultFractionalizer).fractionalize(_listing.collection, _listing.tokenId, "", "", 6, _listing.fractionsCount, _fractionPrice, _listing.paymentToken);
		emit Ended(_listingId);
	}

	function collect(uint256 _listingId) external nonReentrant onlySeller(_listingId) inState(_listingId, State.Finalized)
	{
		address payable _from = msg.sender;
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.amount;
		_listing.amount = 0;
		balances[_listing.paymentToken] -= _amount;
		_safeTransfer(_listing.paymentToken, _from, _amount);
		emit Collect(_from, _listingId, _amount);
	}

	function claim(uint256 _listingId) external nonReentrant inState(_listingId, State.Finalized)
	{
		address payable _from = msg.sender;
		ListingInfo storage _listing = listings[_listingId];
		uint256 _amount = _listing.buyers[_from].amount;
		_listing.buyers[_from].amount = 0;
		uint256 _fractionsCount = _amount.mul(_listing.fractionsCount) / _listing.amount;
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

	event UpdatePrice(address indexed _from, uint256 indexed _listingId, uint256 _oldReservePrice, uint256 _newReservePrice);
	event Cancel(address indexed _from, uint256 indexed _listingId);
	event Deposit(address indexed _from, uint256 indexed _listingId, uint256 _amount);
	event Withdrawal(address indexed _from, uint256 indexed _listingId, uint256 _amount);
	event Collect(address indexed _from, uint256 indexed _listingId, uint256 _amount);
	event Claim(address indexed _from, uint256 indexed _listingId, uint256 _amount, uint256 _fractionsCount);
	event Sold(uint256 indexed _listingId);
	event Ended(uint256 indexed _listingId);
}
