// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { FlashAcquireCallee, OpenCollectivePurchase } from "./OpenCollectivePurchase.sol";

contract OpenSeaAcquirer is FlashAcquireCallee
{
	using SafeERC20 for IERC20;

	address immutable public collective;
	address payable immutable public vault;

	// mainnet: 0x7Be8076f4EA4A4AD08075C2508e481d6C946D12b / 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073
	// rinkeby: 0x5206e78b21Ce315ce284FB24cf05e0585A93B1d9 / 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073
	address immutable public exchange;
	address immutable public feeRecipient;
	address immutable public referral;

	address private collection_;
	uint256 private tokenId_;
	address private paymentToken_;

	address private seller_;
	uint8 private saleKind_;
	uint256 private basePrice_;
	uint256 private makerRelayerFee_;
	uint256 private listingTime_;
	uint256 private expirationTime_;
	uint256 private extra_;
	uint256 private salt_;
	uint8 private v_;
	bytes32 private r_;
	bytes32 private s_;

	uint256[75] private p_;

	constructor (address _collective, address _exchange, address _feeRecipient, address _referral) public
	{
		collective = _collective;
		vault = OpenCollectivePurchase(_collective).vault();
		exchange = _exchange;
		feeRecipient = _feeRecipient;
		referral = _referral;
	}

	function acquire(uint256 _listingId, bool _relist, bytes calldata _data, bytes calldata _sig) external
	{
		(salt_, v_, r_, s_) = abi.decode(_sig, (uint256, uint8, bytes32, bytes32));
		OpenCollectivePurchase(collective).flashAcquire(_listingId, 0, address(this), _data);
		if (_relist) {
			OpenCollectivePurchase(collective).relist(_listingId);
		}
	}

	function flashAcquireCall(address _source, uint256 _listingId, bytes calldata _data) external override
	{
		require(msg.sender == collective, "invalid sender");
		require(_source == address(this), "invalid source");
		(,, collection_, tokenId_, paymentToken_,,,,,,) = OpenCollectivePurchase(collective).listings(_listingId);
		(seller_, saleKind_, basePrice_, makerRelayerFee_, listingTime_, expirationTime_, extra_) =
			abi.decode(_data, (address, uint8, uint256, uint256, uint256, uint256, uint256));
		if (paymentToken_ == address(0)) {
			uint256 _price = address(this).balance;
			_acquire(_price, _price);
			uint256 _balance = address(this).balance;
			vault.transfer(_balance);
		} else {
			uint256 _price = IERC20(paymentToken_).balanceOf(address(this));
			IERC20(paymentToken_).safeApprove(exchange, _price);
			_acquire(_price, 0);
			IERC20(paymentToken_).safeApprove(exchange, 0);
			uint256 _balance = IERC20(paymentToken_).balanceOf(address(this));
			IERC20(paymentToken_).safeTransfer(vault, _balance);
		}
		IERC721(collection_).approve(collective, tokenId_);
		OpenCollectivePurchase(collective).acquire(_listingId, 0);
	}

	function _acquire(uint256 _price, uint256 _value) internal
	{
		p_[0] = uint256(exchange);			// exchange
		p_[1] = uint256(address(this));		// maker
		//p_[2] = 0;					// taker
		//p_[3] = address(0);				// feeRecipient
		p_[4] = uint256(collection_);			// target
		//p_[5] = address(0);				// staticTarget
		p_[6] = uint256(paymentToken_);		// paymentToken

		p_[7] = uint256(exchange);			// exchange
		p_[8] = uint256(seller_);			// maker
		//p_[9] = address(0);				// taker
		p_[10] = uint256(feeRecipient);		// feeRecipient
		p_[11] = uint256(collection_);		// target
		//p_[12] = address(0);				// staticTarget
		p_[13] = uint256(paymentToken_);		// paymentToken

		p_[14] = makerRelayerFee_;			// makerRelayerFee
		//p_[15] = 0;					// takerRelayerFee
		//p_[16] = 0;					// makerProtocolFee
		//p_[17] = 0;					// takerProtocolFee
		p_[18] = _price;				// price
		//p_[19] = 0;					// extra
		p_[20] = now - 1;				// listimtime
		//p_[21] = 0;					// expirationTime
		//p_[22] = 0;					// salt

		p_[23] = makerRelayerFee_;			// makerRelayerFee
		//p_[24] = 0;					// takerRelayerFee
		//p_[25] = 0;					// makerProtocolFee
		//p_[26] = 0;					// takerProtocolFee
		p_[27] = basePrice_;				// basePrice
		p_[28] = extra_;				// extra
		p_[29] = listingTime_;				// listimtime
		p_[30] = expirationTime_;			// expirationTime
		p_[31] = salt_;				// salt

		p_[32] = 1;					// feeMethod
		//p_[33] = 0;					// side
		//p_[34] = 0;					// saleKind
		//p_[35] = 0;					// howToCall

		p_[36] = 1;					// feeMethod
		p_[37] = 1;					// side
		p_[38] = saleKind_;				// saleKind
		//p_[39] = 0;					// howToCall

		p_[40] = 1696;					// db.offset
		p_[41] = 1856;					// ds.offset
		p_[42] = 2016;					// pb.offset
		p_[43] = 2176;					// ps.offset
		p_[44] = 2336;					// sb.offset
		p_[45] = 2368;					// ss.offset

		//p_[46] = 0;					// v
		p_[47] = v_;					// v

		//p_[48] = bytes32(0);				// r
		//p_[49] = bytes32(0);				// s

		p_[50] = uint256(r_);				// r
		p_[51] = uint256(s_);				// s

		p_[52] = uint256(referral) << 96;		// metadata

		p_[53] = 100;					// db.length
		p_[54] = (0x23b872dd << 224);
		p_[55] = (uint256(address(this)) >> 32);
		p_[56] = (uint256(address(this)) << 224) | (tokenId_ >> 32);
		p_[57] = (tokenId_ << 224);

		p_[58] = 100;					// ds.length
		p_[59] = (0x23b872dd << 224) | (uint256(seller_) >> 32);
		p_[60] = (uint256(seller_) << 224);
		p_[61] = (tokenId_ >> 32);
		p_[62] = (tokenId_ << 224);

		p_[63] = 100;					// pb.length
		p_[64] = (uint256(-1) >> 32);
		p_[65] = (uint256(-1) << 224);
		//p_[66] = 0;
		//p_[67] = 0;

		p_[68] = 100;					// ps.length
		//p_[69] = 0;
		p_[70] = (uint256(-1) >> 32);
		p_[71] = (uint256(-1) << 224);
		//p_[72] = 0;

		//p_[73] = 0;					// sb.length

		//p_[74] = 0;					// ss.length

		bytes memory _data = abi.encodeWithSelector(0xab834bab, p_);
		(bool _success, bytes memory _returndata) = exchange.call{value: _value}(_data);
		require(_success && _returndata.length == 0, "call failure");
	}

	receive() external payable
	{
	}
}
