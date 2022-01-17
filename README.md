# TokenMigrator

A simple contract for migrating from an old ERC20 token to a new ERC20 token.

Also supports letting migrators get back their old tokens after a certain time (e.g. 99 years) for shady legal reasons.

The new ERC20 token MUST implement the [IERC20Migrateable](src/interfaces/IERC20Migrateable.sol) interface, specifically a migrate function following the interface `function migrate(uint256 oldTokenAmount, address recipient) external returns (uint256 newTokenAmount)`. When called, the new ERC20 token must mint some amount of new tokens to `recipient` based on `oldTokenAmount`, and return the amount of new tokens minted as `newTokenAmount`. It does not need to make checks about whether old tokens have been locked. It MUST check that the caller is indeed the `TokenMigrator` contract.

## Local development

This project uses [Foundry](https://github.com/gakonst/foundry) as the development framework.

### Compilation

```
make build
```

### Testing

```
make test
```
