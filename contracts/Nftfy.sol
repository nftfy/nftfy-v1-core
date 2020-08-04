// Nftfy
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Nftfy
{
	mapping (IERC721 => ERC721Wrapper) wrappers;
	mapping (IERC721 => bool) wraps;

	function getWrapper(IERC721 _target) public view returns (ERC721Wrapper _wrapper)
	{
		return wrappers[_target];
	}

	function securitize(IERC721 _target, uint256 _tokenId, uint256 _shareCount, uint8 _decimals, uint256 _price, IERC20 _paymentToken, bool _remnant) public
	{
		address _from = msg.sender;
		require(!wraps[_target]);
		ERC721Wrapper _wrapper = wrappers[_target];
		if (_wrapper == ERC721Wrapper(0)) {
			_wrapper = new ERC721Wrapper(_target);
			wrappers[_target] = _wrapper;
			wraps[_wrapper] = true;
		}
		ERC721Shares _shares = new ERC721Shares(_wrapper, _tokenId, _from, _shareCount, _decimals, _price, _paymentToken, _remnant);
		if (_remnant) _wrapper._insert(_from, _tokenId, _shares);
		_target.safeTransferFrom(_from, address(_shares), _tokenId);
	}
}

contract ERC721Wrapper is Ownable, ERC721
{
	IERC721 target;
	mapping (uint256 => ERC721Shares) shares;

	function n(IERC721 _target) internal view returns (string memory _name)
	{
		return string(abi.encodePacked("Wrapped ", IERC721Metadata(address(_target)).name()));
	}

	function s(IERC721 _target) internal view returns (string memory _symbol)
	{
		return string(abi.encodePacked("w", IERC721Metadata(address(_target)).symbol()));
	}

	constructor (IERC721 _target) ERC721(n(_target), s(_target)) public
	{
		target = _target;
	}

	function getTarget() public view returns (IERC721 _target)
	{
		return target;
	}

	function getShares(uint256 _tokenId) public view returns (ERC721Shares _shares)
	{
		return shares[_tokenId];
	}

	function _insert(address _owner, uint256 _tokenId, ERC721Shares _shares) public onlyOwner
	{
		assert(shares[_tokenId] == ERC721Shares(0));
		shares[_tokenId] = _shares;
		_safeMint(_owner, _tokenId);
		string memory _tokenURI = IERC721Metadata(address(target)).tokenURI(_tokenId);
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
	using Strings for uint256;
	using SafeERC20 for IERC20;

	ERC721Wrapper wrapper;
	uint256 tokenId;
	uint256 shareCount;
	uint256 sharePrice;
	IERC20 paymentToken;
	bool remnant;
	bool claimable;

	function getName(ERC721Wrapper _wrapper, uint256 _tokenId) internal view returns (string memory _name)
	{
		address _target = address(_wrapper.getTarget());
		return string(abi.encodePacked(IERC721Metadata(_target).name(), " #", _tokenId.toString(), " Shares"));
	}

	function getSymbol(ERC721Wrapper _wrapper, uint256 _tokenId) internal view returns (string memory _symbol)
	{
		address _target = address(_wrapper.getTarget());
		return string(abi.encodePacked(IERC721Metadata(_target).symbol(), _tokenId.toString()));
	}

	constructor (ERC721Wrapper _wrapper, uint256 _tokenId, address _owner, uint256 _shareCount, uint8 _decimals, uint256 _exitPrice, IERC20 _paymentToken, bool _remnant) ERC20(getName(_wrapper, _tokenId), getSymbol(_wrapper, _tokenId)) public
	{
		require(_exitPrice % _shareCount == 0, "exitPrice must be divisible by shareCount");
		wrapper = _wrapper;
		tokenId = _tokenId;
		shareCount = _shareCount;
		sharePrice = _exitPrice / _shareCount;
		paymentToken = _paymentToken;
		remnant = _remnant;
		claimable = false;
		_setupDecimals(_decimals);
		_mint(_owner, _shareCount);
	}

	function getWrapper() public view returns (ERC721Wrapper _wrapper)
	{
		return wrapper;
	}

	function getTokenId() public view returns (uint256 _tokenId)
	{
		return tokenId;
	}

	function getShareCount() public view returns (uint256 _shareCount)
	{
		return shareCount;
	}

	function getExitPrice() public view returns (uint256 _exitPrice)
	{
		return shareCount * sharePrice;
	}

	function getSharePrice() public view returns (uint256 _sharePrice)
	{
		return sharePrice;
	}

	function getPaymentToken() public view returns (IERC20 _paymentToken)
	{
		return paymentToken;
	}

	function isClaimable() public view returns (bool _redeemable)
	{
		return claimable;
	}

	function redeem() public payable
	{
		require(!claimable);
		address payable _from = msg.sender;
		uint256 _shares = shareCount;
		uint256 _price = sharePrice * _shares;
		uint256 _balance = balanceOf(_from);
		uint256 _value2 = sharePrice * _balance;
		if (paymentToken == IERC20(0)) {
			uint256 _value1 = msg.value;
			uint256 _total = _value1 + _value2;
			require(_total >= _price);
			uint256 _change = _total - _price;
			if (_change > 0) _from.transfer(_change);
		} else {
			uint256 _value1 = _price - _value2;
			if (_value1 > 0) paymentToken.safeTransferFrom(_from, address(this), _value1);
		}
		claimable = true;
		_burn(_from, _balance);
		if (remnant) wrapper._remove(_from, tokenId);
		wrapper.getTarget().safeTransferFrom(address(this), _from, tokenId);
		uint256 _supply = totalSupply();
		if (_supply == 0) selfdestruct(_from);
	}

	function claim() public
	{
		require(claimable);
		address payable _from = msg.sender;
		uint256 _balance = balanceOf(_from);
		require(_balance > 0);
		_burn(_from, _balance);
		uint256 _amount = _balance * sharePrice;
		if (paymentToken == IERC20(0)) _from.transfer(_amount);
		else paymentToken.safeTransfer(_from, _amount);
		uint256 _supply = totalSupply();
		if (_supply == 0) selfdestruct(_from);
	}
}
