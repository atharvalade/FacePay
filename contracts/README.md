# FacePay Smart Contracts

PaymentHub smart contract for face-based PYUSD payments on Ethereum Sepolia.

## Setup

1. Copy environment template:
```shell
cp env.template .env
```

2. Fill in your API keys and private keys in `.env`

## Available Commands

```shell
# Compile contracts
npx hardhat compile

# Check PYUSD balances
npx hardhat check-balances --network sepolia

# Deploy PaymentHub
npx hardhat ignition deploy ignition/modules/PaymentHub.js --network sepolia

# Set approvals for users
npx hardhat set-approval --user user1 --network sepolia
npx hardhat set-approval --user user2 --network sepolia

# Check approvals
npx hardhat check-approvals --network sepolia

# Simulate payment
npx hardhat simulate-payment --customer user1 --amount 5.50 --network sepolia
```

## Contract Details

- **PaymentHub.sol**: Handles PYUSD transfers for face-based payments
- **PYUSD Address**: 0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9 (Sepolia)
- **Network**: Ethereum Sepolia Testnet
