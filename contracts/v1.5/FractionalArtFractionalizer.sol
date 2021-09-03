// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { SafeERC721 } from "./SafeERC721.sol";

interface FractionalArtERC721VaultFactory
{
	function vaults(uint256 _vaultNumber) external returns (address _vault);
	function mint(string memory _name, string memory _symbol, address _token, uint256 _id, uint256 _supply, uint256 _listPrice, uint256 _fee) external returns (uint256 _vaultNumber);
}

interface FractionalArtERC721Vault
{
	function updateCurator(address _curator) external;
	function updateAuctionLength(uint256 _length) external;
}

contract FractionalArtFractionalizer is ReentrancyGuard
{
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	// Mainnet: 0x85Aa7f78BdB2DE8F3e0c0010d99AD5853fFcfC63
	// Rinkeby: 0x458556c097251f52ca89cB81316B4113aC734BD1
	address immutable vaultFactory;

	constructor (address _vaultFactory) public
	{
		vaultFactory = _vaultFactory;
	}

	function fractionalize(address _target, uint256 _tokenId, string memory _name, string memory _symbol, uint256 _fractionsCount, uint256 _fractionPrice, uint256 _duration, uint256 _fee) external nonReentrant returns (address _fractions)
	{
		address _from = msg.sender;
		IERC721(_target).transferFrom(_from, address(this), _tokenId);
		IERC721(_target).approve(vaultFactory, _tokenId);
		uint256 _vaultNumber = FractionalArtERC721VaultFactory(vaultFactory).mint(_name, _symbol, _target, _tokenId, _fractionsCount, _fractionsCount.mul(_fractionPrice), _fee / 1e15);
		_fractions = FractionalArtERC721VaultFactory(vaultFactory).vaults(_vaultNumber);
		FractionalArtERC721Vault(_fractions).updateAuctionLength(_duration);
		FractionalArtERC721Vault(_fractions).updateCurator(_from);
		IERC20(_fractions).safeTransfer(_from, IERC20(_fractions).balanceOf(address(this)));
		emit Fractionalize(_from, _target, _tokenId, _fractions);
		return _fractions;
	}

	event Fractionalize(address indexed _from, address indexed _target, uint256 indexed _tokenId, address _fractions);
}
