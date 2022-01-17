// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.11;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {TokenMigrator} from "./TokenMigrator.sol";
import {ClonesWithCallData} from "./lib/ClonesWithCallData.sol";
import {IERC20Migrateable} from "./interfaces/IERC20Migrateable.sol";

/// @title TokenMigratorFactory
/// @author zefram.eth
/// @notice Factory for deploying TokenMigrator contracts cheaply
contract TokenMigratorFactory {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using ClonesWithCallData for address;

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The contract used as the template for all clones created
    TokenMigrator public immutable implementation;

    constructor(TokenMigrator implementation_) {
        implementation = implementation_;
    }

    /// @notice Creates a TokenMigrator contract
    /// @dev Uses a modified minimal proxy contract that stores immutable parameters in code and
    /// passes them in through calldata. See ClonesWithCallData.
    /// @param oldToken The old token that's being phased out
    /// @param newToken The new token that's being migrated to
    /// @param unlockTimestamp The timestamp after which the locked old tokens
    /// can be redeemed. Set to 0 if the locked old tokens should
    /// never be unlocked.
    /// @return The created TokenMigrator contract
    function createTokenMigrator(
        ERC20 oldToken,
        IERC20Migrateable newToken,
        uint64 unlockTimestamp
    ) external returns (TokenMigrator) {
        bytes memory ptr;
        if (unlockTimestamp > 0) {
            ptr = new bytes(48);
            assembly {
                mstore(add(ptr, 0x20), shl(0x60, oldToken))
                mstore(add(ptr, 0x34), shl(0x60, newToken))
                mstore(add(ptr, 0x48), shl(0xc0, unlockTimestamp))
            }
        } else {
            ptr = new bytes(40);
            assembly {
                mstore(add(ptr, 0x20), shl(0x60, oldToken))
                mstore(add(ptr, 0x34), shl(0x60, newToken))
            }
        }

        return
            TokenMigrator(
                address(implementation).cloneWithCallDataProvision(ptr)
            );
    }
}
