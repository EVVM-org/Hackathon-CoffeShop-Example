# EVVM CoffeeShop Example

![Solidity](https://img.shields.io/badge/Solidity-^0.8.0-363636?logo=solidity)
![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C?logo=foundry)
![Next.js](https://img.shields.io/badge/Next.js-15.3.3-black?logo=next.js)
![React](https://img.shields.io/badge/React-19.0.0-61DAFB?logo=react)

Complete implementation of an EVVM Service demonstrating a gasless transaction 
pattern where users sign off-chain and fishers execute on-chain with economic incentives.

## Overview

This is a full-stack example implementing the EVVM Service architecture, where:

- Users sign transactions off-chain without paying gas fees
- Users pay only for the service value, not computation
- Any participant can execute transactions as a "fisher" and earn rewards
- Service providers can stake tokens to earn automatic rewards

Documentation: [evvm.info/docs/HowToMakeAEVVMService](https://www.evvm.info/docs/HowToMakeAEVVMService)

## Project Structure

```
contracts/
  src/
    EVVMCafe.sol              # Main service contract
  script/
    EVVMCafe.s.sol            # Deployment script
  foundry.toml                # Foundry configuration
  makefile                    # Build and deploy commands

front/
  src/
    app/                      # Next.js app router
    components/
      CafeComponent.tsx       # Order flow component
      Ticket.tsx              # Receipt display
      VisualExecution.tsx     # Transaction preview
      ConnectButton.tsx       # Wallet connection
    config/index.ts           # Wagmi and AppKit setup
    context/index.tsx         # React context providers
    utils/                    # Helper functions
    constant/                 # ABI definitions and addresses
  package.json
  next.config.ts
```

## Architecture

### Smart Contract (EVVMCafe.sol)

Implements the EVVM Service pattern with the following core function:

```solidity
function orderCoffee(
    address clientAddress,
    string memory coffeeType,
    uint256 quantity,
    uint256 totalPrice,
    uint256 nonce,
    bytes memory signature,
    uint256 priorityFeePay,
    uint256 noncePay,
    bool isAsyncExecPay,
    bytes memory signaturePay
) external
```

This function:
1. Validates the customer signature
2. Prevents replay attacks using nonces
3. Processes payment through EVVM without gas fees
4. Distributes rewards to the transaction executor (fisher)
5. Records nonce usage

### Frontend Layer

Built with Next.js and React, providing:
- Wallet connection via Reown AppKit
- Off-chain signature generation using @evvm/viem-signature-library
- Real-time nonce management
- Transaction preview and receipt display

## Service Details

The contract implements a coffee ordering service with the following characteristics:

### Menu
| Item | Price |
|------|-------|
| Fisher Espresso | 0.001 ETH |
| Virtual Cappuccino | 0.002 ETH |
| Decentralized Latte | 0.003 ETH |
| Nonce Mocha | 0.0067 ETH |

### Core Functions

- `orderCoffee()` - Process a coffee order with EVVM payment
- `stake()` - Owner stakes tokens to earn automatic rewards
- `unstake()` - Owner unstakes tokens
- `withdrawRewards()` - Owner withdraws accumulated EVVM rewards
- `withdrawFunds()` - Owner withdraws accumulated ETH
- View functions for balances and configuration

## Installation

### Requirements

- Node.js >= 18.x
- Foundry (for smart contracts)
- Git

### Setup Smart Contracts

```bash
cd contracts
forge install
forge build
```

### Setup Frontend

```bash
cd front
npm install

# Create environment file
cp .env.example .env.local

# Add your Reown Project ID from https://dashboard.reown.com
```

### Run Development Server

```bash
npm run dev
```

Open http://localhost:3000 in your browser.

## Configuration

### Contract Addresses

Update addresses in `front/src/constant/address.json`:

```json
{
  "CafeAddress": "0xCea5836f0c56E4F9D5c535834FEc090aE1c6C859",
  "EVVMAddress": "0x9902984d86059234c3B6e11D5eAEC55f9627dD0f"
}
```

### Network Configuration

Default network is Sepolia testnet. To use a different network, 
update `front/src/config/index.ts`:

```typescript
import { mainnet, sepolia } from '@reown/appkit/networks'
export const networks = [mainnet, sepolia]
```

### Deployment

Deploy to Sepolia testnet using Foundry:

```bash
cd contracts

export RPC_URL_ETH_SEPOLIA=your_rpc_url
export ETHERSCAN_API=your_etherscan_api_key

make deployContract
```

## Key Concepts

### Signature Structure

The service uses two-level signing:

1. **Service Signature** (orderCoffee authorization)
   ```
   format: "<evvmID>,orderCoffee,<coffeeType>,<quantity>,<totalPrice>,<nonce>"
   signer: customer
   ```

2. **Payment Signature** (EVVM payment authorization)
   ```
   signer: customer
   includes: amount, nonce, priority fee, executor address
   ```

### Nonce Management

Two types of nonces are used:

- Sync nonces: Sequential (1, 2, 3...) - managed by EVVM
- Async nonces: Any unused number - managed by contract

This contract uses async nonces for flexibility in transaction ordering.

### Fisher Economics

When the coffee shop is registered as an EVVM staker, transaction executors 
(fishers) receive automatic rewards:

```solidity
if (evvm.isAddressStaker(address(this))) {
    // Priority fee payment
    makeCaPay(msg.sender, getEtherAddress(), priorityFeePay);
    
    // Half of EVVM generated rewards
    makeCaPay(msg.sender, getPrincipalTokenAddress(), 
              evvm.getRewardAmount() / 2);
}
```

## Component Details

### CafeComponent

Main ordering component managing the flow:
- Coffee selection and quantity input
- Price calculation
- Random nonce generation
- Signature creation and management
- EVVM integration

### Ticket

Displays order receipt with:
- Coffee details (type, quantity, price)
- Payment information
- Transaction signatures

### VisualExecution

Shows transaction data preview and execution interface.

## Usage Flow

### User Flow

1. Connect wallet using AppKit integration
2. Select coffee type and quantity
3. Review order and price details
4. Generate random nonce for transaction
5. Create signatures off-chain (no gas fees)
6. Review receipt with order and payment details
7. Execute transaction on blockchain
8. Fishers are incentivized to process the transaction

### Developer Flow

1. Customize coffee menu in CafeComponent.tsx
2. Adjust reward distribution in EVVMCafe.sol
3. Configure network in src/config/index.ts
4. Deploy contract using Foundry
5. Update contract addresses in constant/address.json

## Resources

### Official Documentation

- **[EVVM Official Docs](https://www.evvm.info/docs)** - Complete EVVM guide
- **[How to Make an EVVM Service](https://www.evvm.info/docs/HowToMakeAEVVMService)** - Detailed tutorial
- **[Signature Structures](https://www.evvm.info/docs/SignatureStructures/Overview)** - Signing guide

### Code References

- **EVVMCafe.sol** - Implementation example
- **CafeComponent.tsx** - Frontend integration
- **executeTransactionData.tsx** - Transaction execution

## Development

### Testing

```bash
# Contract tests
cd contracts
forge test

# Frontend tests
cd front
npm run test
```

### Customization

#### Add New Coffee Item

Edit `front/src/components/CafeComponent.tsx`:

```typescript
const coffePriceMap: { [key: string]: bigint } = {
  "Custom Coffee": BigInt(5000000000000000),  // 0.005 ETH
};
```

#### Modify Reward Distribution

Edit `contracts/src/EVVMCafe.sol` in orderCoffee function to change 
how rewards are distributed to fishers.

## Security

- All transactions require cryptographic signatures from users
- Nonces prevent replay attacks (each can only be used once)
- Only contract owner can withdraw funds and rewards
- EVVM handles payment validation
- Permission checks protect sensitive operations

## Contributing

### Reporting Issues

Open an issue on GitHub with:
- Clear title and description
- Steps to reproduce (for bugs)
- Environment details (Node version, OS)

### Submitting Changes

1. Fork and clone: `git clone https://github.com/your-username/Hackathon-CoffeShop-Example.git`
2. Create branch: `git checkout -b feature/description`
3. Make changes and test
4. Commit: `git commit -m 'Clear description'`
5. Push: `git push origin feature/description`
6. Open pull request

### Guidelines

- Reference issues: "Fixes #123"
- Include tests for new features
- Update documentation
- Follow existing code style
- Keep commits focused

Discuss major changes in an issue before starting work.

## License

MIT License - See LICENSE file

## References

- EVVM Website: https://evvm.info
- GitHub: https://github.com/EVVM-org

## FAQ

**Q: Do users pay gas fees?**
A: No. Users sign transactions off-chain without fees. Fishers execute 
on-chain and receive economic rewards.

**Q: What is a fisher?**
A: Any participant who executes EVVM transactions. Staker fishers receive 
automatic rewards; custom rewards can be configured for others.

**Q: How does the service provider earn revenue?**
A: The provider keeps all service payments (coffee prices). If registered 
as a staker, also earns EVVM protocol rewards.

**Q: What happens if no one executes a transaction?**
A: Fishers have economic incentives. Higher priority fees encourage faster 
execution and prioritization.

**Q: How can I customize pricing or rewards?**
A: Modify coffePriceMap in CafeComponent.tsx and adjust reward logic 
in EVVMCafe.sol orderCoffee function.
