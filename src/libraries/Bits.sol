// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Bits {
    function rightMask(uint256 val, uint256 n) internal pure returns (uint256) {
        if (n > 255) revert();
        return ((1 << n) - 1) & val;
    }
}