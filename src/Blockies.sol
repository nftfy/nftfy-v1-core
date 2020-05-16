// Blockies
pragma solidity >= 0.4.20;

import "./ERC721Base.sol";

contract Blockies is ERC721Metadata, ERC721Base
{
	string constant BASE_URL = "https://blockie.cc";

	function name() public view returns (string memory _name)
	{
		return "Blockies V1";
	}

	function symbol() public view returns (string memory _symbol)
	{
		return "KIE";
	}

	function tokenURI(uint256 _tokenId) public view returns (string memory _tokenURI)
	{
		return string(abi.encodePacked(BASE_URL, "/address/0x", bytes32(_tokenId)));
	}

	constructor () public
	{
	}

	function issue(address _owner) public
	{
		uint256 _tokenId = uint256(_owner);
		assert(balances[_owner] + 1 > balances[_owner]);
		balances[_owner]++;
		require(owners[_tokenId] == address(0));
		owners[_tokenId] = _owner;
	}
}

