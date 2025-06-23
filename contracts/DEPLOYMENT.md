# FacePay Backend Deployment Summary 🚀

## ✅ Deployment Status: COMPLETE

### 📍 Contract Addresses (Sepolia Testnet)

| Contract | Address | Status |
|----------|---------|---------|
| **PYUSD** | `0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9` | ✅ Live |
| **PaymentHub** | `0x728d0f06Bf6D63B4bC9ca7C879D042DDAC66e8A3` | ✅ Deployed |

### 👛 Wallet Configuration

| Wallet | Address | PYUSD Balance | Approval Status |
|---------|---------|---------------|-----------------|
| **User 1** | `0x9f93EebD463d4B7c991986a082d974E77b5a02Dc` | 200.00 PYUSD | ✅ MAX |
| **User 2** | `0xa999F0CB16b55516BD82fd77Dc19f495b41f0770` | 100.00 PYUSD | ✅ MAX |
| **Merchant** | `0x27A7A44250C6Eb3C84d1d894c8A601742827C7C7` | 100.00 PYUSD | N/A |

### 🔧 Network Configuration

```javascript
// iOS App Configuration
const CONFIG = {
  network: "sepolia",
  chainId: 11155111,
  rpcUrl: "https://sepolia.infura.io/v3/YOUR_INFURA_KEY",
  
  contracts: {
    pyusd: "0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9",
    paymentHub: "0x728d0f06Bf6D63B4bC9ca7C879D042DDAC66e8A3"
  },
  
  wallets: {
    user1: "0x9f93EebD463d4B7c991986a082d974E77b5a02Dc",
    user2: "0xa999F0CB16b55516BD82fd77Dc19f495b41f0770",
    merchant: "0x27A7A44250C6Eb3C84d1d894c8A601742827C7C7"
  }
}
```

## 📱 For iOS Integration

### Required ABIs

**PaymentHub ABI (Key Functions):**
```json
[
  "function charge(address customer, uint256 amount) external",
  "function getBalance(address customer) external view returns (uint256)",
  "function hasApproval(address customer, uint256 amount) external view returns (bool)",
  "function getAllowance(address customer) external view returns (uint256)"
]
```

**PYUSD ERC-20 ABI (Key Functions):**
```json
[
  "function balanceOf(address account) external view returns (uint256)",
  "function approve(address spender, uint256 amount) external returns (bool)",
  "function allowance(address owner, address spender) external view returns (uint256)"
]
```

### Payment Flow

1. **Customer Registration**: Store face embedding linked to wallet address
2. **Face Recognition**: Match face → get wallet address
3. **Payment Execution**: Call `PaymentHub.charge(customerAddress, amount)`
4. **Confirmation**: Listen for `Charged` event

### Transaction Amounts

- PYUSD uses **6 decimals**
- Example: 12.50 PYUSD = `12500000` (wei format)

## 🧪 Testing Commands

```bash
# Check balances
npx hardhat check-balances --network sepolia

# Check approvals
npx hardhat check-approvals --network sepolia

# Simulate payment (after adding ETH to merchant)
npx hardhat simulate-payment --customer user1 --amount 5.99 --network sepolia
```

## 📋 Next Steps for iOS

1. ✅ **Backend Complete**: All contracts deployed and configured
2. 🔄 **iOS App**: Integrate web3swift with above config
3. 🔄 **Face Recognition**: Build Vision framework integration
4. 🔄 **Demo Flow**: Test end-to-end payment

---

**Backend Status: 🟢 READY FOR iOS DEVELOPMENT** 