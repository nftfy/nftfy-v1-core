// Base implementation for the ERC-20 Token Standard
pragma solidity 0.5.15;

import "./ERC20.sol";

contract ERC20Base is ERC20
{
	uint256 supply;
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;

	function totalSupply() public view returns (uint256 _totalSupply)
	{
		return supply;
	}

	function balanceOf(address _owner) public view returns (uint256 _balance)
	{
		return balances[_owner];
	}

	function transfer(address _to, uint256 _value) public returns (bool _success)
	{
		require(msg.data.length >= 68); // fix for short address attack
		address _from = msg.sender;
		require(_value > 0);
		require(balances[_from] >= _value);
		balances[_from] -= _value;
		assert(balances[_to] + _value > balances[_to]);
		balances[_to] += _value;
		emit Transfer(_from, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success)
	{
		address _spender = msg.sender;
		require(_value > 0);
		require(balances[_from] >= _value);
		balances[_from] -= _value;
		require(allowed[_from][_spender] >= _value);
		allowed[_from][_spender] -= _value;
		assert(balances[_to] + _value > balances[_to]);
		balances[_to] += _value;
		emit Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool _success)
	{
		address _owner = msg.sender;
		require(_value >= 0);
		allowed[_owner][_spender] = _value;
		emit Approval(_owner, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256 _remaining)
	{
		return allowed[_owner][_spender];
	}
}
