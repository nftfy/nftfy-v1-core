// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

contract Example
{
	struct EIP712Domain {
		string  name;
		string  version;
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

	bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
	bytes32 public constant ORDERCOMPONENTS_TYPEHASH = keccak256("OrderComponents(address offerer,address zone,OfferItem[] offer,ConsiderationItem[] consideration,uint8 orderType,uint256 startTime,uint256 endTime,bytes32 zoneHash,uint256 salt,bytes32 conduitKey,uint256 counter)ConsiderationItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount,address recipient)OfferItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount)");
	bytes32 public constant OFFERITEM_TYPEHASH = keccak256("OfferItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount)");
	bytes32 public constant CONSIDERATIONITEM_TYPEHASH = keccak256("ConsiderationItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount,address recipient)");

	bytes32 public immutable DOMAIN_SEPARATOR;

	constructor () public
	{
		DOMAIN_SEPARATOR = _hash(EIP712Domain({
			name: "Seaport",
			version: "1.1",
			chainId: 4,
			verifyingContract: 0x00000000006c3852cbEf3e08E8dF289169EdE581
		}));
	}

	function _hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32)
	{
		return keccak256(abi.encode(
			EIP712DOMAIN_TYPEHASH,
			keccak256(bytes(eip712Domain.name)),
			keccak256(bytes(eip712Domain.version)),
			eip712Domain.chainId,
			eip712Domain.verifyingContract
		));
	}

	function _hash(OrderComponents memory orderComponents) internal pure returns (bytes32)
	{
		return keccak256(abi.encode(
			ORDERCOMPONENTS_TYPEHASH,
			orderComponents.offerer,
			orderComponents.zone,
			_hash(orderComponents.offer),
			_hash(orderComponents.consideration),
			uint256(orderComponents.orderType),
			orderComponents.startTime,
			orderComponents.endTime,
			orderComponents.zoneHash,
			orderComponents.salt,
			orderComponents.conduitKey,
			orderComponents.counter
		));
	}

	function _hash(OfferItem[] memory offer) internal pure returns (bytes32)
	{
		bytes32[] memory hashes = new bytes32[](offer.length);
		for (uint256 i = 0; i < hashes.length; i++) {
			hashes[i] = _hash(offer[i]);
		}
		return keccak256(abi.encodePacked(hashes));
	}

	function _hash(OfferItem memory offerItem) internal pure returns (bytes32)
	{
		return keccak256(abi.encode(
			OFFERITEM_TYPEHASH,
			uint256(offerItem.itemType),
			offerItem.token,
			offerItem.identifierOrCriteria,
			offerItem.startAmount,
			offerItem.endAmount
		));
	}

	function _hash(ConsiderationItem[] memory consideration) internal pure returns (bytes32)
	{
		bytes32[] memory hashes = new bytes32[](consideration.length);
		for (uint256 i = 0; i < hashes.length; i++) {
			hashes[i] = _hash(consideration[i]);
		}
		return keccak256(abi.encodePacked(hashes));
	}

	function _hash(ConsiderationItem memory considerationItem) internal pure returns (bytes32)
	{
		return keccak256(abi.encode(
			CONSIDERATIONITEM_TYPEHASH,
			uint256(considerationItem.itemType),
			considerationItem.token,
			considerationItem.identifierOrCriteria,
			considerationItem.startAmount,
			considerationItem.endAmount,
			considerationItem.recipient
		));
	}

	function test() public view returns (bytes32)
	{
		OfferItem[] memory offer = new OfferItem[](1);
		offer[0] = OfferItem({
			itemType: 2,
			token: 0x46bEF163D6C470a4774f9585F3500Ae3b642e751,
			identifierOrCriteria: 517,
			startAmount: 1,
			endAmount: 1
		});
		ConsiderationItem[] memory consideration = new ConsiderationItem[](2);
		consideration[0] = ConsiderationItem({
			itemType: 0,
			token: 0x0000000000000000000000000000000000000000,
			identifierOrCriteria: 0,
			startAmount: 97500000000000,
			endAmount: 97500000000000,
			recipient: 0xFDf35F1Bfe270e636f535a45Ce8D02457676e050
		});
		consideration[1] = ConsiderationItem({
			itemType: 0,
			token: 0x0000000000000000000000000000000000000000,
			identifierOrCriteria: 0,
			startAmount: 2500000000000,
			endAmount: 2500000000000,
			recipient: 0x0000a26b00c1F0DF003000390027140000fAa719
		});
		OrderComponents memory orderComponents = OrderComponents({
			offerer: 0xFDf35F1Bfe270e636f535a45Ce8D02457676e050,
			zone: 0x00000000E88FE2628EbC5DA81d2b3CeaD633E89e,
			offer: offer,
			consideration: consideration,
			orderType: 2,
			startTime: 1664206365,
			endTime: 1666798365,
			zoneHash: 0x0000000000000000000000000000000000000000000000000000000000000000,
			salt: 20150809813597178,
			conduitKey: 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000,
			counter: 0
		});
		// 0x35c568f7344e0348798c1fd5f38555ae8ff50b1895e91daf11efd54624fa8183
		return keccak256(abi.encodePacked(
			"\x19\x01",
			DOMAIN_SEPARATOR,
			_hash(orderComponents)
		));
	}
}
