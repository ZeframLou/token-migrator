// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.11;

import {DSTest} from "ds-test/test.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {TestERC20} from "./mocks/TestERC20.sol";
import {TokenMigrator} from "../TokenMigrator.sol";
import {TokenMigratorFactory} from "../TokenMigratorFactory.sol";
import {TestERC20Migrateable} from "./mocks/TestERC20Migrateable.sol";
import {IERC20Migrateable} from "../interfaces/IERC20Migrateable.sol";

contract TokenMigratorFactoryTest is DSTest {
    TokenMigratorFactory factory;
    TestERC20 oldToken;
    TestERC20Migrateable newToken;

    function setUp() public {
        TokenMigrator implementation = new TokenMigrator();
        factory = new TokenMigratorFactory(implementation);

        oldToken = new TestERC20();
        newToken = new TestERC20Migrateable();
    }

    /// -------------------------------------------------------------------
    /// Gas benchmarking
    /// -------------------------------------------------------------------

    function testGas_createTokenMigrator_noUnlock() public {
        factory.createTokenMigrator(oldToken, newToken, 0);
    }

    function testGas_createTokenMigrator_hasUnlock() public {
        factory.createTokenMigrator(oldToken, newToken, 12345678);
    }

    /// -------------------------------------------------------------------
    /// Correctness tests
    /// -------------------------------------------------------------------

    function testCorrectness_createTokenMigrator(uint64 unlockTimestamp)
        public
    {
        TokenMigrator migrator = factory.createTokenMigrator(
            oldToken,
            newToken,
            unlockTimestamp
        );

        assertEq(address(migrator.oldToken()), address(oldToken));
        assertEq(address(migrator.newToken()), address(newToken));
        assertEq(uint256(migrator.unlockTimestamp()), uint256(unlockTimestamp));
    }
}
