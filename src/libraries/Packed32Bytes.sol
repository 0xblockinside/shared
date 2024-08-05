// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Packed32Bytes {
    function get(bytes32 data, uint256 idx) internal pure returns (uint32 value) {
        return uint32(uint256(data) >> (32 * idx));
    }
}