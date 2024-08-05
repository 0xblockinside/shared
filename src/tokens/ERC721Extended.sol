// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721} from "solady/src/tokens/ERC721.sol";

/// @notice Simple ERC721 implementation with storage hitchhiking.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC721.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC721/ERC721.sol)
abstract contract ERC721Extended is ERC721 {
    uint256 private constant _ERC721_MASTER_SLOT_SEED = 0x7d8825530a5a2e7a << 192;

    /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    function _getOwnershipSlot(uint256 id) internal view virtual returns (address owner, uint96 extra) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(m, 0x00), id)
            mstore(add(m, 0x1c), _ERC721_MASTER_SLOT_SEED)
            let ownershipSlot := add(id, add(id, keccak256(add(m, 0x00), 0x20)))
            let packed := sload(ownershipSlot)
            owner := shr(96, shl(96, packed)) // and(0xffffffffffffffffffffffffffffffffffffffff, packed)
            extra := shr(160, packed)
        }
    }

    function _setOwnershipSlot(uint256 id, address owner, uint96 extra) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(m, 0x00), id)
            mstore(add(m, 0x1c), _ERC721_MASTER_SLOT_SEED)
            let ownershipSlot := add(id, add(id, keccak256(add(m, 0x00), 0x20)))
            // Clear the upper 96 bits.
            owner := shr(96, shl(96, owner))
            sstore(ownershipSlot, or(owner, shl(160, extra)))
        }
    }

    function _getBalanceSlot(address owner) internal view returns (uint256 slot) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(m, 0x1c), _ERC721_MASTER_SLOT_SEED)
            mstore(add(m, 0x00), owner)
            let balanceSlot := keccak256(add(m, 0x0c), 0x1c)
            slot := sload(balanceSlot)
        }
    }

    function _setBalanceSlot(address owner, uint32 ownerBalance, uint224 aux) internal {

    }

    function _changeBalance(address owner, bool decrement, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(m, 0x1c), _ERC721_MASTER_SLOT_SEED)
            mstore(add(m, 0x00), owner)
            let balanceSlot := keccak256(add(m, 0x0c), 0x1c)
            let balanceSlotPacked := sload(balanceSlot)

            switch decrement
            case 0 { balanceSlotPacked := add(balanceSlotPacked, amount) }
            default { balanceSlotPacked := sub(balanceSlotPacked, amount) }

            if iszero(and(balanceSlotPacked, _MAX_ACCOUNT_BALANCE)) {
                mstore(add(m, 0x00), 0x01336cea) // `AccountBalanceOverflow()`.
                revert(add(m, 0x1c), 0x04)
            }
            sstore(balanceSlot, balanceSlotPacked)
        }
    }

    function _incrementBalance(address owner, uint256 amount) internal virtual {
        _changeBalance(owner, false, amount);
    }

    function _decrementBalance(address owner, uint256 amount) internal virtual {
        _changeBalance(owner, true, amount);
    }


    function _isApprovedOrOwner(address account, uint256 id, address owner)
        internal
        view
        virtual
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            result := 1
            // Clear the upper 96 bits.
            account := shr(96, shl(96, account))
            // Revert if the token does not exist.
            if iszero(owner) {
                mstore(add(m, 0x00), 0xceea21b6) // `TokenDoesNotExist()`.
                revert(add(m, 0x1c), 0x04)
            }
            // Check if `account` is the `owner`.
            if iszero(eq(account, owner)) {
                mstore(add(m, 0x00), id)
                mstore(add(m, 0x1c), or(_ERC721_MASTER_SLOT_SEED, account))
                let ownershipSlot := add(id, add(id, keccak256(0x00, 0x20)))

                mstore(add(m, 0x00), owner)
                // Check if `account` is approved to
                if iszero(sload(keccak256(add(m, 0x0c), 0x30))) {
                    result := eq(account, sload(add(1, ownershipSlot)))
                }
            }
        }
    }

    function _burn(address by, uint256 id, address owner, bool decrementBalance) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clear the upper 96 bits.
            by := shr(96, shl(96, by))
            // Load the ownership data.
            let m := mload(0x40)
            mstore(add(m, 0x00), id)
            mstore(add(m, 0x1c), or(_ERC721_MASTER_SLOT_SEED, by))
            let ownershipSlot := add(id, add(id, keccak256(add(m, 0x00), 0x20)))
            // Revert if the token does not exist.
            if iszero(owner) {
                mstore(add(m, 0x00), 0xceea21b6) // `TokenDoesNotExist()`.
                revert(add(m, 0x1c), 0x04)
            }
            // Load and check the token approval.
            {
                mstore(add(m, 0x00), owner)
                let approvedAddress := sload(add(1, ownershipSlot))
                // If `by` is not the zero address, do the authorization check.
                // Revert if the `by` is not the owner, nor approved.
                if iszero(or(iszero(by), or(eq(by, owner), eq(by, approvedAddress)))) {
                    if iszero(sload(keccak256(add(m, 0x0c), 0x30))) {
                        mstore(add(m, 0x00), 0x4b6e7f18) // `NotOwnerNorApproved()`.
                        revert(add(m, 0x1c), 0x04)
                    }
                }
                // Delete the approved address if any.
                if approvedAddress { sstore(add(1, ownershipSlot), 0) }
            }
            // Clear the owner and its extra data.
            sstore(ownershipSlot, 0)
            // Decrement the balance of `owner`.
            if decrementBalance {
                let balanceSlot := keccak256(add(m, 0x0c), 0x1c)
                sstore(balanceSlot, sub(sload(balanceSlot), 1))
            }
            // Emit the {Transfer} event.
            log4(add(m, 0x00), 0x00, _TRANSFER_EVENT_SIGNATURE, owner, 0, id)
        }
    }
}
