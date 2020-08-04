// Nftfy
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

import { ERC721Shares } from "./Shares.sol";

library Wrapper
{
	function create(string memory _name, string memory _symbol, IERC721 _target) public returns (ERC721Wrapper _wrapper)
	{
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

	function _insert(address _owner, uint256 _tokenId, bool _remnant, ERC721Shares _shares) public onlyOwner
	{
		assert(shares[_tokenId] == ERC721Shares(0));
		shares[_tokenId] = _shares;
		if (_remnant) {
			_safeMint(_owner, _tokenId);
			string memory _tokenURI = IERC721Metadata(address(target)).tokenURI(_tokenId);
			_setTokenURI(_tokenId, _tokenURI);
		}
	}

	function _remove(address _owner, uint256 _tokenId, bool _remnant) public
	{
		address _shares = msg.sender;
		assert(_shares == address(shares[_tokenId]));
		shares[_tokenId] = ERC721Shares(0);
		if (_remnant) {
			require(_owner == ownerOf(_tokenId));
			_burn(_tokenId);
		}
	}
}
