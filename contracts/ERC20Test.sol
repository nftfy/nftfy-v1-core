// Blockies
pragma solidity >=0.4.25 <0.7.0;

import "./ERC20Base.sol";

contract ERC20Test is ERC20Metadata, ERC20Base
{
	function name() public view returns (string memory _name)
	{
		return "ERC-20 Test";
	}

	function symbol() public view returns (string memory _symbol)
	{
		return "TEST";
	}

	function decimals() public view returns (uint8 _decimals)
	{
		return 2;
	}

	constructor (address _owner, uint256 _supply) public
	{
		supply = _supply;
		balances[_owner] = _supply;
	}
}
