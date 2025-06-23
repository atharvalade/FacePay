# FacePay Deployment Guide

## 🚀 Complete Setup for Real Blockchain Transactions

This guide shows you how to deploy the FacePay API and update your iOS app to use **REAL** blockchain transactions with live streaming logs.

## 📁 Project Structure

```
FacePay/
├── api/                    # New API server for real transactions
│   ├── server.js          # Express.js server with streaming
│   ├── package.json       # Dependencies
│   ├── vercel.json        # Vercel configuration
│   └── README.md          # API documentation
├── FacePay/               # iOS app
│   └── Services/
│       └── Web3Service.swift  # Updated with API integration
└── contracts/             # Existing blockchain contracts
```

## 🌐 API Deployment (Vercel)

### Step 1: Push API to GitHub

1. Create a new repository or push to existing one:
```bash
git add api/
git commit -m "Add FacePay API server with real blockchain transactions"
git push origin main
```

### Step 2: Deploy to Vercel

1. Go to [vercel.com](https://vercel.com) and sign in
2. Click "New Project"
3. Import your GitHub repository
4. Set **Root Directory** to `api`
5. Add environment variables:
   - `SEPOLIA_RPC`: `https://sepolia.infura.io/v3/40f21c9a3e114c7d880efefc7d9b04be`
6. Click "Deploy"

### Step 3: Get Your API URL

After deployment, you'll get a URL like: `https://your-project.vercel.app`

## 📱 iOS App Configuration

### Step 1: Update API URL

In `FacePay/Services/Web3Service.swift`, update line 26:

```swift
private let apiBaseURL = "https://your-actual-vercel-url.vercel.app"
```

### Step 2: Build and Run

Your iOS app will now:
- ✅ Execute **REAL** blockchain transactions
- 🌊 Show **live streaming logs** during payment
- 📊 Display transaction progress in real-time
- 🔗 Provide **real Etherscan links**

## 🧪 Testing the Setup

### Local API Testing

1. Start the API locally:
```bash
cd api
npm install
npm start
```

2. Test endpoints:
```bash
# Health check
curl http://localhost:3000/health

# Balance check
curl http://localhost:3000/balance/0x9f93EebD463d4B7c991986a082d974E77b5a02Dc

# Real transaction (will submit to blockchain!)
curl -X POST http://localhost:3000/transaction \
  -H "Content-Type: application/json" \
  -d '{
    "fromAddress": "0x9f93EebD463d4B7c991986a082d974E77b5a02Dc",
    "toAddress": "0x27A7A44250C6Eb3C84d1d894c8A601742827C7C7",
    "amount": "0.1",
    "privateKey": "15953296e322c945eaa0c215f8740fcdb1cb18231d19e477efa91ae4310becdf"
  }'
```

### iOS App Testing

1. Run the app on iOS Simulator
2. Go to Merchant tab
3. Enter amount (e.g., 1.0 PYUSD)
4. Tap "Scan Customer Face"
5. Watch the **real-time transaction logs** appear!

## 🎯 What You Get

### Real Blockchain Integration
- ✅ **Actual Sepolia transactions** submitted to blockchain
- ✅ **Real transaction hashes** visible on Etherscan
- ✅ **Live balance updates** after payments
- ✅ **Gas optimization** with reasonable fees

### Live Streaming Experience
- 🌊 **Real-time logs** during transaction processing
- 📊 **Progress indicators** for each step
- ⚡ **Instant feedback** on transaction status
- 🔗 **Direct Etherscan links** for verification

### Production Ready Features
- 🛡️ **Error handling** with retry logic
- ⏱️ **Timeout protection** for long transactions
- 🎨 **Beautiful UI** with log animations
- 📱 **iOS + macOS** compatibility

## 🔧 API Endpoints

### GET /health
Health check for the API

### GET /balance/:address
Get PYUSD balance for any address

### POST /transaction
Simple transaction (returns final result)

### POST /transaction/stream
**Real-time streaming transaction** with live logs

## 🌟 Demo Flow

1. **Customer Setup**: Face recognition links wallet address
2. **Merchant Input**: Enter payment amount
3. **Face Scan**: Camera captures customer face
4. **Real Transaction**: API executes actual blockchain transfer
5. **Live Logs**: Real-time progress shown in app
6. **Confirmation**: Real transaction hash + Etherscan link
7. **Balance Update**: Live balance refresh

## 🏆 Hackathon Impact

This setup gives you:
- ✅ **Real blockchain integration** (not just demo)
- 🌊 **Live streaming experience** (unique UX)
- 📊 **Professional transaction logs** (impressive demo)
- 🔗 **Verifiable results** on Etherscan (provable)

## 🚨 Important Notes

1. **Private Keys**: Currently hardcoded for demo - in production, use secure key management
2. **Gas Fees**: Transactions use real ETH for gas (small amounts on Sepolia)
3. **Rate Limits**: API includes reasonable rate limiting
4. **Error Handling**: Comprehensive error messages for debugging

## 📞 Support

If you encounter issues:
1. Check Vercel deployment logs
2. Verify environment variables are set
3. Test API endpoints individually
4. Check iOS app console for detailed logs

---

🎉 **You now have a complete real blockchain payment system with live streaming!** 