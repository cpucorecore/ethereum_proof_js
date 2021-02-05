pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./RLPUtil.sol";

library Util {

    using RLPUtil for RLPUtil.LogEntry;

    function BytesEqual(bytes memory v1, bytes memory v2) public pure returns (bool) {
        if (v1.length != v2.length) return false;

        for (uint i=0;i<v1.length;i++) {
            if (v1[i] != v2[i]) return false;
        }

        return true;
    }

    function LogEntryEqual(RLPUtil.LogEntry memory v1, RLPUtil.LogEntry memory v2) public pure returns (bool) {
        if (v1.addr != v2.addr) return false;
        if (!BytesEqual(v1.data, v2.data)) return false;
        if (v1.topices.length != v2.topices.length) return false;

        for (uint i=0;i<v1.topices.length;i++) {
            if (v1.topices[i] != v2.topices[i]) {
                return false;
            }
        }

        return true;
    }

    function ExtractNibbles(bytes memory key) public pure returns (bytes memory) {
        require(key.length != 0);

        bytes memory nibbles = new bytes(key.length*2);
        for(uint32 i=0; i<key.length; i++) {
            nibbles[i*2] = key[i] >> 4;
            nibbles[i*2 + 1] = key[i] & 0x0f;
        }

        return nibbles;
    }

    function ConcatNibbles(bytes memory nibbles) public pure returns (bytes memory empty) {
        if (nibbles.length == 0) return empty;

        bytes memory value = new bytes((nibbles.length+1)/2);
        bytes memory t = new bytes(value.length*2);
        if (nibbles.length % 2 == 1) {
            t[0] = 0;
            for (uint i=1;i<value.length;i++) {
                t[i] = nibbles[i-1];
            }
        } else {
            t = nibbles;
        }

        for(uint32 i=0; i<t.length; i=i+2) {
            value[i/2] = t[i] << 4 | t[i+1];
        }

        return value;
    }

    function subarray(bytes memory src, uint startIndex, uint endIndex) public pure returns (bytes memory) {
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = src[i];
        }
        return result;
    }
}



