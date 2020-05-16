// Interface for the ERC-721 Token Standard
// https://eips.ethereum.org/EIPS/eip-721
pragma solidity 0.5.15;

interface ERC721
{
	function balanceOf(address _owner) external view returns (uint256 _balance);
	function ownerOf(uint256 _tokenId) external view returns (address _owner);
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable;
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
	function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
	function approve(address _approved, uint256 _tokenId) external payable;
	function setApprovalForAll(address _operator, bool _approved) external;
	function getApproved(uint256 _tokenId) external view returns (address _approved);
	function isApprovedForAll(address _owner, address _operator) external view returns (bool _approved);
	event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
	event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

interface ERC721Enumerable {
	function totalSupply() external view returns (uint256 _totalSupply);
	function tokenByIndex(uint256 _index) external view returns (uint256 _tokenId);
	function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
}

interface ERC721Metadata
{
	function name() external view returns (string memory _name);
	function symbol() external view returns (string memory _symbol);
	function tokenURI(uint256 _tokenId) external view returns (string memory _tokenURI);
}

interface ERC721Receiver
{
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4 _magic);
}
