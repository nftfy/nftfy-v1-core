// SafeERC721Metadata
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

library SafeERC721Metadata
{
	function safeName(IERC721Metadata _metadata) public view returns (string memory _name)
	{
		try _metadata.name() returns (string memory _n) {
			return _n;
		} catch (bytes memory /* _data */) {
			return "";
		}
	}

	function safeSymbol(IERC721Metadata _metadata) public view returns (string memory _symbol)
	{
		try _metadata.symbol() returns (string memory _s) {
			return _s;
		} catch (bytes memory /* _data */) {
			return "";
		}
	}

	function safeTokenURI(IERC721Metadata _metadata, uint256 _tokenId) public view returns (string memory _tokenURI)
	{
		try _metadata.tokenURI(_tokenId) returns (string memory _t) {
			return _t;
		} catch (bytes memory /* _data */) {
			return "";
		}
	}
}
