// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

/**
 * @title PaymentHub
 * @dev Handles face-based PYUSD payments for FacePay app
 * @author FacePay Team
 */
contract PaymentHub {
    IERC20 public immutable pyusd;
    
    // Events
    event Charged(
        address indexed customer,
        address indexed merchant, 
        uint256 amount,
        uint256 timestamp
    );
    
    event ApprovalSet(
        address indexed user,
        uint256 amount
    );
    
    // Errors
    error InsufficientBalance();
    error InsufficientAllowance();
    error TransferFailed();
    error ZeroAmount();
    error ZeroAddress();
    
    /**
     * @dev Constructor sets the PYUSD contract address
     * @param _pyusdAddress Address of PYUSD contract on Sepolia
     */
    constructor(address _pyusdAddress) {
        if (_pyusdAddress == address(0)) revert ZeroAddress();
        pyusd = IERC20(_pyusdAddress);
    }
    
    /**
     * @dev Charge a customer for a purchase
     * @param customer Address of the customer to charge
     * @param amount Amount of PYUSD to charge (in wei, 6 decimals for PYUSD)
     */
    function charge(address customer, uint256 amount) external {
        if (customer == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        
        address merchant = msg.sender;
        
        // Check customer has sufficient balance
        uint256 customerBalance = pyusd.balanceOf(customer);
        if (customerBalance < amount) revert InsufficientBalance();
        
        // Check allowance
        uint256 allowance = pyusd.allowance(customer, address(this));
        if (allowance < amount) revert InsufficientAllowance();
        
        // Transfer PYUSD from customer to merchant
        bool success = pyusd.transferFrom(customer, merchant, amount);
        if (!success) revert TransferFailed();
        
        // Emit event
        emit Charged(customer, merchant, amount, block.timestamp);
    }
    
    /**
     * @dev Check if customer has approved sufficient amount
     * @param customer Customer address
     * @param amount Amount to check
     * @return bool Whether customer has approved sufficient amount
     */
    function hasApproval(address customer, uint256 amount) external view returns (bool) {
        return pyusd.allowance(customer, address(this)) >= amount;
    }
    
    /**
     * @dev Get customer's PYUSD balance
     * @param customer Customer address
     * @return uint256 Customer's PYUSD balance
     */
    function getBalance(address customer) external view returns (uint256) {
        return pyusd.balanceOf(customer);
    }
    
    /**
     * @dev Get customer's allowance for this contract
     * @param customer Customer address
     * @return uint256 Customer's allowance for this contract
     */
    function getAllowance(address customer) external view returns (uint256) {
        return pyusd.allowance(customer, address(this));
    }
} 