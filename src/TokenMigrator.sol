// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.11;

import {Clone} from "@clones/Clone.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IERC20Migrateable} from "./interfaces/IERC20Migrateable.sol";

/// @title TokenMigrator
/// @author zefram.eth
/// @notice Used for migrating from an existing ERC20 token to a new ERC20 token
contract TokenMigrator is Clone {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error Error_BeforeUnlockTimestamp();
    error Error_AfterUnlockTimestamp();

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice Records the amount of old tokens locked by a user during migration
    /// @dev Only used if unlockTimestamp() is non-zero
    mapping(address => uint256) public lockedOldTokenBalance;

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The old token that's being phased out
    /// @return _oldToken The old token that's being phased out
    function oldToken() public pure returns (ERC20 _oldToken) {
        return ERC20(_getArgAddress(0));
    }

    /// @notice The new token that's being migrated to
    /// @return _newToken The new token that's being migrated to
    function newToken() public pure returns (IERC20Migrateable _newToken) {
        return IERC20Migrateable(_getArgAddress(0x14));
    }

    /// @notice The timestamp after which the locked old tokens
    /// can be redeemed. Set to 0 if the locked old tokens should
    /// never be unlocked.
    ///
    /// This feature is included because some lawyers said you can pay less
    /// taxes by having a finite unlock period so that the migration is legally
    /// speaking a loan. ¯\_(ツ)_/¯
    /// @return _unlockTimestamp The timestamp after which the locked old tokens
    /// can be redeemed. Set to 0 if the locked old tokens should never be unlocked.
    function unlockTimestamp() public pure returns (uint64 _unlockTimestamp) {
        return _getArgUint64(0x28);
    }

    /// -----------------------------------------------------------------------
    /// User actions
    /// -----------------------------------------------------------------------

    /// @notice Migrates old tokens to new tokens
    /// @param oldTokenAmount The amount of old tokens to migrate
    /// @param recipient The address that will receive the new tokens
    /// (as well as the right to unlock the old tokens if unlockTimestamp is set)
    /// @return newTokenAmount The amount of new tokens received
    function migrate(uint256 oldTokenAmount, address recipient)
        external
        returns (uint256 newTokenAmount)
    {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // if migrating 0, just do nothing
        if (oldTokenAmount == 0) {
            return 0;
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        uint256 _unlockTimestamp = unlockTimestamp();
        if (_unlockTimestamp > 0) {
            // oh wow you listened to your lawyer, poggers
            // we will record the old token balance so you can unlock it
            // in 99 years or something
            // credited to the recipient because they're already getting the
            // new tokens, they might as well get the old ones too

            // can't migrate after unlock since that enables infinite migration loops
            if (block.timestamp >= _unlockTimestamp) {
                revert Error_AfterUnlockTimestamp();
            }

            // don't check for overflow cause nobody cares
            // also because an ERC20 token's total supply can't exceed 256 bits
            unchecked {
                lockedOldTokenBalance[recipient] += oldTokenAmount;
            }
        }

        /// -----------------------------------------------------------------------
        /// Effects
        /// -----------------------------------------------------------------------

        // transfer old tokens from sender and lock
        oldToken().safeTransferFrom(msg.sender, address(this), oldTokenAmount);

        // migrate to new token
        newTokenAmount = newToken().migrate(oldTokenAmount, recipient);
    }

    /// @notice Unlocks old tokens used in migration. Only callable if unlockTimestamp is non-zero
    /// and the current time is >= unlockTimestamp.
    /// @param recipient The address that will receive the old tokens
    /// @return oldTokenAmount The amount of old tokens unlocked
    function unlock(address recipient)
        external
        returns (uint256 oldTokenAmount)
    {
        /// -----------------------------------------------------------------------
        /// Validation
        /// -----------------------------------------------------------------------

        // must be after unlock timestamp
        uint256 _unlockTimestamp = unlockTimestamp();
        if (
            _unlockTimestamp == 0 ||
            (_unlockTimestamp > 0 && block.timestamp < _unlockTimestamp)
        ) {
            revert Error_BeforeUnlockTimestamp();
        }

        /// -----------------------------------------------------------------------
        /// State updates
        /// -----------------------------------------------------------------------

        oldTokenAmount = lockedOldTokenBalance[msg.sender];
        if (oldTokenAmount == 0) return 0;
        delete lockedOldTokenBalance[msg.sender];

        /// -----------------------------------------------------------------------
        /// Effects
        /// -----------------------------------------------------------------------

        oldToken().safeTransfer(recipient, oldTokenAmount);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    function _getImmutableVariablesOffset()
        internal
        pure
        returns (uint256 offset)
    {
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}
