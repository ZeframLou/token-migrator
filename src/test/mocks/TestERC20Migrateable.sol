// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {IERC20Migrateable} from "../../interfaces/IERC20Migrateable.sol";

contract TestERC20Migrateable is ERC20("", "", 18), IERC20Migrateable {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function migrate(uint256 oldTokenAmount, address recipient)
        external
        returns (uint256 newTokenAmount)
    {
        // we don't do auth checks for msg.sender but we should in prod

        // 1:10000 migration
        newTokenAmount = oldTokenAmount * 10000;

        _mint(recipient, newTokenAmount);
    }
}
