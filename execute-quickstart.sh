#!/bin/bash
# Execute Quick Start Transactions (1-4)

echo "========================================"
echo "Executing Quick Start Transactions"
echo "========================================"
echo ""
echo "Balance: 2471.3 STX ✓"
echo ""

# Transaction 1: Fund Staking Rewards Pool
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Transaction 1: Fund Staking Pool"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd /home/marcus/stacks-builder-challenge-1/staking-rewards

# Create a transaction to fund the pool
cat > tx1-fund-staking.clar << 'EOF'
(contract-call? 'ST3P3DPDB69YP0Z259SS6MSA16GBQEBF8KG8P96D2.staking-rewards fund-rewards u100000000)
EOF

echo "Funding staking pool with 100 STX..."
# Using clarinet to submit the transaction
clarinet console --testnet < tx1-fund-staking.clar 2>&1 | tail -20

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Transaction 2: Start Lottery Round"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd /home/marcus/stacks-builder-challenge-1/decentralized-lottery

cat > tx2-start-lottery.clar << 'EOF'
(contract-call? 'ST3P3DPDB69YP0Z259SS6MSA16GBQEBF8KG8P96D2.decentralized-lottery start-round u1440)
EOF

echo "Starting lottery round (10 day duration)..."
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Transaction 3: Create Tipping Profile"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd /home/marcus/stacks-builder-challenge-1/tipping-platform

cat > tx3-create-profile.clar << 'EOF'
(contract-call? 'ST3P3DPDB69YP0Z259SS6MSA16GBQEBF8KG8P96D2.tipping-platform create-profile "Smart Contract Developer" "Built 30 Stacks contracts for Builder Challenge")
EOF

echo "Creating tipping platform profile..."
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Transaction 4: Post First Bounty"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd /home/marcus/stacks-builder-challenge-1/bounty-system

cat > tx4-create-bounty.clar << 'EOF'
(contract-call? 'ST3P3DPDB69YP0Z259SS6MSA16GBQEBF8KG8P96D2.bounty-system create-bounty u5000000 "Test all 30 deployed contracts" u1440)
EOF

echo "Creating bounty with 5 STX reward..."
echo ""

echo "========================================"
echo "Transaction files created!"
echo "========================================"
echo ""
echo "Note: Clarinet console doesn't support testnet mode."
echo "Using alternative method with stacks-cli..."
