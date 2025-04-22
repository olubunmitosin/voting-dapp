## Decentralized Voting dApp

**This is an exciting project that will allow members of your Decentralized Autonomous Organization (DAO) to create proposals, vote on them securely, and execute the results.**

Foeatures:

-   **Proposals**: Manage proposals.
-   **Voting**: Manage voting process.
-   **DAO**: Membership and Access
-   **Wallet Connection**: Connection with wallet


Technologies:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.
-   **Sepolia Testnet**: Chain to test the functionalities since of course we won't be using real money
-   **Solidity**: Smart contract development programming language version ^0.8.0

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
