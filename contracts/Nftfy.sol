// Nftfy
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

import { Wrapper, ERC721Wrapper } from "./Wrapper.sol";
import { Shares, ERC721Shares } from "./Shares.sol";

contract Nftfy
{
	mapping (IERC721 => bool) wraps;
	mapping (IERC721 => ERC721Wrapper) public wrappers;

	function securitize(IERC721 _target, uint256 _tokenId, uint256 _shareCount, uint8 _decimals, uint256 _exitPrice, IERC20 _paymentToken, bool _remnant) public
	{
		address _from = msg.sender;
		require(!wraps[_target]);
		IERC721Metadata _metadata = IERC721Metadata(address(_target));
		ERC721Wrapper _wrapper = wrappers[_target];
		if (_wrapper == ERC721Wrapper(0)) {
			_wrapper = Wrapper.create(_metadata, _target);
			wrappers[_target] = _wrapper;
			wraps[_wrapper] = true;
		}
		require(_exitPrice % _shareCount == 0);
		uint256 _sharePrice = _exitPrice / _shareCount;
		ERC721Shares _shares = Shares.create(_metadata, _wrapper, _tokenId, _from, _shareCount, _decimals, _sharePrice, _paymentToken, _remnant);
		_wrapper._insert(_from, _tokenId, _remnant, _shares);
		_target.safeTransferFrom(_from, address(_shares), _tokenId);
	}
}
