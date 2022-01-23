// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.11;

import {ClonesWithImmutableArgs} from "@clones/ClonesWithImmutableArgs.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {TokenMigrator} from "./TokenMigrator.sol";
import {IERC20Migrateable} from "./interfaces/IERC20Migrateable.sol";

/// @title TokenMigratorFactory
/// @author zefram.eth
/// @notice Factory for deploying TokenMigrator contracts cheaply
contract TokenMigratorFactory {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using ClonesWithImmutableArgs for address;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event CreateTokenMigrator(TokenMigrator migrator);

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
    /// @return migrator The created TokenMigrator contract
    function createTokenMigrator(
        ERC20 oldToken,
        IERC20Migrateable newToken,
        uint64 unlockTimestamp
    ) external returns (TokenMigrator migrator) {
        bytes memory data;
        if (unlockTimestamp > 0) {
            data = abi.encodePacked(oldToken, newToken, unlockTimestamp);
        } else {
            data = abi.encodePacked(oldToken, newToken);
        }

        migrator = TokenMigrator(address(implementation).clone(data));
        emit CreateTokenMigrator(migrator);
    }
}
