// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct Permit {
     uint256 deadline;
     bytes32 r;
     bytes32 s;
     uint8 v;
     bool enable;
}

// solhint-disable-next-line
function NoPermit() pure returns (Permit memory) {
    return Permit(0, 0, 0, 0, false);
}