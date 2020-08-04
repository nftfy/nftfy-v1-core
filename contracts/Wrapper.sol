// Wrapper / ERC721Wrapper
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

import { ERC721Shares } from "./Shares.sol";

library Wrapper
{
	function create(IERC721Metadata _metadata, IERC721 _target) public returns (ERC721Wrapper _wrapper)
	{
		string memory _name = string(abi.encodePacked("Wrapped ", _metadata.name()));
		string memory _symbol = string(abi.encodePacked("w", _metadata.symbol()));
		return new ERC721Wrapper(_name, _symbol, _target);
	}
}

contract ERC721Wrapper is Ownable, ERC721
{
	IERC721 public target;
	mapping (uint256 => ERC721Shares) public shares;

	constructor (string memory _name, string memory _symbol, IERC721 _target) ERC721(_name, _symbol) public
	{
		target = _target;
	}

	function _insert(address _from, uint256 _tokenId, bool _remnant, ERC721Shares _shares) public onlyOwner
	{
		require(shares[_tokenId] == ERC721Shares(0));
		shares[_tokenId] = _shares;
		if (_remnant) {
			_safeMint(_from, _tokenId);
			IERC721Metadata _metadata = IERC721Metadata(address(target));
			string memory _tokenURI = _metadata.tokenURI(_tokenId);
			_setTokenURI(_tokenId, _tokenURI);
		}
		emit Securitize(_from, _tokenId, address(_shares));
	}

	function _remove(address _from, uint256 _tokenId, bool _remnant) public
	{
		ERC721Shares _shares = ERC721Shares(msg.sender);
		assert(shares[_tokenId] == _shares);
		shares[_tokenId] = ERC721Shares(0);
		if (_remnant) {
			address _owner = ownerOf(_tokenId);
			require(_from == _owner);
			_burn(_tokenId);
		}
		emit Redeem(_from, _tokenId, address(_shares));
	}

	event Securitize(address indexed _from, uint256 indexed _tokenId, address indexed _shares);
	event Redeem(address indexed _from, uint256 indexed _tokenId, address indexed _shares);
}
