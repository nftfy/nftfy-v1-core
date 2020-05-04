// Base implementation for the ERC-721 Token Standard
pragma solidity >= 0.4.20;

import "./ERC721.sol";

contract ERC721Base is ERC721
{
	mapping (address => uint256) balances;
	mapping (uint256 => address) owners;
	mapping (uint256 => address) approvals;
	mapping (address => mapping (address => bool)) operators;

	function balanceOf(address _owner) public view returns (uint256 _balance)
	{
		return balances[_owner];
	}

	function ownerOf(uint256 _tokenId) public view returns (address _owner)
	{
		return owners[_tokenId];
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable
	{
		address _operator = msg.sender;
		transferFrom(_from, _to, _tokenId);
		uint256 _size;
		assembly { _size := extcodesize(_to) }
		if (_size > 0) {
			ERC721Receiver _receiver = ERC721Receiver(_to);
			bytes4 _magic1 = _receiver.onERC721Received(_operator, _from, _tokenId, _data);
			bytes4 _magic2 = _receiver.onERC721Received.selector;
			require(_magic1 == _magic2);
		}
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable
	{
		safeTransferFrom(_from, _to, _tokenId, "");
	}

	function transferFrom(address _from, address _to, uint256 _tokenId) public payable
	{
		address _operator = msg.sender;
		address _owner = owners[_tokenId];
		require(_operator == _owner || _operator == approvals[_tokenId] || operators[_owner][_operator]);
		require(_from == _owner);
		require(_from != address(0));
		require(_to != address(0));
		assert(balances[_from] > 0);
		balances[_from]--;
		assert(balances[_to] + 1 > balances[_to]);
		balances[_to]++;
		owners[_tokenId] = _to;
		approvals[_tokenId] = address(0);
		emit Transfer(_from, _to, _tokenId);
	}

	function approve(address _approved, uint256 _tokenId) public payable
	{
		address _operator = msg.sender;
		address _owner = owners[_tokenId];
		require(_operator == _owner || operators[_owner][_operator]);
		require(_approved != _owner);
		approvals[_tokenId] = _approved;
		emit Approval(_owner, _approved, _tokenId);
	}

	function setApprovalForAll(address _operator, bool _approved) public
	{
		address _owner = msg.sender;
		require(_operator != _owner);
		operators[_owner][_operator] = _approved;
		emit ApprovalForAll(_owner, _operator, _approved);
	}

	function getApproved(uint256 _tokenId) public view returns (address _approved)
	{
		return approvals[_tokenId];
	}

	function isApprovedForAll(address _owner, address _operator) public view returns (bool _approved)
	{
		return operators[_owner][_operator];
	}
}
