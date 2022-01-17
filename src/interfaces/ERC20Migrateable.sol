// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.5.0;

interface ERC20Migrateable {
    function migrate(uint256 oldTokenAmount, address recipient) external returns (uint256 newTokenAmount);
}