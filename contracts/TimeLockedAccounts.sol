// TimeLockedAccounts
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract TimeLockedAccounts
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	address constant NFY = 0xc633BAf9fDE99800226C74328024525192294D2b;
	uint256 constant PERIOD = 30 days;

	mapping (address => uint256) public balance;

	mapping (address => uint256) baseTime;
	mapping (address => uint256) lockedPeriods;
	mapping (address => uint256) lockedPerPeriod;

	function available(address _receiver) external view returns (uint256 _amount)
	{
		(,,,_amount) = _available(_receiver);
		return _amount;
	}

	function deposit(address _receiver, uint256 _amount) external
	{
		address _sender = msg.sender;
		_deposit(_receiver, _amount);
		IERC20(NFY).safeTransferFrom(_sender, address(this), _amount);
	}

	function depositBatch(address _sender, address[] memory _receivers, uint256[] memory _amounts) external
	{
		require(_receivers.length == _amounts.length, "length mismatch");
		for (uint256 _i = 0; _i < _receivers.length; _i++) {
			_deposit(_receivers[_i], _amounts[_i]);
		}
		uint256 _totalAmount = 0;
		for (uint256 _i = 0; _i < _amounts.length; _i++) {
			_totalAmount = _totalAmount.add(_amounts[_i]);
		}
		IERC20(NFY).safeTransferFrom(_sender, address(this), _totalAmount);
	}

	function withdraw() external
	{
		address _receiver = msg.sender;
		_withdraw(_receiver);
	}

	function withdrawBatch(address[] memory _receivers) external
	{
		for (uint256 _i = 0; _i < _receivers.length; _i++) {
			_withdraw(_receivers[_i]);
		}
	}

	function _available(address _receiver) internal view returns (uint256 _newBalance, uint256 _newBaseTime, uint256 _newLockedPeriods, uint256 _amount)
	{
		uint256 _balance = balance[_receiver];
		uint256 _baseTime = baseTime[_receiver];
		uint256 _lockedPeriods = lockedPeriods[_receiver];
		uint256 _lockedPerPeriod = lockedPerPeriod[_receiver];

		uint256 _unlockedPeriods = now.sub(_baseTime).div(PERIOD);
		if (_unlockedPeriods > _lockedPeriods) _unlockedPeriods = _lockedPeriods;

		_newLockedPeriods = _lockedPeriods.sub(_unlockedPeriods);
		_newBaseTime = _baseTime.add(_unlockedPeriods.mul(PERIOD));
		_newBalance = _newLockedPeriods.mul(_lockedPerPeriod);

		_amount = _balance.sub(_newBalance);

		return (_newBalance, _newBaseTime, _newLockedPeriods, _amount);
	}

	function _deposit(address _receiver, uint256 _amount) internal
	{
		require(baseTime[_receiver] == 0, "already exists");
		require(_amount > 0, "zero amount");
		balance[_receiver] = _amount;
		baseTime[_receiver] = now;
		lockedPeriods[_receiver] = 20;
		lockedPerPeriod[_receiver] = _amount.mul(5e16).div(100e16); // 5%
	}

	function _withdraw(address _receiver) internal
	{
		(uint256 _newBalance, uint256 _newBaseTime, uint256 _newLockedPeriods, uint256 _amount) = _available(_receiver);

		require(_amount > 0, "zero balance");

		balance[_receiver] = _newBalance;
		baseTime[_receiver] = _newBaseTime;
		lockedPeriods[_receiver] = _newLockedPeriods;

		IERC20(NFY).safeTransfer(_receiver, _amount);
	}
}
