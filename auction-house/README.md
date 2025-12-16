# Auction House - NFT/Asset Auction System

Create auctions for NFTs and digital assets with bidding and automatic settlement.

## Features

- **English Auctions**: Highest bid wins
- **Dutch Auctions**: Price decreases over time
- **Reserve Price**: Set minimum acceptable price
- **Bid Tracking**: Track all bids and bidders
- **Auto Settlement**: Settle auctions on-chain
- **Platform Fees**: 2.5% fee on successful sales

## Key Functions

### create-auction
Create a new auction with starting price, reserve, and duration.

### place-bid
Place a bid on an active auction.

### settle-auction
Settle auction after end time and distribute funds.

### cancel-auction
Cancel auction if no bids placed.

## Auction Types

- **English**: Traditional ascending price auction
- **Dutch**: Descending price auction (price drops over time)

## Deployment

```bash
clarinet check
clarinet deploy --testnet
```
