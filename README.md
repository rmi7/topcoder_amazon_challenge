# TopCoder Amazon.sol challenge

This repo contains my `Amazon.sol` submission for the [Diligence Smart Contract Fun Challenge](https://blockchain.topcoder.com/challenges/30065885).

- used `truffle@4.1.11` (that's why `emit` is now prepended to event calls)
- moved the original `Amazon.sol` file to `original_contracts/Amazon.sol`
- added review comments in `original_contracts/Amazon.sol` which all start with `// @audit`
- fixed all found issues in `contracts/Amazon.sol`
- added tests in `test/amazon.test.js`

## Test

1. start-up ganache --> `ganache-cli`
2. execute tests --> `truffle test`

## License

MIT
