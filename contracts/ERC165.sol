// Interface for the ERC-165 Interface Detection Standard
// https://eips.ethereum.org/EIPS/eip-165
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

interface ERC165
{
	function supportsInterface(bytes4 _interfaceId) external view returns (bool _supported);
}
