// Fungify
pragma solidity >= 0.4.20;

import "./ERC20Base.sol";
import "./ERC721Base.sol";

contract Fungify is ERC721Receiver
{
	mapping (address => Wrapper) wrappers;
	mapping (address => mapping (uint256 => Shares)) shares;

	constructor () public
	{
	}

	function getWrapper(ERC721 _target) external view returns (ERC721 _wrapper)
	{
		return wrappers[address(_target)];
	}

	function getShares(ERC721 _target, uint256 _tokenId) external view returns (ERC20 _shares)
	{
		return shares[address(_target)][_tokenId];
	}

	function onERC721Received(address /*_operator*/, address _from, uint256 _tokenId, bytes memory _data) public returns (bytes4 _magic)
	{
		address _target = msg.sender;
		uint256 _supply;
		require(_data.length == 32);
		assembly { _supply := mload(add(_data, 32)) }
		require(_supply > 0);
		Wrapper _wrapper = wrappers[_target];
		if (_wrapper == Wrapper(0)) {
			_wrapper = new Wrapper(address(this), _target);
			wrappers[_target] = _wrapper;
		}
		_wrapper._insert(_from, _tokenId);
		Shares _shares = new Shares(_target, _tokenId, _from, _supply);
		assert(shares[_target][_tokenId] == Shares(0));
		shares[_target][_tokenId] = _shares;
		ERC721(_target).transferFrom(address(this), address(_shares), _tokenId);
		return ERC721Receiver(this).onERC721Received.selector;
	}
}

contract Wrapper is ERC721Metadata, ERC721Base
{
	address admin;
	address target;

	constructor (address _admin, address _target) public
	{
		admin = _admin;
		target = _target;
	}

	function _insert(address _owner, uint256 _tokenId) public
	{
		address _admin = msg.sender;
		require(_admin == admin);
		assert(balances[_owner] + 1 > balances[_owner]);
		balances[_owner]++;
		assert(owners[_tokenId] == address(0));
		owners[_tokenId] = _owner;
	}

	function _remove(address _owner, uint256 _tokenId) public
	{
		address _admin = msg.sender;
		require(_admin == admin);
		require(owners[_tokenId] == _owner);
		assert(balances[_owner] > 0);
		balances[_owner]--;
		owners[_tokenId] = address(0);
		approvals[_tokenId] = address(0);
	}

	function name() external view returns (string memory _name)
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
}

contract Shares is ERC20Metadata, ERC20Base
{
	uint256 constant SHARES = 1 * 10**9;

	address target;
	uint256 tokenId;
	uint256 sharePrice;
	bool redeemable;

	function name() public view returns (string memory _name)
	{
		return string(abi.encodePacked(ERC721Metadata(target).name(), "@", bytes32(tokenId)));
	}

	function symbol() public view returns (string memory _symbol)
	{
		return string(abi.encodePacked(ERC721Metadata(target).symbol(), "@", bytes32(tokenId)));
	}

	function decimals() public view returns (uint8 _decimals)
	{
		return 18;
	}

	constructor (address _target, uint256 _tokenId, address _owner, uint256 _price) public
	{
		require(_price % SHARES == 0);
		target = _target;
		tokenId = _tokenId;
		sharePrice = _price / SHARES;
		redeemable = false;
		supply = SHARES;
		balances[_owner] = SHARES;
	}

	function release1() public returns (bool _success)
	{
		require(!redeemable);
		address _from = msg.sender;
		uint256 _value = balances[_from];
		require(_value == supply);
		balances[_from] = 0;
		supply = 0;
		ERC721(target).safeTransferFrom(address(this), _from, tokenId);
		return true;
	}

	function release2() public payable returns (bool _success)
	{
		require(!redeemable);
		address _from = msg.sender;
		uint256 _value = msg.value;
		uint256 _price = sharePrice * SHARES;
		require(_value == _price);
		redeemable = true;
		ERC721(target).safeTransferFrom(address(this), _from, tokenId);
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
