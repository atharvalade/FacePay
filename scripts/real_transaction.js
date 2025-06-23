#!/usr/bin/env node

/**
 * Real Blockchain Transaction Script for FacePay
 * This script executes actual PYUSD transfers on Sepolia testnet
 * Usage: node real_transaction.js <from_address> <to_address> <amount> <private_key>
 */

const { ethers } = require('ethers');

// Sepolia configuration
const SEPOLIA_RPC = "https://sepolia.infura.io/v3/40f21c9a3e114c7d880efefc7d9b04be";
const PYUSD_ADDRESS = "0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9";
const CHAIN_ID = 11155111;

// ERC20 ABI for transfer function
const ERC20_ABI = [
    "function transfer(address to, uint256 amount) returns (bool)",
    "function balanceOf(address account) view returns (uint256)",
    "function decimals() view returns (uint8)"
];

async function executeRealTransaction() {
    try {
        // Parse command line arguments
        const args = process.argv.slice(2);
        if (args.length !== 4) {
            console.error("Usage: node real_transaction.js <from_address> <to_address> <amount> <private_key>");
            process.exit(1);
        }

        const [fromAddress, toAddress, amount, privateKey] = args;
        
        console.log("🚀 EXECUTING REAL BLOCKCHAIN TRANSACTION");
        console.log("=====================================");
        console.log(`From: ${fromAddress}`);
        console.log(`To: ${toAddress}`);
        console.log(`Amount: ${amount} PYUSD`);
        console.log(`Network: Sepolia Testnet`);
        console.log("");

        // Setup provider and wallet
        const provider = new ethers.JsonRpcProvider(SEPOLIA_RPC);
        const wallet = new ethers.Wallet(privateKey, provider);
        
        console.log("✅ Wallet connected");
        console.log(`   Address: ${wallet.address}`);
        
        // Verify from address matches wallet
        if (wallet.address.toLowerCase() !== fromAddress.toLowerCase()) {
            throw new Error("Private key does not match from address");
        }

        // Connect to PYUSD contract
        const pyusdContract = new ethers.Contract(PYUSD_ADDRESS, ERC20_ABI, wallet);
        
        console.log("✅ Connected to PYUSD contract");
        console.log(`   Contract: ${PYUSD_ADDRESS}`);

        // Check balance
        const decimals = await pyusdContract.decimals();
        const balance = await pyusdContract.balanceOf(fromAddress);
        const balanceFormatted = ethers.formatUnits(balance, decimals);
        
        console.log(`   Balance: ${balanceFormatted} PYUSD`);

        // Convert amount to wei
        const amountWei = ethers.parseUnits(amount, decimals);
        
        console.log("💳 Preparing transaction...");
        console.log(`   Amount (wei): ${amountWei.toString()}`);

        // Check if sufficient balance
        if (balance < amountWei) {
            throw new Error(`Insufficient balance. Have ${balanceFormatted}, need ${amount}`);
        }

        // Get current network conditions
        const feeData = await provider.getFeeData();
        const nonce = await provider.getTransactionCount(fromAddress);
        
        console.log("📊 Network conditions:");
        console.log(`   Nonce: ${nonce}`);
        console.log(`   Gas Price: ${ethers.formatUnits(feeData.gasPrice, 'gwei')} Gwei`);

        // Execute the transfer
        console.log("🔐 Signing and submitting transaction...");
        
        const tx = await pyusdContract.transfer(toAddress, amountWei, {
            gasLimit: 90000,
            gasPrice: feeData.gasPrice
        });

        console.log("✅ TRANSACTION SUBMITTED!");
        console.log(`   Transaction Hash: ${tx.hash}`);
        console.log(`   Etherscan: https://sepolia.etherscan.io/tx/${tx.hash}`);

        // Wait for confirmation
        console.log("⏳ Waiting for confirmation...");
        const receipt = await tx.wait();

        console.log("🎉 TRANSACTION CONFIRMED!");
        console.log(`   Block: ${receipt.blockNumber}`);
        console.log(`   Gas Used: ${receipt.gasUsed.toString()}`);
        console.log(`   Status: ${receipt.status === 1 ? 'Success' : 'Failed'}`);

        // Output JSON result for iOS app
        const result = {
            success: true,
            txHash: tx.hash,
            blockNumber: receipt.blockNumber,
            gasUsed: receipt.gasUsed.toString(),
            explorerUrl: `https://sepolia.etherscan.io/tx/${tx.hash}`
        };

        console.log("\n" + JSON.stringify(result));
        
    } catch (error) {
        console.error("❌ TRANSACTION FAILED:");
        console.error(error.message);
        
        const result = {
            success: false,
            error: error.message
        };
        
        console.log("\n" + JSON.stringify(result));
        process.exit(1);
    }
}

// Execute if called directly
if (require.main === module) {
    executeRealTransaction();
}

module.exports = { executeRealTransaction }; 