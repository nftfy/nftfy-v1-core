pragma solidity 0.5.15;

library Utils
{
	function hexc(uint8 _value) public pure returns (byte _char)
	{
		assert(_value < 16);
		return byte(_value < 10 ? uint8(byte("0")) + _value : uint8(byte("a")) + _value - 10);
	}

	function hexs(uint256 _value) public pure returns (string memory _string)
	{
		bytes memory _buffer = new bytes(64);
		for (uint256 _i = 64; _i > 0; _i--) {
			uint256 _index = _i - 1;
			uint8 _ord = uint8(_value) & 0x0f;
			_buffer[_index] = hexc(_ord);
			_value >>= 4;
		}
		return string(_buffer);
	}
}
