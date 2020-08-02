// Nftfy
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Nftfy is IERC721Receiver, ERC165
{
	bytes4 constant INTERFACE_ID_ERC721_RECEIVER = 0x150b7a02;

	mapping (address => Wrapper) wrappers;
	mapping (address => bool) wraps;

	constructor () public
	{
		_registerInterface(INTERFACE_ID_ERC721_RECEIVER);
	}

	function getWrapper(address _target) public view returns (ERC721 _wrapper)
	{
		return wrappers[_target];
	}

	function onERC721Received(address /*_operator*/, address _from, uint256 _tokenId, bytes memory _data) public override returns (bytes4 _magic)
	{
		address _target = msg.sender;
		require(!wraps[_target]);
		uint256 _price = 1 ether;
		if (_data.length > 0) {
			require(_data.length == 32);
			assembly { _price := mload(add(_data, 32)) }
		}
		Wrapper _wrapper = wrappers[_target];
		if (_wrapper == Wrapper(0)) {
			_wrapper = new Wrapper(address(this), _target);
			wrappers[_target] = _wrapper;
			wraps[address(_wrapper)] = true;
		}
		Shares _shares = new Shares(_wrapper, _from, _tokenId, _price);
		string memory _tokenURI = IERC721Metadata(_target).tokenURI(_tokenId);
		_wrapper._insert(_from, _tokenId, _tokenURI, _shares);
		IERC721(_target).transferFrom(address(this), address(_shares), _tokenId);
		return this.onERC721Received.selector;
	}
}

contract Wrapper is ERC721
{
	address admin;
	address target;
	mapping (uint256 => Shares) shares;

	function getName(address _target) internal view returns (string memory _name)
	{
		return string(abi.encodePacked("Wrapped ", IERC721Metadata(_target).name()));
	}

	function getSymbol(address _target) internal view returns (string memory _symbol)
	{
		return string(abi.encodePacked("w", IERC721Metadata(_target).symbol()));
	}

	constructor (address _admin, address _target) ERC721(getName(_target), getSymbol(_target)) public
	{
		admin = _admin;
		target = _target;
	}

	function getTarget() public view returns (IERC721 _target)
	{
		return IERC721(target);
	}

	function getShares(uint256 _tokenId) public view returns (IERC20 _shares)
	{
		return shares[_tokenId];
	}

	function _insert(address _owner, uint256 _tokenId, string memory _tokenURI, Shares _shares) public
	{
		address _admin = msg.sender;
		require(_admin == admin);
		assert(shares[_tokenId] == Shares(0));
		shares[_tokenId] = _shares;
		_safeMint(_owner, _tokenId);
		_setTokenURI(_tokenId, _tokenURI);
	}

	function _remove(address _owner, uint256 _tokenId) public
	{
		address _shares = msg.sender;
		require(_shares == address(shares[_tokenId]));
		shares[_tokenId] = Shares(0);
		require(_owner == ownerOf(_tokenId));
		_burn(_tokenId);
	}
}

contract Shares is ERC20
{
	uint256 constant SHARES = 1 * 10**6;

	Wrapper wrapper;
	uint256 tokenId;
	uint256 sharePrice;
	bool redeemable;

	function getName(Wrapper _wrapper, uint256 _tokenId) internal view returns (string memory _name)
	{
		return string(abi.encodePacked(_wrapper.name(), " #", decs(_tokenId), " Shares"));
	}

	function getSymbol(Wrapper _wrapper, uint256 _tokenId) internal view returns (string memory _symbol)
	{
		return string(abi.encodePacked("s", _wrapper.symbol(), "-", decs(_tokenId)));
	}

	function decc(uint8 _value) internal pure returns (byte _char)
	{
		assert(_value < 10);
		return byte(uint8(byte("0")) + _value);
	}

	function decs(uint256 _value) internal pure returns (string memory _string)
	{
		uint256 _size = 0;
		uint256 _copy = _value;
		while (_copy > 0) {
			_copy /= 10;
			_size++;
		}
		if (_value == 0) _size = 1;
		bytes memory _buffer = new bytes(_size);
		for (uint256 _i = _size; _i > 0; _i--) {
			uint256 _index = _i - 1;
			uint8 _ord = uint8(_value % 10);
			_buffer[_index] = decc(_ord);
			_value /= 10;
		}
		return string(_buffer);
	}

	constructor (Wrapper _wrapper, address _owner, uint256 _tokenId, uint256 _price) ERC20(getName(_wrapper, _tokenId), getSymbol(_wrapper, _tokenId)) public
	{
		require(_price % SHARES == 0);
		wrapper = _wrapper;
		tokenId = _tokenId;
		sharePrice = _price / SHARES;
		redeemable = false;
		_mint(_owner, SHARES);
		_setupDecimals(0);
	}

	function getWrapper() public view returns (ERC721 _wrapper)
	{
		return wrapper;
	}

	function getTokenId() public view returns (uint256 _tokenId)
	{
		return tokenId;
	}

	function getSharePrice() public view returns (uint256 _sharePrice)
	{
		return sharePrice;
	}

	function isRedeemable() public view returns (bool _redeemable)
	{
		return redeemable;
	}

	function release() public payable returns (bool _success)
	{
		require(!redeemable);
		address payable _from = msg.sender;
		uint256 _balance = balanceOf(_from);
		uint256 _value1 = msg.value;
		uint256 _value2 = sharePrice * _balance;
		uint256 _price = sharePrice * SHARES;
		uint256 _total = _value1 + _value2;
		require(_total >= _price);
		uint256 _change = _total - _price;
		redeemable = true;
		_burn(_from, _balance);
		wrapper._remove(_from, tokenId);
		wrapper.getTarget().safeTransferFrom(address(this), _from, tokenId);
		if (_change > 0) _from.transfer(_change);
		uint256 _supply = totalSupply();
		if (_supply == 0) selfdestruct(_from);
		return true;
	}

	function redeem() public returns (bool _success)
	{
		require(redeemable);
		address payable _from = msg.sender;
		uint256 _balance = balanceOf(_from);
		require(_balance > 0);
		_burn(_from, _balance);
		uint256 _amount = _balance * sharePrice;
		_from.transfer(_amount);
		uint256 _supply = totalSupply();
		if (_supply == 0) selfdestruct(_from);
		return true;
	}
}
