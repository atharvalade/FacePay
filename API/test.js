// Simple test script for FacePay API
const TEST_CONFIG = {
    fromAddress: '0x9f93EebD463d4B7c991986a082d974E77b5a02Dc',
    toAddress: '0x27A7A44250C6Eb3C84d1d894c8A601742827C7C7', 
    amount: '0.1',
    privateKey: '15953296e322c945eaa0c215f8740fcdb1cb18231d19e477efa91ae4310becdf'
};

console.log('FacePay API Test Configuration:');
console.log('From:', TEST_CONFIG.fromAddress);
console.log('To:', TEST_CONFIG.toAddress);
console.log('Amount:', TEST_CONFIG.amount, 'PYUSD');
console.log('\nReady for testing!'); 