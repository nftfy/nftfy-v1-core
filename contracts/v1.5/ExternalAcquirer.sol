// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { FlashAcquireCallee, OpenCollectivePurchase } from "./OpenCollectivePurchase.sol";

contract ExternalAcquirer is FlashAcquireCallee
{
	using SafeERC20 for IERC20;
	using Address for address payable;

	address immutable public collective;
	address payable immutable public vault;

	constructor (address _collective) public
	{
		collective = _collective;
		vault = OpenCollectivePurchase(_collective).vault();
	}

	function acquire(uint256 _listingId, bool _relist, bytes calldata _data) external
	{
		OpenCollectivePurchase(collective).flashAcquire(_listingId, 0, address(this), _data);
		if (_relist) {
			OpenCollectivePurchase(collective).relist(_listingId);
		}
	}

	function flashAcquireCall(address _source, uint256 _listingId, bytes calldata _data) external override
	{
		require(msg.sender == collective, "invalid sender");
		require(_source == address(this), "invalid source");
		(address _spender, address _target, bytes memory _calldata) = abi.decode(_data, (address, address, bytes));
		(,,address _collection, uint256 _tokenId,, address _paymentToken,,,,,,,) = OpenCollectivePurchase(collective).listings(_listingId);
		if (_paymentToken == address(0)) {
			uint256 _balance = address(this).balance;
			(bool _success, bytes memory _returndata) = _target.call{value: _balance}(_calldata);
			require(_success, string(_returndata));
			_balance = address(this).balance;
			if (_balance > 0) {
				vault.sendValue(_balance);
			}
		} else {
			uint256 _balance = IERC20(_paymentToken).balanceOf(address(this));
			IERC20(_paymentToken).safeApprove(_spender, _balance);
			(bool _success, bytes memory _returndata) = _target.call(_calldata);
			require(_success, string(_returndata));
			IERC20(_paymentToken).safeApprove(_spender, 0);
			_balance = IERC20(_paymentToken).balanceOf(address(this));
			if (_balance > 0) {
				IERC20(_paymentToken).safeTransfer(vault, _balance);
			}
		}
		IERC721(_collection).approve(collective, _tokenId);
		OpenCollectivePurchase(collective).acquire(_listingId, 0);
	}

	receive() external payable
	{
	}
}
