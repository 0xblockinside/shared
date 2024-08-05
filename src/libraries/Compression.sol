// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DecimalMath} from "./DecimalMath.sol";
import {Bits} from "./Bits.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

library DynamicCompression56 {
    uint8 public constant VALUE_BITS = 51;
    uint8 public constant DECIMAL_BITS = 5;

    using Bits for uint256;
    using DecimalMath for uint256;

    function compress56(uint256 value) internal pure returns (uint56) {
        uint8 curDecimal = value.lsd();
        while (value / 10 ** curDecimal >= 2 ** VALUE_BITS) {
            curDecimal++;
        }
        // curDecimals will never be greater than 2 ** DECIMAL_BITS
        return uint56(curDecimal) |
               uint56(value / 10 ** curDecimal) << DECIMAL_BITS; 
    }

    function decompress56(uint56 value) internal pure returns (uint256) {
        uint256 decoded = uint256(value >> DECIMAL_BITS);
        decoded *= 10 ** uint256(value).rightMask(DECIMAL_BITS);
        return decoded;
    }
}

library AssetCompression90 {
    uint constant BITS = 90;

    function decimalCompressionOffset(IERC20 asset) internal view returns (uint decimal) {
        uint a = asset.totalSupply() /  (2 ** BITS - 1);
        while (a >= 10) {
            a /= 10;
            decimal++;
        }
    }

    function compress90(IERC20 asset, uint amount) internal view returns (uint amount90, uint decimal) {
        decimal = decimalCompressionOffset(asset);
        amount90 = amount / 10 ** decimal;
    }

    function decompress90(IERC20 asset, uint amount90) internal view returns (uint amount) {
        uint decimal = decimalCompressionOffset(asset);
        amount = amount90 *  10 ** decimal;
    }
}
