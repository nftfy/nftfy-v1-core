// NFY
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract NFY is ERC20
{
	address public distribution;

	constructor () ERC20("Nftfy", "NFY") public
	{
		_setupDecimals(18);
	}

	function setDistribution(address _distribution, uint256 _totalSupply) public
	{
		require(distribution == address(0), "distribution already set");
		_mint(_distribution, _totalSupply);
		distribution = _distribution;
	}
}

contract Distribution is AccessControl
{
	using SafeERC20 for IERC20;

	uint256 constant _2020_09_29 = 1601337600;
	uint256 constant _2020_12_01 = _2020_09_29 + 9 weeks;

	uint256 constant _1ST_YEAR_DAYS = 365;
	uint256 constant _2ND_YEAR_DAYS = 365;
	uint256 constant _3RD_YEAR_DAYS = 365;
	uint256 constant _4TH_YEAR_DAYS = 366;
	uint256 constant _5TH_YEAR_DAYS = 365;

	uint256 constant MINING_QUOTA = 200000000e18; // 200 mi

	uint256 constant TREASURY_QUOTA_1ST_YEAR = 160000000e18; // 160 mi
	uint256 constant TREASURY_QUOTA_2ND_YEAR = 100000000e18; // 100 mi
	uint256 constant TREASURY_QUOTA_3RD_YEAR = 80000000e18; // 80 mi
	uint256 constant TREASURY_QUOTA_4TH_YEAR = 40000000e18; // 40 mi
	uint256 constant TREASURY_QUOTA_5TH_YEAR = 20000000e18; // 20 mi
	uint256 constant TREASURY_STARTING_DATE = 2020_12_01;
	uint256 constant TREASURY_QUOTA_1ST_YEAR_PER_DAY = TREASURY_QUOTA_1ST_YEAR / _1ST_YEAR_DAYS;
	uint256 constant TREASURY_QUOTA_2ND_YEAR_PER_DAY = TREASURY_QUOTA_2ND_YEAR / _2ND_YEAR_DAYS;
	uint256 constant TREASURY_QUOTA_3RD_YEAR_PER_DAY = TREASURY_QUOTA_3RD_YEAR / _3RD_YEAR_DAYS;
	uint256 constant TREASURY_QUOTA_4TH_YEAR_PER_DAY = TREASURY_QUOTA_4TH_YEAR / _4TH_YEAR_DAYS;
	uint256 constant TREASURY_QUOTA_5TH_YEAR_PER_DAY = TREASURY_QUOTA_5TH_YEAR / _5TH_YEAR_DAYS;
	uint256 constant TREASURY_QUOTA =
		TREASURY_QUOTA_1ST_YEAR +
		TREASURY_QUOTA_2ND_YEAR +
		TREASURY_QUOTA_3RD_YEAR +
		TREASURY_QUOTA_4TH_YEAR +
		TREASURY_QUOTA_5TH_YEAR;

	uint256 constant USERS_QUOTA = 10080000e18; // 10,08 mi
	uint256 constant USERS_WEEKS = 48;
	uint256 constant USERS_QUOTA_PER_WEEK = USERS_QUOTA / USERS_WEEKS;
	uint256 constant USERS_QUOTA_PER_DAY = USERS_QUOTA_PER_WEEK / 7;

	uint256 constant AIRDROP_QUOTA = 39920000e18; // 39,92 mi

	uint256 constant ECOSYSTEM_QUOTA_1ST_YEAR = 20000000e18; // 20 mi
	uint256 constant ECOSYSTEM_QUOTA_2ND_YEAR = 12500000e18; // 12,5 mi
	uint256 constant ECOSYSTEM_QUOTA_3RD_YEAR = 10000000e18; // 10 mi
	uint256 constant ECOSYSTEM_QUOTA_4TH_YEAR = 5000000e18; // 5 mi
	uint256 constant ECOSYSTEM_QUOTA_5TH_YEAR = 2500000e18; // 2,5 mi
	uint256 constant ECOSYSTEM_STARTING_DATE = _2020_09_29;
	uint256 constant ECOSYSTEM_QUOTA_1ST_YEAR_PER_DAY = ECOSYSTEM_QUOTA_1ST_YEAR / _1ST_YEAR_DAYS;
	uint256 constant ECOSYSTEM_QUOTA_2ND_YEAR_PER_DAY = ECOSYSTEM_QUOTA_2ND_YEAR / _2ND_YEAR_DAYS;
	uint256 constant ECOSYSTEM_QUOTA_3RD_YEAR_PER_DAY = ECOSYSTEM_QUOTA_3RD_YEAR / _3RD_YEAR_DAYS;
	uint256 constant ECOSYSTEM_QUOTA_4TH_YEAR_PER_DAY = ECOSYSTEM_QUOTA_4TH_YEAR / _4TH_YEAR_DAYS;
	uint256 constant ECOSYSTEM_QUOTA_5TH_YEAR_PER_DAY = ECOSYSTEM_QUOTA_5TH_YEAR / _5TH_YEAR_DAYS;
	uint256 constant ECOSYSTEM_QUOTA =
		ECOSYSTEM_QUOTA_1ST_YEAR +
		ECOSYSTEM_QUOTA_2ND_YEAR +
		ECOSYSTEM_QUOTA_3RD_YEAR +
		ECOSYSTEM_QUOTA_4TH_YEAR +
		ECOSYSTEM_QUOTA_5TH_YEAR;

	uint256 constant INVESTORS_QUOTA_1ST_YEAR = 20000000e18; // 20 mi
	uint256 constant INVESTORS_QUOTA_2ND_YEAR = 12500000e18; // 12,5 mi
	uint256 constant INVESTORS_QUOTA_3RD_YEAR = 10000000e18; // 10 mi
	uint256 constant INVESTORS_QUOTA_4TH_YEAR = 5000000e18; // 5 mi
	uint256 constant INVESTORS_QUOTA_5TH_YEAR = 2500000e18; // 2,5 mi
	uint256 constant INVESTORS_STARTING_DATE = _2020_09_29;
	uint256 constant INVESTORS_QUOTA_1ST_YEAR_PER_DAY = INVESTORS_QUOTA_1ST_YEAR / _1ST_YEAR_DAYS;
	uint256 constant INVESTORS_QUOTA_2ND_YEAR_PER_DAY = INVESTORS_QUOTA_2ND_YEAR / _2ND_YEAR_DAYS;
	uint256 constant INVESTORS_QUOTA_3RD_YEAR_PER_DAY = INVESTORS_QUOTA_3RD_YEAR / _3RD_YEAR_DAYS;
	uint256 constant INVESTORS_QUOTA_4TH_YEAR_PER_DAY = INVESTORS_QUOTA_4TH_YEAR / _4TH_YEAR_DAYS;
	uint256 constant INVESTORS_QUOTA_5TH_YEAR_PER_DAY = INVESTORS_QUOTA_5TH_YEAR / _5TH_YEAR_DAYS;
	uint256 constant INVESTORS_QUOTA =
		INVESTORS_QUOTA_1ST_YEAR +
		INVESTORS_QUOTA_2ND_YEAR +
		INVESTORS_QUOTA_3RD_YEAR +
		INVESTORS_QUOTA_4TH_YEAR +
		INVESTORS_QUOTA_5TH_YEAR;

	uint256 constant VESTING_QUOTA_1ST_YEAR = 10000000e18; // 10 mi
	uint256 constant VESTING_QUOTA_2ND_YEAR = 6250000e18; // 6,25 mi
	uint256 constant VESTING_QUOTA_3RD_YEAR = 5000000e18; // 5 mi
	uint256 constant VESTING_QUOTA_4TH_YEAR = 2500000e18; // 2,5 mi
	uint256 constant VESTING_QUOTA_5TH_YEAR = 1250000e18; // 1,25 mi
	uint256 constant VESTING_STARTING_DATE = _2020_09_29;
	uint256 constant VESTING_QUOTA_1ST_YEAR_PER_DAY = VESTING_QUOTA_1ST_YEAR / _1ST_YEAR_DAYS;
	uint256 constant VESTING_QUOTA_2ND_YEAR_PER_DAY = VESTING_QUOTA_2ND_YEAR / _2ND_YEAR_DAYS;
	uint256 constant VESTING_QUOTA_3RD_YEAR_PER_DAY = VESTING_QUOTA_3RD_YEAR / _3RD_YEAR_DAYS;
	uint256 constant VESTING_QUOTA_4TH_YEAR_PER_DAY = VESTING_QUOTA_4TH_YEAR / _4TH_YEAR_DAYS;
	uint256 constant VESTING_QUOTA_5TH_YEAR_PER_DAY = VESTING_QUOTA_5TH_YEAR / _5TH_YEAR_DAYS;
	uint256 constant VESTING_QUOTA =
		VESTING_QUOTA_1ST_YEAR +
		VESTING_QUOTA_2ND_YEAR +
		VESTING_QUOTA_3RD_YEAR +
		VESTING_QUOTA_4TH_YEAR +
		VESTING_QUOTA_5TH_YEAR;

	uint256 constant CORE_QUOTA_1ST_YEAR = 90000000e18; // 90 mi
	uint256 constant CORE_QUOTA_2ND_YEAR = 56250000e18; // 56,25 mi
	uint256 constant CORE_QUOTA_3RD_YEAR = 45000000e18; // 45 mi
	uint256 constant CORE_QUOTA_4TH_YEAR = 22500000e18; // 22,5 mi
	uint256 constant CORE_QUOTA_5TH_YEAR = 11250000e18; // 11,25 mi
	uint256 constant CORE_STARTING_DATE = _2020_09_29;
	uint256 constant CORE_QUOTA_1ST_YEAR_PER_DAY = CORE_QUOTA_1ST_YEAR / _1ST_YEAR_DAYS;
	uint256 constant CORE_QUOTA_2ND_YEAR_PER_DAY = CORE_QUOTA_2ND_YEAR / _2ND_YEAR_DAYS;
	uint256 constant CORE_QUOTA_3RD_YEAR_PER_DAY = CORE_QUOTA_3RD_YEAR / _3RD_YEAR_DAYS;
	uint256 constant CORE_QUOTA_4TH_YEAR_PER_DAY = CORE_QUOTA_4TH_YEAR / _4TH_YEAR_DAYS;
	uint256 constant CORE_QUOTA_5TH_YEAR_PER_DAY = CORE_QUOTA_5TH_YEAR / _5TH_YEAR_DAYS;
	uint256 constant CORE_QUOTA =
		CORE_QUOTA_1ST_YEAR +
		CORE_QUOTA_2ND_YEAR +
		CORE_QUOTA_3RD_YEAR +
		CORE_QUOTA_4TH_YEAR +
		CORE_QUOTA_5TH_YEAR;

	uint256 constant TOTAL_SUPPLY =
		MINING_QUOTA +
		TREASURY_QUOTA +
		USERS_QUOTA +
		AIRDROP_QUOTA +
		ECOSYSTEM_QUOTA +
		INVESTORS_QUOTA +
		VESTING_QUOTA +
		CORE_QUOTA;

	bytes32 public constant DISTRIBUTION_MANAGER = keccak256("DISTRIBUTION_MANAGER");
	bytes32 public constant MINING_MANAGER = keccak256("MINING_MANAGER");
	bytes32 public constant TREASURY_MANAGER = keccak256("TREASURY_MANAGER");
	bytes32 public constant USERS_MANAGER = keccak256("USERS_MANAGER");
	bytes32 public constant AIRDROP_MANAGER = keccak256("AIRDROP_MANAGER");
	bytes32 public constant ECOSYSTEM_MANAGER = keccak256("ECOSYSTEM_MANAGER");
	bytes32 public constant INVESTORS_MANAGER = keccak256("INVESTORS_MANAGER");
	bytes32 public constant VESTING_MANAGER = keccak256("VESTING_MANAGER");
	bytes32 public constant CORE_MANAGER = keccak256("CORE_MANAGER");

	address immutable public token;

	uint256 public miningLocked = MINING_QUOTA;
	uint256 public treasuryLocked = TREASURY_QUOTA;
	uint256 public usersLocked = USERS_QUOTA;
	uint256 public airdropLocked = AIRDROP_QUOTA;
	uint256 public ecosystemLocked = ECOSYSTEM_QUOTA;
	uint256 public investorsLocked = INVESTORS_QUOTA;
	uint256 public vestingLocked = VESTING_QUOTA;
	uint256 public coreLocked = CORE_QUOTA;

	address public miningWallet;
	address public treasuryWallet;
	address public usersWallet;
	address public airdropWallet;
	address public ecosystemWallet;
	address public investorsWallet;
	address public vestingWallet;
	address public coreWallet;

	uint256 public lastDistributionDay = _2020_09_29;

	modifier onlyRole(bytes32 _role)
	{
		require(hasRole(_role, _msgSender()), "access denied");
		_;
	}

	constructor (address _token) public
	{
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		token = _token;
		NFY(_token).setDistribution(address(this), TOTAL_SUPPLY);
	}

	function calcDays(uint256 _startingDay, uint256 _baseDay, uint256 _days) internal pure returns (uint256 _1stYearDays, uint256 _2ndYearDays, uint256 _3rdYearDays, uint256 _4thYearDays, uint256 _5thYearDays)
	{
		if (_baseDay < _startingDay) {
			uint256 _waitDays = Math.min(_days, (_startingDay - _baseDay) / 1 days);
			_days -= _waitDays;
			_baseDay = _startingDay;
		}
		uint256 _1stYearEndingDay = _startingDay + _1ST_YEAR_DAYS * 1 days;
		if (_baseDay < _1stYearEndingDay) {
			_1stYearDays = Math.min(_days, (_1stYearEndingDay - _baseDay) / 1 days);
			_days -= _1stYearDays;
			_baseDay = _1stYearEndingDay;
		}
		uint256 _2ndYearEndingDay = _1stYearEndingDay + _2ND_YEAR_DAYS * 1 days;
		if (_baseDay < _2ndYearEndingDay) {
			_2ndYearDays = Math.min(_days, (_2ndYearEndingDay - _baseDay) / 1 days);
			_days -= _2ndYearDays;
			_baseDay = _2ndYearEndingDay;
		}
		uint256 _3rdYearEndingDay = _2ndYearEndingDay + _3RD_YEAR_DAYS * 1 days;
		if (_baseDay < _3rdYearEndingDay) {
			_3rdYearDays = Math.min(_days, (_3rdYearEndingDay - _baseDay) / 1 days);
			_days -= _3rdYearDays;
			_baseDay = _3rdYearEndingDay;
		}
		uint256 _4thYearEndingDay = _3rdYearEndingDay + _4TH_YEAR_DAYS * 1 days;
		if (_baseDay < _4thYearEndingDay) {
			_4thYearDays = Math.min(_days, (_4thYearEndingDay - _baseDay) / 1 days);
			_days -= _4thYearDays;
			_baseDay = _4thYearEndingDay;
		}
		uint256 _5thYearEndingDay = _4thYearEndingDay + _5TH_YEAR_DAYS * 1 days;
		if (_baseDay < _5thYearEndingDay) {
			_5thYearDays = Math.min(_days, (_5thYearEndingDay - _baseDay) / 1 days);
			_days -= _5thYearDays;
			_baseDay = _5thYearEndingDay;
		}
		return (_1stYearDays, _2ndYearDays, _3rdYearDays, _4thYearDays, _5thYearDays);
	}

	function calcMiningAmount(uint256 /* _baseDay */, uint256 /* _days */) public pure returns (uint256 _miningAmount)
	{
		return MINING_QUOTA;
	}

	function calcTreasuryAmount(uint256 _baseDay, uint256 _days) public pure returns (uint256 _treasuryAmount)
	{
		(
			uint256 _1stYearDays,
			uint256 _2ndYearDays,
			uint256 _3rdYearDays,
			uint256 _4thYearDays,
			uint256 _5thYearDays
		) = calcDays(TREASURY_STARTING_DATE, _baseDay, _days);
		return
			_1stYearDays * TREASURY_QUOTA_1ST_YEAR_PER_DAY +
			_2ndYearDays * TREASURY_QUOTA_2ND_YEAR_PER_DAY +
			_3rdYearDays * TREASURY_QUOTA_3RD_YEAR_PER_DAY +
			_4thYearDays * TREASURY_QUOTA_4TH_YEAR_PER_DAY +
			_5thYearDays * TREASURY_QUOTA_5TH_YEAR_PER_DAY;
	}

	function calcUsersAmount(uint256 /* _baseDay */, uint256 _days) public pure returns (uint256 _usersAmount)
	{
		return _days * USERS_QUOTA_PER_DAY;
	}

	function calcAirdropAmount(uint256 /* _baseDay */, uint256 /* _days */) public pure returns (uint256 _airdropAmount)
	{
		return AIRDROP_QUOTA;
	}

	function calcEcosystemAmount(uint256 _baseDay, uint256 _days) public pure returns (uint256 _ecosystemAmount)
	{
		(
			uint256 _1stYearDays,
			uint256 _2ndYearDays,
			uint256 _3rdYearDays,
			uint256 _4thYearDays,
			uint256 _5thYearDays
		) = calcDays(ECOSYSTEM_STARTING_DATE, _baseDay, _days);
		return
			_1stYearDays * ECOSYSTEM_QUOTA_1ST_YEAR_PER_DAY +
			_2ndYearDays * ECOSYSTEM_QUOTA_2ND_YEAR_PER_DAY +
			_3rdYearDays * ECOSYSTEM_QUOTA_3RD_YEAR_PER_DAY +
			_4thYearDays * ECOSYSTEM_QUOTA_4TH_YEAR_PER_DAY +
			_5thYearDays * ECOSYSTEM_QUOTA_5TH_YEAR_PER_DAY;
	}

	function calcInvestorsAmount(uint256 _baseDay, uint256 _days) public pure returns (uint256 _investorsAmount)
	{
		(
			uint256 _1stYearDays,
			uint256 _2ndYearDays,
			uint256 _3rdYearDays,
			uint256 _4thYearDays,
			uint256 _5thYearDays
		) = calcDays(INVESTORS_STARTING_DATE, _baseDay, _days);
		return
			_1stYearDays * INVESTORS_QUOTA_1ST_YEAR_PER_DAY +
			_2ndYearDays * INVESTORS_QUOTA_2ND_YEAR_PER_DAY +
			_3rdYearDays * INVESTORS_QUOTA_3RD_YEAR_PER_DAY +
			_4thYearDays * INVESTORS_QUOTA_4TH_YEAR_PER_DAY +
			_5thYearDays * INVESTORS_QUOTA_5TH_YEAR_PER_DAY;
	}

	function calcVestingAmount(uint256 _baseDay, uint256 _days) public pure returns (uint256 _vestingAmount)
	{
		(
			uint256 _1stYearDays,
			uint256 _2ndYearDays,
			uint256 _3rdYearDays,
			uint256 _4thYearDays,
			uint256 _5thYearDays
		) = calcDays(VESTING_STARTING_DATE, _baseDay, _days);
		return
			_1stYearDays * VESTING_QUOTA_1ST_YEAR_PER_DAY +
			_2ndYearDays * VESTING_QUOTA_2ND_YEAR_PER_DAY +
			_3rdYearDays * VESTING_QUOTA_3RD_YEAR_PER_DAY +
			_4thYearDays * VESTING_QUOTA_4TH_YEAR_PER_DAY +
			_5thYearDays * VESTING_QUOTA_5TH_YEAR_PER_DAY;
	}

	function calcCoreAmount(uint256 _baseDay, uint256 _days) public pure returns (uint256 _coreAmount)
	{
		(
			uint256 _1stYearDays,
			uint256 _2ndYearDays,
			uint256 _3rdYearDays,
			uint256 _4thYearDays,
			uint256 _5thYearDays
		) = calcDays(CORE_STARTING_DATE, _baseDay, _days);
		return
			_1stYearDays * CORE_QUOTA_1ST_YEAR_PER_DAY +
			_2ndYearDays * CORE_QUOTA_2ND_YEAR_PER_DAY +
			_3rdYearDays * CORE_QUOTA_3RD_YEAR_PER_DAY +
			_4thYearDays * CORE_QUOTA_4TH_YEAR_PER_DAY +
			_5thYearDays * CORE_QUOTA_5TH_YEAR_PER_DAY;
	}

	function distribute() public onlyRole(DISTRIBUTION_MANAGER)
	{
		require(now >= lastDistributionDay + 1 weeks);
		uint256 _weeks = (now - lastDistributionDay) / 1 weeks;
		assert(_weeks >= 1);
		uint256 _distributionDay = lastDistributionDay + _weeks * 1 weeks;
		require(treasuryWallet != address(0) || _distributionDay <= TREASURY_STARTING_DATE, "treasury wallet not set");
		require(ecosystemWallet != address(0), "ecosystem wallet not set");
		require(investorsWallet != address(0), "investors wallet not set");
		require(vestingWallet != address(0), "vesting wallet not set");
		require(coreWallet != address(0), "core wallet not set");
		uint256 _days = _weeks * 7;
		transferMining(calcMiningAmount(lastDistributionDay, _days));
		transferTreasury(calcTreasuryAmount(lastDistributionDay, _days));
		transferUsers(calcUsersAmount(lastDistributionDay, _days));
		transferAirdrop(calcAirdropAmount(lastDistributionDay, _days));
		transferEcosystem(calcEcosystemAmount(lastDistributionDay, _days));
		transferInvestors(calcInvestorsAmount(lastDistributionDay, _days));
		transferVesting(calcVestingAmount(lastDistributionDay, _days));
		transferCore(calcCoreAmount(lastDistributionDay, _days));
		lastDistributionDay = _distributionDay;
	}

	function setMiningWallet(address _miningWallet) public onlyRole(MINING_MANAGER) { miningWallet = _miningWallet; }
	function setTreasuryWallet(address _treasuryWallet) public onlyRole(TREASURY_MANAGER) { treasuryWallet = _treasuryWallet; }
	function setUsersWallet(address _usersWallet) public onlyRole(USERS_MANAGER) { usersWallet = _usersWallet; }
	function setAirdropWallet(address _airdropWallet) public onlyRole(AIRDROP_MANAGER) { airdropWallet = _airdropWallet; }
	function setEcosystemWallet(address _ecosystemWallet) public onlyRole(ECOSYSTEM_MANAGER) { ecosystemWallet = _ecosystemWallet; }
	function setInvestorsWallet(address _investorsWallet) public onlyRole(INVESTORS_MANAGER) { investorsWallet = _investorsWallet; }
	function setVestingWallet(address _vestingWallet) public onlyRole(VESTING_MANAGER) { vestingWallet = _vestingWallet; }
	function setCoreWallet(address _coreWallet) public onlyRole(CORE_MANAGER) { coreWallet = _coreWallet; }

	function transferMining(uint256 _miningAmount) internal
	{
		if (miningWallet == address(0)) return;
		_miningAmount = Math.min(miningLocked, _miningAmount);
		if (_miningAmount == 0) return;
		miningLocked -= _miningAmount;
		IERC20(token).safeTransfer(miningWallet, _miningAmount);
	}

	function transferTreasury(uint256 _treasuryAmount) internal
	{
		if (treasuryWallet == address(0)) return;
		_treasuryAmount = Math.min(treasuryLocked, _treasuryAmount);
		if (_treasuryAmount == 0) return;
		treasuryLocked -= _treasuryAmount;
		IERC20(token).safeTransfer(treasuryWallet, _treasuryAmount);
	}

	function transferUsers(uint256 _usersAmount) internal
	{
		if (usersWallet == address(0)) return;
		_usersAmount = Math.min(usersLocked, _usersAmount);
		if (_usersAmount == 0) return;
		usersLocked -= _usersAmount;
		IERC20(token).safeTransfer(usersWallet, _usersAmount);
	}

	function transferAirdrop(uint256 _airdropAmount) internal
	{
		if (airdropWallet == address(0)) return;
		_airdropAmount = Math.min(airdropLocked, _airdropAmount);
		if (_airdropAmount == 0) return;
		airdropLocked -= _airdropAmount;
		IERC20(token).safeTransfer(airdropWallet, _airdropAmount);
	}

	function transferEcosystem(uint256 _ecosystemAmount) internal
	{
		if (ecosystemWallet == address(0)) return;
		_ecosystemAmount = Math.min(ecosystemLocked, _ecosystemAmount);
		if (_ecosystemAmount == 0) return;
		ecosystemLocked -= _ecosystemAmount;
		IERC20(token).safeTransfer(ecosystemWallet, _ecosystemAmount);
	}

	function transferInvestors(uint256 _investorsAmount) internal
	{
		if (investorsWallet == address(0)) return;
		_investorsAmount = Math.min(investorsLocked, _investorsAmount);
		if (_investorsAmount == 0) return;
		investorsLocked -= _investorsAmount;
		IERC20(token).safeTransfer(investorsWallet, _investorsAmount);
	}

	function transferVesting(uint256 _vestingAmount) internal
	{
		if (vestingWallet == address(0)) return;
		_vestingAmount = Math.min(vestingLocked, _vestingAmount);
		if (_vestingAmount == 0) return;
		vestingLocked -= _vestingAmount;
		IERC20(token).safeTransfer(vestingWallet, _vestingAmount);
	}

	function transferCore(uint256 _coreAmount) internal
	{
		if (coreWallet == address(0)) return;
		_coreAmount = Math.min(coreLocked, _coreAmount);
		if (_coreAmount == 0) return;
		coreLocked -= _coreAmount;
		IERC20(token).safeTransfer(coreWallet, _coreAmount);
	}
}
