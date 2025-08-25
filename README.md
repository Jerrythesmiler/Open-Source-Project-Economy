# 🚀 Open-Source Project Economy

> 💰 A decentralized bounty and royalty system for open-source contributors built on Stacks blockchain

## 🎯 Overview

The Open-Source Project Economy creates a sustainable business model for open-source development by enabling:
- 🎁 **Bounty Creation**: Fund specific features and bug fixes
- 📈 **Community Staking**: Prioritize features through token staking
- 🏆 **Automated Payouts**: Fair compensation for validated contributions
- 💎 **Royalty System**: Ongoing revenue sharing for project maintainers

## ✨ Features

### 🏗️ Project Management
- Register open-source projects with customizable royalty rates
- Set project metadata and repository links
- Enable/disable project participation

### 👥 Contributor System
- Register as a contributor with GitHub profile
- Build reputation through validated contributions
- Track earnings and contribution history

### 💎 Bounty Marketplace
- Create funded bounties for specific tasks
- Assign bounties to qualified contributors
- Validate contributions and automate payments

### 🪙 Staking & Prioritization
- Stake STX tokens on projects to show support
- Higher stakes = higher project priority
- Withdraw stakes when needed

## 🚀 Quick Start

### Prerequisites
- [Clarinet CLI](https://docs.hiro.so/clarinet) installed
- Stacks wallet with STX tokens

### Installation
```bash
git clone <repository-url>
cd Open-Source-Project-Economy
clarinet check
```

### Deployment
```bash
clarinet deploy --testnet
```

## 📚 Usage Guide

### 1️⃣ Register as a Contributor
```clarity
(contract-call? .Open-Source-Project-Economy register-contributor "your-github-username")
```

### 2️⃣ Register Your Project
```clarity
(contract-call? .Open-Source-Project-Economy register-project 
  "My Cool Project" 
  "A revolutionary open-source tool" 
  "https://github.com/user/project" 
  u15)  ;; 15% royalty rate
```

### 3️⃣ Create a Bounty
```clarity
;; First send STX to contract, then create bounty
(contract-call? .Open-Source-Project-Economy create-bounty 
  u1  ;; project-id
  "Fix critical bug in auth module"
  "Need to resolve authentication bypass vulnerability"
  u1000  ;; deadline (block height)
  "Rust, Security, Authentication")
```

### 4️⃣ Stake on Projects
```clarity
(contract-call? .Open-Source-Project-Economy stake-on-project 
  u1  ;; project-id
  u5000000)  ;; stake amount in microSTX
```

### 5️⃣ Submit Contributions
```clarity
(contract-call? .Open-Source-Project-Economy submit-contribution 
  u1  ;; bounty-id
  "https://github.com/user/project/pull/123")
```

### 6️⃣ Validate Contributions (Project Maintainers)
```clarity
(contract-call? .Open-Source-Project-Economy validate-contribution 
  u1  ;; contribution-id
  true)  ;; approved
```

## 🔍 Read-Only Functions

### Get Project Information
```clarity
(contract-call? .Open-Source-Project-Economy get-project u1)
```

### Check Contributor Profile
```clarity
(contract-call? .Open-Source-Project-Economy get-contributor 'SP1ABCD...)
```

### View Platform Statistics
```clarity
(contract-call? .Open-Source-Project-Economy get-platform-stats)
```

### Calculate Priority Score
```clarity
(contract-call? .Open-Source-Project-Economy get-project-priority-score u1)
```

## 💡 How It Works

### 🔄 Bounty Lifecycle
1. **Creation**: Maintainer creates bounty with STX funding
2. **Assignment**: Contributors can be assigned to bounties
3. **Submission**: Contributors submit work via GitHub URLs
4. **Validation**: Project maintainers approve/reject submissions
5. **Payment**: Approved contributions trigger automatic STX transfer

### 🏅 Reputation System
- Contributors earn reputation points for approved contributions
- Higher reputation = higher priority for bounty assignments
- Verified contributors get additional benefits

### 📊 Staking Mechanism
- Community members stake STX on projects they support
- Higher total stakes = higher project visibility
- Stakes can be withdrawn at any time

### 💰 Revenue Distribution
- Bounty payments go directly to contributors
- Project royalties distributed to maintainers
- 5% platform fee on all transactions

## 🛡️ Security Features

- **Authorization checks** for all critical operations
- **Input validation** for all user-provided data
- **Safe STX transfers** with proper error handling
- **Emergency pause** functionality for projects
- **Contribution verification** by project maintainers

## 🎛️ Configuration

### Royalty Rates
- Maximum royalty percentage: 25%
- Set during project registration
- Cannot be changed after registration

### Staking Requirements
- Minimum stake amount: 1 STX (1,000,000 microSTX)
- No maximum stake limit
- Stakes earn priority points

## 🧪 Testing

```bash
clarinet test
```

## 📖 API Reference

### Core Functions
- `register-project`: Register new open-source project
- `register-contributor`: Register as a contributor
- `create-bounty`: Create funded development bounty
- `stake-on-project`: Stake tokens to support project
- `submit-contribution`: Submit work for bounty
- `validate-contribution`: Approve/reject contributions
- `distribute-royalties`: Distribute earnings to maintainers

### Query Functions
- `get-project`: Retrieve project details
- `get-contributor`: Get contributor profile
- `get-bounty`: View bounty information
- `get-platform-stats`: Platform-wide statistics

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Submit contributions via the platform
4. Earn STX rewards for approved work!

## 📄 License

MIT License - Build the future of open-source economics!

---

*Built with ❤️ for the open-source community*
