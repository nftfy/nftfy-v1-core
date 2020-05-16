// Blockies
pragma solidity >= 0.4.20;

import "./ERC721Base.sol";
import "./ERC165.sol";

contract Blockies is ERC721Metadata, ERC721Base, ERC165
{
	bytes4 constant INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
	bytes4 constant INTERFACE_ID_ERC721 = 0x80ac58cd;
	bytes4 constant INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

	string constant BASE_URI = "https://blockie.cc";

	function name() public view returns (string memory _name)
	{
		return "Blockies";
	}

	function symbol() public view returns (string memory _symbol)
	{
		return "KIE";
	}

	function tokenURI(uint256 _tokenId) public view returns (string memory _tokenURI)
	{
		require(owners[_tokenId] != address(0));
		return string(abi.encodePacked(BASE_URI, "/address/0x", bytes32(_tokenId)));
	}

	constructor () public
	{
	}

	function issue(address _owner) public
	{
		uint256 _tokenId = uint256(_owner);
		assert(supply + 1 > supply);
		assert(tokens[address(0)][supply] == 0);
		assert(indexes[address(0)][_tokenId] == 0);
		tokens[address(0)][supply] = _tokenId;
		indexes[address(0)][_tokenId] = supply;
		supply++;
		assert(balances[_owner] + 1 > balances[_owner]);
		assert(tokens[_owner][balances[_owner]] == 0);
		assert(indexes[_owner][_tokenId] == 0);
		tokens[_owner][balances[_owner]] = _tokenId;
		indexes[_owner][_tokenId] = balances[_owner];
		balances[_owner]++;
		require(owners[_tokenId] == address(0));
		owners[_tokenId] = _owner;
	}

	function supportsInterface(bytes4 _interfaceId) public view returns (bool _supported)
	{
		return
			_interfaceId == INTERFACE_ID_ERC721_METADATA ||
			_interfaceId == INTERFACE_ID_ERC721 ||
			_interfaceId == INTERFACE_ID_ERC721_ENUMERABLE;
	}
}