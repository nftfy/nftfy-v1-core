// Interface for the ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

interface ERC20
{
	function totalSupply() external view returns (uint256 _totalSupply);
	function balanceOf(address _owner) external view returns (uint256 _balance);
	function transfer(address _to, uint256 _value) external returns (bool _success);
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
	function approve(address _spender, uint256 _value) external returns (bool _success);
	function allowance(address _owner, address _spender) external view returns (uint256 _remaining);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface ERC20Metadata
{
	function name() external view returns (string memory _name);
	function symbol() external view returns (string memory _symbol);
	function decimals() external view returns (uint8 _decimals);
}
