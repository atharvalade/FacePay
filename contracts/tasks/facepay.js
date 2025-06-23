const { task } = require("hardhat/config");

// PYUSD has 6 decimals
const PYUSD_DECIMALS = 6;
const MAX_APPROVAL = "115792089237316195423570985008687907853269984665640564039457584007913129639935"; // 2^256 - 1

// Helper function to format PYUSD amounts
function formatPYUSD(amount) {
  return (Number(amount) / Math.pow(10, PYUSD_DECIMALS)).toFixed(2);
}

function parsePYUSD(amount) {
  return (parseFloat(amount) * Math.pow(10, PYUSD_DECIMALS)).toString();
}

// Task: Check PYUSD balances
task("check-balances", "Check PYUSD balances for all wallets")
  .setAction(async (taskArgs, hre) => {
    const config = hre.config.facepay;
    
    // Use standard ERC-20 ABI
    const erc20Abi = [
      "function balanceOf(address account) external view returns (uint256)"
    ];
    
    const pyusdContract = new hre.ethers.Contract(
      config.pyusdAddress,
      erc20Abi,
      hre.ethers.provider
    );
    
    console.log("=== PYUSD Balances ===");
    
    for (const [name, address] of Object.entries(config.wallets)) {
      const balance = await pyusdContract.balanceOf(address);
      console.log(`${name.toUpperCase()}: ${formatPYUSD(balance)} PYUSD (${address})`);
    }
  });

// Task: Set approval for PaymentHub
task("set-approval", "Set PYUSD approval for PaymentHub contract")
  .addParam("user", "User to set approval for (user1, user2)")
  .addOptionalParam("amount", "Amount to approve (default: max)", "max")
  .setAction(async (taskArgs, hre) => {
    const config = hre.config.facepay;
    const userAddress = config.wallets[taskArgs.user];
    
    if (!userAddress) {
      throw new Error(`Invalid user: ${taskArgs.user}. Use user1 or user2`);
    }
    
    // Get PaymentHub address (you'll need to update this after deployment)
    const paymentHubAddress = process.env.PAYMENT_HUB_ADDRESS;
    if (!paymentHubAddress) {
      throw new Error("PAYMENT_HUB_ADDRESS not set. Deploy PaymentHub first.");
    }
    
    const approvalAmount = taskArgs.amount === "max" ? MAX_APPROVAL : parsePYUSD(taskArgs.amount);
    
    // Get signer for the user
    const [signer1, signer2] = await hre.ethers.getSigners();
    const signer = taskArgs.user === "user1" ? signer1 : signer2;
    
    // Use standard ERC-20 ABI
    const erc20Abi = [
      "function approve(address spender, uint256 amount) external returns (bool)",
      "function allowance(address owner, address spender) external view returns (uint256)",
      "function balanceOf(address account) external view returns (uint256)"
    ];
    
    const pyusdContract = new hre.ethers.Contract(
      config.pyusdAddress,
      erc20Abi,
      signer
    );
    
    console.log(`Setting approval for ${taskArgs.user} (${userAddress})...`);
    console.log(`Amount: ${taskArgs.amount === "max" ? "MAX" : taskArgs.amount} PYUSD`);
    console.log(`PaymentHub: ${paymentHubAddress}`);
    
    const tx = await pyusdContract.approve(paymentHubAddress, approvalAmount);
    console.log(`Transaction hash: ${tx.hash}`);
    
    await tx.wait();
    console.log("✅ Approval set successfully!");
    
    // Check new allowance
    const allowance = await pyusdContract.allowance(userAddress, paymentHubAddress);
    console.log(`New allowance: ${formatPYUSD(allowance)} PYUSD`);
  });

// Task: Check approvals
task("check-approvals", "Check PYUSD approvals for PaymentHub")
  .setAction(async (taskArgs, hre) => {
    const config = hre.config.facepay;
    const paymentHubAddress = process.env.PAYMENT_HUB_ADDRESS;
    
    if (!paymentHubAddress) {
      throw new Error("PAYMENT_HUB_ADDRESS not set. Deploy PaymentHub first.");
    }
    
    // Use standard ERC-20 ABI
    const erc20Abi = [
      "function allowance(address owner, address spender) external view returns (uint256)"
    ];
    
    const pyusdContract = new hre.ethers.Contract(
      config.pyusdAddress,
      erc20Abi,
      hre.ethers.provider
    );
    
    console.log("=== PYUSD Approvals for PaymentHub ===");
    console.log(`PaymentHub: ${paymentHubAddress}`);
    console.log("");
    
    for (const [name, address] of Object.entries(config.wallets)) {
      const allowance = await pyusdContract.allowance(address, paymentHubAddress);
      const isMax = allowance.toString() === MAX_APPROVAL;
      console.log(`${name.toUpperCase()}: ${isMax ? "MAX" : formatPYUSD(allowance)} PYUSD`);
    }
  });

// Task: Simulate payment
task("simulate-payment", "Simulate a payment transaction")
  .addParam("customer", "Customer address (user1 or user2)")
  .addParam("amount", "Amount to charge in PYUSD")
  .setAction(async (taskArgs, hre) => {
    const config = hre.config.facepay;
    const customerAddress = config.wallets[taskArgs.customer];
    const paymentHubAddress = process.env.PAYMENT_HUB_ADDRESS;
    
    if (!customerAddress) {
      throw new Error(`Invalid customer: ${taskArgs.customer}`);
    }
    
    if (!paymentHubAddress) {
      throw new Error("PAYMENT_HUB_ADDRESS not set. Deploy PaymentHub first.");
    }
    
    // Merchant signer (3rd signer)
    const [, , merchantSigner] = await hre.ethers.getSigners();
    
    // PaymentHub ABI
    const paymentHubAbi = [
      "function charge(address customer, uint256 amount) external"
    ];
    
    const paymentHub = new hre.ethers.Contract(
      paymentHubAddress,
      paymentHubAbi,
      merchantSigner
    );
    
    const amount = parsePYUSD(taskArgs.amount);
    
    console.log("=== Simulating Payment ===");
    console.log(`Customer: ${taskArgs.customer} (${customerAddress})`);
    console.log(`Merchant: ${config.wallets.merchant}`);
    console.log(`Amount: ${taskArgs.amount} PYUSD`);
    console.log("");
    
    // Check balances before
    const erc20AbiForBalance = [
      "function balanceOf(address account) external view returns (uint256)"
    ];
    
    const pyusdContract = new hre.ethers.Contract(
      config.pyusdAddress,
      erc20AbiForBalance,
      hre.ethers.provider
    );
    const customerBalanceBefore = await pyusdContract.balanceOf(customerAddress);
    const merchantBalanceBefore = await pyusdContract.balanceOf(config.wallets.merchant);
    
    console.log("Balances BEFORE:");
    console.log(`Customer: ${formatPYUSD(customerBalanceBefore)} PYUSD`);
    console.log(`Merchant: ${formatPYUSD(merchantBalanceBefore)} PYUSD`);
    console.log("");
    
    // Execute payment
    console.log("Executing payment...");
    const tx = await paymentHub.charge(customerAddress, amount);
    console.log(`Transaction hash: ${tx.hash}`);
    
    await tx.wait();
    console.log("✅ Payment successful!");
    
    // Check balances after
    const customerBalanceAfter = await pyusdContract.balanceOf(customerAddress);
    const merchantBalanceAfter = await pyusdContract.balanceOf(config.wallets.merchant);
    
    console.log("");
    console.log("Balances AFTER:");
    console.log(`Customer: ${formatPYUSD(customerBalanceAfter)} PYUSD`);
    console.log(`Merchant: ${formatPYUSD(merchantBalanceAfter)} PYUSD`);
  });

module.exports = {}; 