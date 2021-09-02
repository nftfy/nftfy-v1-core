// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFractions is IERC20
{
	function target() external view returns (address _target);
	function tokenId() external view returns (uint256 _tokenId);
	function fractionsCount() external view returns (uint256 _fractionsCount);
}
