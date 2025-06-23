const express = require('express');
const cors = require('cors');
const { ethers } = require('ethers');
const multer = require('multer');
const faceRecognition = require('./faceRecognition');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Configure multer for image uploads
const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 10 * 1024 * 1024 // 10MB limit
    }
});

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

// Initialize face recognition models on startup
let modelsLoaded = false;
async function initializeFaceRecognition() {
    try {
        console.log('🤖 Initializing face-api.js models...');
        await faceRecognition.loadModels();
        modelsLoaded = true;
        console.log('✅ Face recognition ready!');
    } catch (error) {
        console.error('❌ Face recognition initialization failed:', error);
    }
}

// Initialize on startup
initializeFaceRecognition();

// Helper function to send Server-Sent Events
function sendEvent(res, event, data) {
    res.write(`event: ${event}\n`);
    res.write(`data: ${JSON.stringify(data)}\n\n`);
}

// Health check endpoint
app.get('/health', (req, res) => {
    const faceStatus = faceRecognition.getStatus();
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        faceRecognition: {
            ready: faceStatus.modelsLoaded,
            method: faceStatus.method,
            fallbackMode: faceStatus.fallbackMode,
            faceCount: faceStatus.faceCount
        }
    });
});

// Face Recognition Endpoints

// Register face endpoint
app.post('/face/register', upload.single('image'), async (req, res) => {
    try {
        if (!modelsLoaded) {
            return res.status(503).json({ error: 'Face recognition models not ready' });
        }

        const { walletAddress, userName } = req.body;
        
        if (!req.file) {
            return res.status(400).json({ error: 'No image file provided' });
        }

        if (!walletAddress) {
            return res.status(400).json({ error: 'Wallet address required' });
        }

        console.log(`👤 Registering face for wallet: ${walletAddress}`);
        
        const result = await faceRecognition.registerFace(
            walletAddress, 
            req.file.buffer,
            userName || 'User'
        );

        res.json({
            success: true,
            walletAddress: result.walletAddress,
            confidence: result.confidence,
            message: 'Face registered successfully'
        });

    } catch (error) {
        console.error('❌ Face registration error:', error);
        res.status(400).json({ 
            error: error.message || 'Face registration failed' 
        });
    }
});

// Face matching endpoint
app.post('/face/match', upload.single('image'), async (req, res) => {
    try {
        if (!modelsLoaded) {
            return res.status(503).json({ error: 'Face recognition models not ready' });
        }

        if (!req.file) {
            return res.status(400).json({ error: 'No image file provided' });
        }

        console.log('🔍 Processing face match request...');
        
        const match = await faceRecognition.findBestMatch(req.file.buffer, 0.6);

        if (match) {
            res.json({
                success: true,
                match: {
                    walletAddress: match.walletAddress,
                    userName: match.userName,
                    confidence: match.similarity,
                    distance: match.distance
                }
            });
        } else {
            res.json({
                success: false,
                message: 'No matching face found'
            });
        }

    } catch (error) {
        console.error('❌ Face matching error:', error);
        res.status(400).json({ 
            error: error.message || 'Face matching failed' 
        });
    }
});

// Load face database endpoint (for external face data)
app.post('/face/load-database', async (req, res) => {
    try {
        const { faceEmbeddings } = req.body;
        
        if (!Array.isArray(faceEmbeddings)) {
            return res.status(400).json({ error: 'faceEmbeddings must be an array' });
        }

        await faceRecognition.loadFaceDatabase(faceEmbeddings);
        
        res.json({
            success: true,
            loadedCount: faceEmbeddings.length,
            totalFaces: faceRecognition.getFaceCount()
        });

    } catch (error) {
        console.error('❌ Database load error:', error);
        res.status(500).json({ 
            error: error.message || 'Failed to load face database' 
        });
    }
});

// Get face database info
app.get('/face/info', (req, res) => {
    const status = faceRecognition.getStatus();
    res.json({
        ...status,
        faces: faceRecognition.getAllFaces().map(face => ({
            walletAddress: face.walletAddress,
            userName: face.userName,
            registrationDate: face.registrationDate,
            isNeural: face.isNeural
        }))
    });
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