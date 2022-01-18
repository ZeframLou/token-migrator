// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.11;

import {DSTest} from "ds-test/test.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {VM} from "./utils/VM.sol";
import {TestERC20} from "./mocks/TestERC20.sol";
import {TokenMigrator} from "../TokenMigrator.sol";
import {TokenMigratorFactory} from "../TokenMigratorFactory.sol";
import {TestERC20Migrateable} from "./mocks/TestERC20Migrateable.sol";
import {IERC20Migrateable} from "../interfaces/IERC20Migrateable.sol";

contract TokenMigratorTest is DSTest {
    VM constant vm = VM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    TokenMigratorFactory factory;
    TokenMigrator migratorNoUnlock;
    TokenMigrator migratorHasUnlock;
    TestERC20 oldToken;
    TestERC20Migrateable newToken;
    uint64 unlockTimestamp;

    function setUp() public {
        TokenMigrator implementation = new TokenMigrator();
        factory = new TokenMigratorFactory(implementation);

        oldToken = new TestERC20();
        newToken = new TestERC20Migrateable();

        unlockTimestamp = uint64(block.timestamp + 99 * 365 days);
        migratorNoUnlock = factory.createTokenMigrator(oldToken, newToken, 0);
        migratorHasUnlock = factory.createTokenMigrator(
            oldToken,
            newToken,
            unlockTimestamp
        );

        oldToken.mint(address(this), 1000 ether);
        oldToken.approve(address(migratorNoUnlock), type(uint256).max);
        oldToken.approve(address(migratorHasUnlock), type(uint256).max);
    }

    /// -----------------------------------------------------------------------
    /// Gas benchmarking
    /// -----------------------------------------------------------------------

    function testGas_migrate_noUnlock() public {
        migratorNoUnlock.migrate(1 ether, address(this));
    }

    function testGas_migrate_hasUnlock() public {
        migratorHasUnlock.migrate(1 ether, address(this));
    }

    /// -----------------------------------------------------------------------
    /// Correctness tests
    /// -----------------------------------------------------------------------

    function testCorrectness_migrate(uint240 oldTokenAmount) public {
        uint256 beforeOldTokenBalance = oldToken.balanceOf(address(this));

        // mint old tokens
        oldToken.mint(address(this), oldTokenAmount);

        // migrate
        uint256 newTokenAmount = migratorNoUnlock.migrate(
            oldTokenAmount,
            address(this)
        );

        // check balance
        assertEq(newToken.balanceOf(address(this)), newTokenAmount);
        assertEq(oldToken.balanceOf(address(this)), beforeOldTokenBalance);
    }

    function testCorrectness_unlock(uint240 oldTokenAmount) public {
        uint256 beforeOldTokenBalance = oldToken.balanceOf(address(this));

        // mint old tokens
        oldToken.mint(address(this), oldTokenAmount);

        // migrate
        migratorHasUnlock.migrate(oldTokenAmount, address(this));

        // warp to unlock timestamp
        vm.warp(unlockTimestamp);

        // unlock
        migratorHasUnlock.unlock(address(this));

        // check balance
        assertEq(
            oldToken.balanceOf(address(this)),
            beforeOldTokenBalance + oldTokenAmount
        );
    }
}
