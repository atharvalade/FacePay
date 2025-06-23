require("@nomicfoundation/hardhat-toolbox");
require("./tasks/facepay.js");
require("dotenv").config();

// Load private keys from environment variables (add 0x prefix if missing)
function formatPrivateKey(key) {
  if (!key) return undefined;
  return key.startsWith('0x') ? key : `0x${key}`;
}

const USER1_PRIVATE_KEY = formatPrivateKey(process.env.USER1_PRIVATE_KEY);
const USER2_PRIVATE_KEY = formatPrivateKey(process.env.USER2_PRIVATE_KEY);
const MERCHANT_PRIVATE_KEY = formatPrivateKey(process.env.MERCHANT_PRIVATE_KEY);

// Validate required environment variables for network operations
if (process.argv.includes('--network') && (process.argv.includes('sepolia'))) {
  if (!USER1_PRIVATE_KEY || !USER2_PRIVATE_KEY || !MERCHANT_PRIVATE_KEY) {
    console.error("❌ Missing required private keys in .env file");
    console.error("Required: USER1_PRIVATE_KEY, USER2_PRIVATE_KEY, MERCHANT_PRIVATE_KEY");
    process.exit(1);
  }
}

// Contract addresses
const PYUSD_SEPOLIA = "0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    sepolia: {
      url: process.env.INFURA_API_KEY 
        ? `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`
        : "https://sepolia.infura.io/v3/YOUR_INFURA_KEY",
      accounts: [USER1_PRIVATE_KEY, USER2_PRIVATE_KEY, MERCHANT_PRIVATE_KEY].filter(Boolean),
      chainId: 11155111,
      gasPrice: 20000000000, // 20 gwei
    },
    hardhat: {
      chainId: 1337
    }
  },
  // Custom config for FacePay
  facepay: {
    pyusdAddress: PYUSD_SEPOLIA,
    wallets: {
      user1: "0x9f93EebD463d4B7c991986a082d974E77b5a02Dc",
      user2: "0xa999F0CB16b55516BD82fd77Dc19f495b41f0770", 
      merchant: "0x27A7A44250C6Eb3C84d1d894c8A601742827C7C7"
    }
  }
};
