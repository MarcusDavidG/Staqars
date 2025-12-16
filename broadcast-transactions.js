#!/usr/bin/env node
// Execute Quick Start Transactions using @stacks/transactions

const {
  makeContractCall,
  broadcastTransaction,
  AnchorMode,
  stringAsciiCV,
  uintCV,
  createStacksPrivateKey,
  getAddressFromPrivateKey,
  TransactionVersion,
} = require('@stacks/transactions');

const MNEMONIC = "tube school delay discover broom gallery ahead arena ceiling kid biology spell bachelor section initial wall join public major aisle question hotel maid hurt";
const network = {
  coreApiUrl: 'https://api.testnet.hiro.so',
  version: TransactionVersion.Testnet,
};

async function getPrivateKey() {
  // Derive private key from mnemonic using BIP39
  const bip39 = require('bip39');
  const { HDKey } = require('micro-stacks/crypto');
  
  const seed = await bip39.mnemonicToSeed(MNEMONIC);
  const root = HDKey.fromMasterSeed(seed);
  const child = root.derive("m/44'/5757'/0'/0/0");
  
  return child.privateKey.toString('hex');
}

async function executeTransactions() {
  console.log('========================================');
  console.log('Executing Quick Start Transactions');
  console.log('========================================\n');
  
  const senderKey = await getPrivateKey();
  const address = 'ST3P3DPDB69YP0Z259SS6MSA16GBQEBF8KG8P96D2';
  
  try {
    // Transaction 1: Fund Staking Pool
    console.log('1️⃣  Funding Staking Pool (100 STX)...');
    const tx1 = await makeContractCall({
      network,
      anchorMode: AnchorMode.Any,
      contractAddress: address,
      contractName: 'staking-rewards',
      functionName: 'fund-rewards',
      functionArgs: [uintCV(100000000)],
      senderKey,
      fee: 10000,
    });
    
    const result1 = await broadcastTransaction(tx1, network);
    console.log(`   ✓ TX ID: ${result1.txid}`);
    console.log(`   🔗 https://explorer.hiro.so/txid/${result1.txid}?chain=testnet\n`);
    
    // Wait a bit between transactions
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Transaction 2: Start Lottery
    console.log('2️⃣  Starting Lottery Round...');
    const tx2 = await makeContractCall({
      network,
      anchorMode: AnchorMode.Any,
      contractAddress: address,
      contractName: 'decentralized-lottery',
      functionName: 'start-round',
      functionArgs: [uintCV(1440)],
      senderKey,
      fee: 10000,
    });
    
    const result2 = await broadcastTransaction(tx2, network);
    console.log(`   ✓ TX ID: ${result2.txid}`);
    console.log(`   🔗 https://explorer.hiro.so/txid/${result2.txid}?chain=testnet\n`);
    
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Transaction 3: Create Tipping Profile
    console.log('3️⃣  Creating Tipping Profile...');
    const tx3 = await makeContractCall({
      network,
      anchorMode: AnchorMode.Any,
      contractAddress: address,
      contractName: 'tipping-platform',
      functionName: 'create-profile',
      functionArgs: [
        stringAsciiCV('Smart Contract Developer'),
        stringAsciiCV('Built 30 Stacks contracts for Builder Challenge')
      ],
      senderKey,
      fee: 10000,
    });
    
    const result3 = await broadcastTransaction(tx3, network);
    console.log(`   ✓ TX ID: ${result3.txid}`);
    console.log(`   🔗 https://explorer.hiro.so/txid/${result3.txid}?chain=testnet\n`);
    
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Transaction 4: Create Bounty
    console.log('4️⃣  Creating First Bounty (5 STX)...');
    const tx4 = await makeContractCall({
      network,
      anchorMode: AnchorMode.Any,
      contractAddress: address,
      contractName: 'bounty-system',
      functionName: 'create-bounty',
      functionArgs: [
        uintCV(5000000),
        stringAsciiCV('Test all 30 deployed contracts'),
        uintCV(1440)
      ],
      senderKey,
      fee: 10000,
    });
    
    const result4 = await broadcastTransaction(tx4, network);
    console.log(`   ✓ TX ID: ${result4.txid}`);
    console.log(`   🔗 https://explorer.hiro.so/txid/${result4.txid}?chain=testnet\n`);
    
    console.log('========================================');
    console.log('✅ All 4 Transactions Broadcast!');
    console.log('========================================');
    console.log('\n📊 Summary:');
    console.log('  • Staking Pool: Funded with 100 STX');
    console.log('  • Lottery: Round #1 Started');  
    console.log('  • Tipping: Profile Created');
    console.log('  • Bounty: 5 STX bounty posted');
    console.log('\n⏳ Transactions will confirm in ~10 minutes');
    console.log('🔗 Check status on explorer using links above');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
  }
}

executeTransactions();
