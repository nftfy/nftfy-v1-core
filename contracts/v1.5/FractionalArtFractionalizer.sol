// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { SafeERC721 } from "./SafeERC721.sol";

interface FractionalArtERC721VaultFactory
{
	function vaults(uint256 _vaultNumber) external returns (address _vault);
	function mint(string memory _name, string memory _symbol, address _token, uint256 _id, uint256 _supply, uint256 _listPrice, uint256 _fee) external returns (uint256 _vaultNumber);
}

contract FractionalArtFractionalizer is ReentrancyGuard
{
	using SafeMath for uint256;

	address constant ERC721_VAULT_FACTORY = address(0x85Aa7f78BdB2DE8F3e0c0010d99AD5853fFcfC63);

	function fractionalize(address _target, uint256 _tokenId, string memory _name, string memory _symbol, uint8 _decimals, uint256 _fractionsCount, uint256 _fractionPrice) external nonReentrant returns (address _fractions)
	{
		address _from = msg.sender;
		uint256 _listPrice = _fractionsCount.mul(_fractionPrice);
		uint256 _supply = _fractionsCount.mul(10 ** (uint256(18).sub(_decimals)));
		IERC721(_target).transferFrom(_from, address(this), _tokenId);
		IERC721(_target).approve(ERC721_VAULT_FACTORY, _tokenId);
		uint256 _vaultNumber = FractionalArtERC721VaultFactory(ERC721_VAULT_FACTORY).mint(_name, _symbol, _target, _tokenId, _supply, _listPrice, 0);
		_fractions = FractionalArtERC721VaultFactory(ERC721_VAULT_FACTORY).vaults(_vaultNumber);
		emit Fractionalize(_from, _target, _tokenId, _fractions);
		return _fractions;
	}

	event Fractionalize(address indexed _from, address indexed _target, uint256 indexed _tokenId, address _fractions);
}
