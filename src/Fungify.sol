// Fungify
pragma solidity >= 0.4.20;

import "./ERC20Base.sol";
import "./ERC721Base.sol";

contract Fungify is ERC721Receiver
{
	mapping (address => Wrapper) wrappers;

	constructor () public
	{
	}

	function getWrapper(address _target) public view returns (ERC721 _wrapper)
	{
		return wrappers[_target];
	}

	function onERC721Received(address /*_operator*/, address _from, uint256 _tokenId, bytes memory _data) public returns (bytes4 _magic)
	{
		address _target = msg.sender;
		uint256 _price;
		require(_data.length == 32);
		assembly { _price := mload(add(_data, 32)) }
		Wrapper _wrapper = wrappers[_target];
		if (_wrapper == Wrapper(0)) {
			_wrapper = new Wrapper(address(this), _target);
			wrappers[_target] = _wrapper;
		}
		Shares _shares = new Shares(_wrapper, _from, _tokenId, _price);
		_wrapper._insert(_from, _tokenId, _shares);
		ERC721(_target).transferFrom(address(this), address(_shares), _tokenId);
		return ERC721Receiver(this).onERC721Received.selector;
	}
}

contract Wrapper is ERC721Metadata, ERC721Base
{
	address admin;
	address target;
	mapping (uint256 => Shares) shares;

	function name() public view returns (string memory _name)
	{
		return ERC721Metadata(target).name();
	}

	function symbol() public view returns (string memory _symbol)
	{
		return ERC721Metadata(target).symbol();
	}

	function tokenURI(uint256 _tokenId) public view returns (string memory _tokenURI)
	{
		return ERC721Metadata(target).tokenURI(_tokenId);
	}

	constructor (address _admin, address _target) public
	{
		admin = _admin;
		target = _target;
	}

	function getTarget() public view returns (ERC721 _target)
	{
		return ERC721(target);
	}

	function getShares(uint256 _tokenId) public view returns (ERC20 _shares)
	{
		return shares[_tokenId];
	}

	function _insert(address _owner, uint256 _tokenId, Shares _shares) public
	{
		address _admin = msg.sender;
		require(_admin == admin);
		assert(shares[_tokenId] == Shares(0));
		shares[_tokenId] = _shares;
		assert(balances[_owner] + 1 > balances[_owner]);
		balances[_owner]++;
		assert(owners[_tokenId] == address(0));
		owners[_tokenId] = _owner;
	}

	function _remove(uint256 _tokenId) public
	{
		address _shares = msg.sender;
		require(_shares == address(shares[_tokenId]));
		shares[_tokenId] = Shares(0);
		address _owner = owners[_tokenId];
		assert(balances[_owner] > 0);
		balances[_owner]--;
		owners[_tokenId] = address(0);
		approvals[_tokenId] = address(0);
	}
}

contract Shares is ERC20Metadata, ERC20Base
{
	uint256 constant SHARES = 1 * 10**9;

	Wrapper wrapper;
	uint256 tokenId;
	uint256 sharePrice;
	bool redeemable;

	function name() public view returns (string memory _name)
	{
		return string(abi.encodePacked(wrapper.name(), "@", bytes32(tokenId)));
	}

	function symbol() public view returns (string memory _symbol)
	{
		return string(abi.encodePacked(wrapper.symbol(), "@", bytes32(tokenId)));
	}

	function decimals() public view returns (uint8 _decimals)
	{
		return 0;
	}

	constructor (Wrapper _wrapper, address _owner, uint256 _tokenId, uint256 _price) public
	{
		require(_price % SHARES == 0);
		wrapper = _wrapper;
		tokenId = _tokenId;
		sharePrice = _price / SHARES;
		redeemable = false;
		supply = SHARES;
		balances[_owner] = SHARES;
	}

	function release() public payable returns (bool _success)
	{
		require(!redeemable);
		address payable _from = msg.sender;
		uint256 _value1 = msg.value;
		uint256 _value2 = sharePrice * balances[_from];
		uint256 _price = sharePrice * SHARES;
		uint256 _total = _value1 + _value2;
		require(_total >= _price);
		uint256 _change = _total - _price;
		redeemable = true;
		wrapper._remove(tokenId);
		wrapper.getTarget().safeTransferFrom(address(this), _from, tokenId);
		if (_change > 0) _from.transfer(_change);
		return true;
	}

	function redeem() public returns (bool _success)
	{
		require(redeemable);
		address payable _from = msg.sender;
		uint256 _value = balances[_from];
		require(_value > 0);
		balances[_from] = 0;
		assert(supply >= _value);
		supply -= _value;
		uint256 _amount = _value * sharePrice;
		_from.transfer(_amount);
		return true;
	}
}
