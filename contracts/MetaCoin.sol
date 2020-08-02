// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ConvertLib.sol";

contract MetaCoin
{
	mapping (address => uint256) balances;

	constructor() public
	{
		balances[tx.origin] = 10000;
	}

	function sendCoin(address _receiver, uint256 _amount) public returns (bool _sufficient)
	{
		if (balances[msg.sender] < _amount) return false;
		balances[msg.sender] -= _amount;
		balances[_receiver] += _amount;
		emit Transfer(msg.sender, _receiver, _amount);
		return true;
	}

	function getBalanceInEth(address _addr) public view returns (uint256 _convertedBalance)
	{
		return ConvertLib.convert(getBalance(_addr), 2);
	}

	function getBalance(address _addr) public view returns (uint256 _balance)
	{
		return balances[_addr];
	}

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
}
