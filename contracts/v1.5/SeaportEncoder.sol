// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract SeaportEncoder is Ownable
{
	struct EIP712Domain {
		string name;
		string version;
		uint256 chainId;
		address verifyingContract;
	}

	struct OrderComponents {
		address offerer;
		address zone;
		OfferItem[] offer;
		ConsiderationItem[] consideration;
		uint8 orderType;
		uint256 startTime;
		uint256 endTime;
		bytes32 zoneHash;
		uint256 salt;
		bytes32 conduitKey;
		uint256 counter;
	}

	struct OfferItem {
		uint8 itemType;
		address token;
		uint256 identifierOrCriteria;
		uint256 startAmount;
		uint256 endAmount;
	}

	struct ConsiderationItem {
		uint8 itemType;
		address token;
		uint256 identifierOrCriteria;
		uint256 startAmount;
		uint256 endAmount;
		address recipient;
	}

	bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
	bytes32 constant ORDERCOMPONENTS_TYPEHASH = keccak256("OrderComponents(address offerer,address zone,OfferItem[] offer,ConsiderationItem[] consideration,uint8 orderType,uint256 startTime,uint256 endTime,bytes32 zoneHash,uint256 salt,bytes32 conduitKey,uint256 counter)ConsiderationItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount,address recipient)OfferItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount)");
	bytes32 constant OFFERITEM_TYPEHASH = keccak256("OfferItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount)");
	bytes32 constant CONSIDERATIONITEM_TYPEHASH = keccak256("ConsiderationItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount,address recipient)");

	string constant SEAPORT_NAME = "Seaport";
	string constant SEAPORT_VERSION = "1.1";
	address constant SEAPORT_ADDRESS = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

	bytes32 public immutable DOMAIN_SEPARATOR;

	uint256[2] public fee = [975, 1000];
	address public feeCollector = 0x0000a26b00c1F0DF003000390027140000fAa719;
	uint8 public orderType = 0;
	address public zone = 0x0000000000000000000000000000000000000000;
	bytes32 public zoneHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
	bytes32 public conduitKey = 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;

	constructor () public
	{
		uint256 _chainId;
		assembly {
			_chainId := chainid()
		}
		DOMAIN_SEPARATOR = _hash(EIP712Domain({
			name: SEAPORT_NAME,
			version: SEAPORT_VERSION,
			chainId: _chainId,
			verifyingContract: SEAPORT_ADDRESS
		}));
	}

	function configure(uint256[2] memory _fee, address _feeCollector, uint8 _orderType, address _zone, bytes32 _zoneHash, bytes32 _conduitKey) external onlyOwner
	{
		fee = _fee;
		feeCollector = _feeCollector;
		orderType = _orderType;
		zone = _zone;
		zoneHash = _zoneHash;
		conduitKey = _conduitKey;
	}

	function hash(address _offerer, address _collection, uint256 _tokenId, uint256 _price, address _paymentToken, uint256 _startTime, uint256 _endTime, uint256 _salt, uint256 _counter) external view returns (bytes32)
	{
		uint256 _fee = _price * fee[1] / fee[0] - _price;
		while ((_price + _fee) * fee[0] / fee[1] < _price) _fee++;
		OfferItem[] memory offer = new OfferItem[](1);
		offer[0] = OfferItem({
			itemType: 2,
			token: _collection,
			identifierOrCriteria: _tokenId,
			startAmount: 1,
			endAmount: 1
		});
		ConsiderationItem[] memory consideration = new ConsiderationItem[](2);
		consideration[0] = ConsiderationItem({
			itemType: _paymentToken == address(0) ? 0 : 1,
			token: _paymentToken,
			identifierOrCriteria: 0,
			startAmount: _price,
			endAmount: _price,
			recipient: _offerer
		});
		consideration[1] = ConsiderationItem({
			itemType: _paymentToken == address(0) ? 0 : 1,
			token: _paymentToken,
			identifierOrCriteria: 0,
			startAmount: _fee,
			endAmount: _fee,
			recipient: feeCollector
		});
		OrderComponents memory orderComponents = OrderComponents({
			offerer: _offerer,
			zone: zone,
			offer: offer,
			consideration: consideration,
			orderType: orderType,
			startTime: _startTime,
			endTime: _endTime,
			zoneHash: zoneHash,
			salt: _salt,
			conduitKey: conduitKey,
			counter: _counter
		});
		return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, _hash(orderComponents)));
	}

	function _hash(EIP712Domain memory _eip712Domain) internal pure returns (bytes32)
	{
		return keccak256(abi.encode(
			EIP712DOMAIN_TYPEHASH,
			keccak256(bytes(_eip712Domain.name)),
			keccak256(bytes(_eip712Domain.version)),
			_eip712Domain.chainId,
			_eip712Domain.verifyingContract
		));
	}

	function _hash(OrderComponents memory _orderComponents) internal pure returns (bytes32)
	{
		return keccak256(abi.encode(
			ORDERCOMPONENTS_TYPEHASH,
			_orderComponents.offerer,
			_orderComponents.zone,
			_hash(_orderComponents.offer),
			_hash(_orderComponents.consideration),
			uint256(_orderComponents.orderType),
			_orderComponents.startTime,
			_orderComponents.endTime,
			_orderComponents.zoneHash,
			_orderComponents.salt,
			_orderComponents.conduitKey,
			_orderComponents.counter
		));
	}

	function _hash(OfferItem[] memory _offer) internal pure returns (bytes32)
	{
		bytes32[] memory _data = new bytes32[](_offer.length);
		for (uint256 _i = 0; _i < _data.length; _i++) {
			_data[_i] = _hash(_offer[_i]);
		}
		return keccak256(abi.encodePacked(_data));
	}

	function _hash(OfferItem memory _offerItem) internal pure returns (bytes32)
	{
		return keccak256(abi.encode(
			OFFERITEM_TYPEHASH,
			uint256(_offerItem.itemType),
			_offerItem.token,
			_offerItem.identifierOrCriteria,
			_offerItem.startAmount,
			_offerItem.endAmount
		));
	}

	function _hash(ConsiderationItem[] memory _consideration) internal pure returns (bytes32)
	{
		bytes32[] memory _data = new bytes32[](_consideration.length);
		for (uint256 _i = 0; _i < _data.length; _i++) {
			_data[_i] = _hash(_consideration[_i]);
		}
		return keccak256(abi.encodePacked(_data));
	}

	function _hash(ConsiderationItem memory _considerationItem) internal pure returns (bytes32)
	{
		return keccak256(abi.encode(
			CONSIDERATIONITEM_TYPEHASH,
			uint256(_considerationItem.itemType),
			_considerationItem.token,
			_considerationItem.identifierOrCriteria,
			_considerationItem.startAmount,
			_considerationItem.endAmount,
			_considerationItem.recipient
		));
	}
}
