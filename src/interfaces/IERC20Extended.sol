// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20 as OZ_IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "openzeppelin/token/ERC20/extensions/IERC20Permit.sol";


interface IERC20 is OZ_IERC20, IERC20Metadata {}

interface IPermitERC20 is IERC20, IERC20Permit {}
