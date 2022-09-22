# AAVE Redeem FEI

This repository contains the Proposal Payload and tests for redeeming 300,000 aFEI for FEI and then redeeming FEI for DAI via Tribe DAO’s DAI Peg Stability Module (PSM).

## Installation

It requires [Foundry](https://github.com/gakonst/foundry) installed to run. You can find instructions here [Foundry installation](https://github.com/gakonst/foundry#installation).

To set up the project manually, run the following commands:

```sh
$ git clone https://github.com/llama-community/aave-redeem-fei.git
$ cd aave-redeem-fei/
$ forge install
```

## Setup

Duplicate `.env.example` and rename to `.env`:

- Add a valid mainnet URL for an Ethereum JSON-RPC client for the `ETH_RPC_URL` variable.
- Keep the same mainnet block number (i.e `15529359`) for the `BLOCK_NUMBER` variable.
- Add a valid Etherscan API Key for the `ETHERSCAN_API_KEY` variable.

### Commands

- `make build` - build the project
- `make test` - run tests
