const express = require('express');
const cors = require('cors');
const { ethers } = require('ethers');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Configuration
const SEPOLIA_RPC = process.env.SEPOLIA_RPC || "https://sepolia.infura.io/v3/40f21c9a3e114c7d880efefc7d9b04be";
const PYUSD_ADDRESS = "0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9";
const CHAIN_ID = 11155111;

// ERC20 ABI for transfer function
const ERC20_ABI = [
    "function transfer(address to, uint256 amount) returns (bool)",
    "function balanceOf(address account) view returns (uint256)",
    "function decimals() view returns (uint8)"
];

// Helper function to send Server-Sent Events
function sendEvent(res, event, data) {
    res.write(`event: ${event}\n`);
    res.write(`data: ${JSON.stringify(data)}\n\n`);
}

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Get balance endpoint
app.get('/balance/:address', async (req, res) => {
    try {
        const { address } = req.params;
        
        const provider = new ethers.JsonRpcProvider(SEPOLIA_RPC);
        const pyusdContract = new ethers.Contract(PYUSD_ADDRESS, ERC20_ABI, provider);
        
        const balance = await pyusdContract.balanceOf(address);
        const decimals = await pyusdContract.decimals();
        const balanceFormatted = ethers.formatUnits(balance, decimals);
        
        res.json({
            success: true,
            address,
            balance: balanceFormatted,
            balanceWei: balance.toString()
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Real-time blockchain transaction endpoint with streaming
app.post('/transaction/stream', async (req, res) => {
    const { fromAddress, toAddress, amount, privateKey } = req.body;
    
    // Validate required fields
    if (!fromAddress || !toAddress || !amount || !privateKey) {
        return res.status(400).json({
            success: false,
            error: 'Missing required fields: fromAddress, toAddress, amount, privateKey'
        });
    }
    
    // Set up Server-Sent Events
    res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Cache-Control'
    });
    
    try {
        // Start streaming logs
        sendEvent(res, 'log', {
            type: 'info',
            message: '🚀 EXECUTING REAL BLOCKCHAIN TRANSACTION',
            timestamp: new Date().toISOString()
        });
        
        sendEvent(res, 'log', {
            type: 'info',
            message: `From: ${fromAddress}`,
            timestamp: new Date().toISOString()
        });
        
        sendEvent(res, 'log', {
            type: 'info',
            message: `To: ${toAddress}`,
            timestamp: new Date().toISOString()
        });
        
        sendEvent(res, 'log', {
            type: 'info',
            message: `Amount: ${amount} PYUSD`,
            timestamp: new Date().toISOString()
        });
        
        sendEvent(res, 'log', {
            type: 'info',
            message: 'Network: Sepolia Testnet',
            timestamp: new Date().toISOString()
        });
        
        // Setup provider and wallet
        sendEvent(res, 'log', {
            type: 'info',
            message: '⚙️ Setting up wallet connection...',
            timestamp: new Date().toISOString()
        });
        
        const provider = new ethers.JsonRpcProvider(SEPOLIA_RPC);
        const wallet = new ethers.Wallet(privateKey, provider);
        
        sendEvent(res, 'log', {
            type: 'success',
            message: `✅ Wallet connected: ${wallet.address}`,
            timestamp: new Date().toISOString()
        });
        
        // Verify from address matches wallet
        if (wallet.address.toLowerCase() !== fromAddress.toLowerCase()) {
            throw new Error("Private key does not match from address");
        }
        
        // Connect to PYUSD contract
        sendEvent(res, 'log', {
            type: 'info',
            message: '📄 Connecting to PYUSD contract...',
            timestamp: new Date().toISOString()
        });
        
        const pyusdContract = new ethers.Contract(PYUSD_ADDRESS, ERC20_ABI, wallet);
        
        sendEvent(res, 'log', {
            type: 'success',
            message: `✅ Connected to PYUSD: ${PYUSD_ADDRESS}`,
            timestamp: new Date().toISOString()
        });
        
        // Check balance
        sendEvent(res, 'log', {
            type: 'info',
            message: '💰 Checking balance...',
            timestamp: new Date().toISOString()
        });
        
        const decimals = await pyusdContract.decimals();
        const balance = await pyusdContract.balanceOf(fromAddress);
        const balanceFormatted = ethers.formatUnits(balance, decimals);
        
        sendEvent(res, 'log', {
            type: 'info',
            message: `Balance: ${balanceFormatted} PYUSD`,
            timestamp: new Date().toISOString()
        });
        
        // Convert amount to wei
        const amountWei = ethers.parseUnits(amount, decimals);
        
        sendEvent(res, 'log', {
            type: 'info',
            message: `Amount (wei): ${amountWei.toString()}`,
            timestamp: new Date().toISOString()
        });
        
        // Check if sufficient balance
        if (balance < amountWei) {
            throw new Error(`Insufficient balance. Have ${balanceFormatted}, need ${amount}`);
        }
        
        // Get current network conditions
        sendEvent(res, 'log', {
            type: 'info',
            message: '📊 Getting network conditions...',
            timestamp: new Date().toISOString()
        });
        
        const feeData = await provider.getFeeData();
        const nonce = await provider.getTransactionCount(fromAddress);
        
        sendEvent(res, 'log', {
            type: 'info',
            message: `Nonce: ${nonce}`,
            timestamp: new Date().toISOString()
        });
        
        sendEvent(res, 'log', {
            type: 'info',
            message: `Gas Price: ${ethers.formatUnits(feeData.gasPrice, 'gwei')} Gwei`,
            timestamp: new Date().toISOString()
        });
        
        // Execute the transfer
        sendEvent(res, 'log', {
            type: 'info',
            message: '🔐 Signing and submitting transaction...',
            timestamp: new Date().toISOString()
        });
        
        const tx = await pyusdContract.transfer(toAddress, amountWei, {
            gasLimit: 90000,
            gasPrice: feeData.gasPrice
        });
        
        sendEvent(res, 'log', {
            type: 'success',
            message: '✅ TRANSACTION SUBMITTED!',
            timestamp: new Date().toISOString()
        });
        
        sendEvent(res, 'log', {
            type: 'success',
            message: `Transaction Hash: ${tx.hash}`,
            timestamp: new Date().toISOString()
        });
        
        sendEvent(res, 'log', {
            type: 'info',
            message: `🔗 Etherscan: https://sepolia.etherscan.io/tx/${tx.hash}`,
            timestamp: new Date().toISOString()
        });
        
        // Wait for confirmation
        sendEvent(res, 'log', {
            type: 'info',
            message: '⏳ Waiting for confirmation...',
            timestamp: new Date().toISOString()
        });
        
        const receipt = await tx.wait();
        
        sendEvent(res, 'log', {
            type: 'success',
            message: '🎉 TRANSACTION CONFIRMED!',
            timestamp: new Date().toISOString()
        });
        
        sendEvent(res, 'log', {
            type: 'success',
            message: `Block: ${receipt.blockNumber}`,
            timestamp: new Date().toISOString()
        });
        
        sendEvent(res, 'log', {
            type: 'success',
            message: `Gas Used: ${receipt.gasUsed.toString()}`,
            timestamp: new Date().toISOString()
        });
        
        sendEvent(res, 'log', {
            type: 'success',
            message: `Status: ${receipt.status === 1 ? 'Success' : 'Failed'}`,
            timestamp: new Date().toISOString()
        });
        
        // Send final result
        sendEvent(res, 'result', {
            success: true,
            txHash: tx.hash,
            blockNumber: receipt.blockNumber,
            gasUsed: receipt.gasUsed.toString(),
            explorerUrl: `https://sepolia.etherscan.io/tx/${tx.hash}`,
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        sendEvent(res, 'log', {
            type: 'error',
            message: `❌ TRANSACTION FAILED: ${error.message}`,
            timestamp: new Date().toISOString()
        });
        
        sendEvent(res, 'result', {
            success: false,
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
    
    res.end();
});

// Simple transaction endpoint (without streaming)
app.post('/transaction', async (req, res) => {
    const { fromAddress, toAddress, amount, privateKey } = req.body;
    
    try {
        const provider = new ethers.JsonRpcProvider(SEPOLIA_RPC);
        const wallet = new ethers.Wallet(privateKey, provider);
        
        if (wallet.address.toLowerCase() !== fromAddress.toLowerCase()) {
            throw new Error("Private key does not match from address");
        }
        
        const pyusdContract = new ethers.Contract(PYUSD_ADDRESS, ERC20_ABI, wallet);
        const decimals = await pyusdContract.decimals();
        const amountWei = ethers.parseUnits(amount, decimals);
        
        const feeData = await provider.getFeeData();
        
        const tx = await pyusdContract.transfer(toAddress, amountWei, {
            gasLimit: 90000,
            gasPrice: feeData.gasPrice
        });
        
        const receipt = await tx.wait();
        
        res.json({
            success: true,
            txHash: tx.hash,
            blockNumber: receipt.blockNumber,
            gasUsed: receipt.gasUsed.toString(),
            explorerUrl: `https://sepolia.etherscan.io/tx/${tx.hash}`
        });
        
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

app.listen(PORT, () => {
    console.log(`🚀 FacePay API server running on port ${PORT}`);
    console.log(`📡 Health check: http://localhost:${PORT}/health`);
});

module.exports = app; 