// Nftfy
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Nftfy is IERC721Receiver
{
	uint256 constant DEFAULT_SHARE_COUNT = 1 * 10**6;
	uint8 constant DEFAULT_SHARE_DECIMALS = 0;

	mapping (address => ERC721Wrapper) wrappers;
	mapping (address => bool) wraps;

	function getWrapper(address _target) public view returns (ERC721Wrapper _wrapper)
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
		ERC721Wrapper _wrapper = wrappers[_target];
		if (_wrapper == ERC721Wrapper(0)) {
			_wrapper = new ERC721Wrapper(address(this), _target);
			wrappers[_target] = _wrapper;
			wraps[address(_wrapper)] = true;
		}
		ERC721Shares _shares = new ERC721Shares(_wrapper, _tokenId, _from, DEFAULT_SHARE_COUNT, DEFAULT_SHARE_DECIMALS, _price);
		string memory _tokenURI = IERC721Metadata(_target).tokenURI(_tokenId);
		_wrapper._insert(_from, _tokenId, _tokenURI, _shares);
		IERC721(_target).safeTransferFrom(address(this), address(_shares), _tokenId);
		return this.onERC721Received.selector;
	}
}

contract ERC721Wrapper is ERC721
{
	address admin;
	address target;
	mapping (uint256 => ERC721Shares) shares;

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

	function getShares(uint256 _tokenId) public view returns (ERC721Shares _shares)
	{
		return shares[_tokenId];
	}

	function _insert(address _owner, uint256 _tokenId, string memory _tokenURI, ERC721Shares _shares) public
	{
		address _admin = msg.sender;
		require(_admin == admin);
		assert(shares[_tokenId] == ERC721Shares(0));
		shares[_tokenId] = _shares;
		_safeMint(_owner, _tokenId);
		_setTokenURI(_tokenId, _tokenURI);
	}

	function _remove(address _owner, uint256 _tokenId) public
	{
		address _shares = msg.sender;
		require(_shares == address(shares[_tokenId]));
		shares[_tokenId] = ERC721Shares(0);
		require(_owner == ownerOf(_tokenId));
		_burn(_tokenId);
	}
}

contract ERC721Shares is ERC721Holder, ERC20
{
	ERC721Wrapper wrapper;
	uint256 tokenId;
	uint256 shareCount;
	uint256 sharePrice;
	bool claimable;

	function getName(ERC721Wrapper _wrapper, uint256 _tokenId) internal view returns (string memory _name)
	{
		address _target = address(_wrapper.getTarget());
		return string(abi.encodePacked(IERC721Metadata(_target).name(), " #", Strings.toString(_tokenId), " Shares"));
	}

	function getSymbol(ERC721Wrapper _wrapper, uint256 _tokenId) internal view returns (string memory _symbol)
	{
		address _target = address(_wrapper.getTarget());
		return string(abi.encodePacked(IERC721Metadata(_target).symbol(), Strings.toString(_tokenId)));
	}

	constructor (ERC721Wrapper _wrapper, uint256 _tokenId, address _owner, uint256 _shares, uint8 _decimals, uint256 _price) ERC20(getName(_wrapper, _tokenId), getSymbol(_wrapper, _tokenId)) public
	{
		require(_price % _shares == 0);
		wrapper = _wrapper;
		tokenId = _tokenId;
		shareCount = _shares;
		sharePrice = _price / _shares;
		claimable = false;
		_mint(_owner, _shares);
		_setupDecimals(_decimals);
	}

	function getWrapper() public view returns (ERC721Wrapper _wrapper)
	{
		return wrapper;
	}

	function getTokenId() public view returns (uint256 _tokenId)
	{
		return tokenId;
	}

	function getExitPrice() public view returns (uint256 _exitPrice)
	{
		return shareCount * sharePrice;
	}

	function getSharePrice() public view returns (uint256 _sharePrice)
	{
		return sharePrice;
	}

	function isClaimable() public view returns (bool _redeemable)
	{
		return claimable;
	}

	function redeem() public payable returns (bool _success)
	{
		require(!claimable);
		address payable _from = msg.sender;
		uint256 _balance = balanceOf(_from);
		uint256 _shares = shareCount;
		uint256 _value1 = msg.value;
		uint256 _value2 = sharePrice * _balance;
		uint256 _price = sharePrice * _shares;
		uint256 _total = _value1 + _value2;
		require(_total >= _price);
		uint256 _change = _total - _price;
		claimable = true;
		_burn(_from, _balance);
		wrapper._remove(_from, tokenId);
		wrapper.getTarget().safeTransferFrom(address(this), _from, tokenId);
		if (_change > 0) _from.transfer(_change);
		uint256 _supply = totalSupply();
		if (_supply == 0) selfdestruct(_from);
		return true;
	}

	function claim() public returns (bool _success)
	{
		require(claimable);
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
