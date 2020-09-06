// Wrapper / ERC721Wrapper
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/EnumerableSet.sol";

import { SafeERC721Metadata } from "./SafeERC721Metadata.sol";
import { ERC721Shares } from "./Shares.sol";

library Wrapper
{
	using SafeERC721Metadata for IERC721Metadata;

	function create(IERC721 _target) public returns (ERC721Wrapper _wrapper)
	{
		IERC721Metadata _metadata = IERC721Metadata(address(_target));
		string memory _name = string(abi.encodePacked("Wrapped ", _metadata.safeName()));
		string memory _symbol = string(abi.encodePacked("w", _metadata.safeSymbol()));
		return new ERC721Wrapper(_name, _symbol, _target);
	}
}

contract ERC721Wrapper is Ownable, ERC721
{
	using SafeERC721Metadata for IERC721Metadata;
	using EnumerableSet for EnumerableSet.AddressSet;

	IERC721 public target;
	mapping (uint256 => ERC721Shares) public shares;
	EnumerableSet.AddressSet private history;

	constructor (string memory _name, string memory _symbol, IERC721 _target) ERC721(_name, _symbol) public
	{
		target = _target;
	}

	function securitized(uint256 _tokenId) public view returns (bool _securitized)
	{
		return shares[_tokenId] != ERC721Shares(0);
	}

	function historyLength() public view returns (uint256 _length)
	{
		return history.length();
	}

	function historyAt(uint256 _index) public view returns (ERC721Shares _shares)
	{
		return ERC721Shares(history.at(_index));
	}

	function _insert(address _from, uint256 _tokenId, bool _remnant, ERC721Shares _shares) public onlyOwner
	{
		require(shares[_tokenId] == ERC721Shares(0));
		shares[_tokenId] = _shares;
		history.add(address(_shares));
		address _holder = _remnant ? _from : address(_shares);
		_safeMint(_holder, _tokenId);
		IERC721Metadata _metadata = IERC721Metadata(address(target));
		string memory _tokenURI = _metadata.safeTokenURI(_tokenId);
		_setTokenURI(_tokenId, _tokenURI);
	}

	function _remove(address _from, uint256 _tokenId, bool _remnant) public
	{
		ERC721Shares _shares = ERC721Shares(msg.sender);
		require(shares[_tokenId] == _shares);
		shares[_tokenId] = ERC721Shares(0);
		address _holder = _remnant ? _from : address(_shares);
		require(_holder == ownerOf(_tokenId));
		_burn(_tokenId);
	}

	function _forget() public
	{
		ERC721Shares _shares = ERC721Shares(msg.sender);
		require(history.remove(address(_shares)));
	}
}
