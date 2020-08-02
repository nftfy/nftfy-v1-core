// Interface for the ERC-165 Interface Detection Standard
// https://eips.ethereum.org/EIPS/eip-165
pragma solidity >=0.4.25 <0.7.0;

interface ERC165
{
	function supportsInterface(bytes4 _interfaceId) external view returns (bool _supported);
}
