# FacePay API Server

Real-time blockchain transaction API with streaming logs.

## Features

- ✅ Real Sepolia blockchain transactions
- 🚀 Server-Sent Events for real-time logging
- 💰 PYUSD balance checking
- 🔗 Etherscan integration

## API Endpoints

### GET /health
Health check endpoint

### GET /balance/:address
Get PYUSD balance for an address

### POST /transaction/stream
Execute real blockchain transaction with streaming logs

### POST /transaction
Execute real blockchain transaction (simple response)

## Vercel Deployment

1. Push this API folder to GitHub
2. Connect to Vercel
3. Set environment variables in Vercel dashboard:
   - `SEPOLIA_RPC`: Your Infura Sepolia endpoint
4. Deploy!

## Local Development

```bash
npm install
npm start
```

## Environment Variables

```
SEPOLIA_RPC=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
PORT=3000
```

## Usage Example

```javascript
// Streaming transaction
const response = await fetch('https://your-api.vercel.app/transaction/stream', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    fromAddress: '0x...',
    toAddress: '0x...',
    amount: '1.0',
    privateKey: 'your_private_key'
  })
});

const reader = response.body.getReader();
// Process streaming logs...
``` 