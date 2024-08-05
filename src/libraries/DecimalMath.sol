// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library DecimalMath {
    function msd(uint256 num) internal pure returns (uint8) {
        if (num == 0) revert();
        uint8 ms = 0;
        while (num > 0) {
            num /= 10;
            ms++;
        }
        return ms;
    }

    function lsd(uint256 num) internal pure returns (uint8) {
        if (num == 0) revert();
        uint8 ls = 0;
        while (num > 0 && num % 10 == 0) {
            num /= 10;
            ls++;
        }
        return ls;
    } 
}