// Blockies
pragma solidity 0.5.15;

import "./ERC20Base.sol";
import "./ERC165.sol";

contract ERC20Test is ERC20Metadata, ERC20Base, ERC165
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
		return 18;
	}

	constructor (address _owner, uint256 _supply) public
	{
		supply = _supply;
		balances[_owner] = _supply;
	}
}
