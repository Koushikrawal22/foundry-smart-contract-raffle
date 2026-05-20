# Foundry Smart Contract Raffle

A decentralized raffle/lottery smart contract built using Solidity, Foundry, and Chainlink VRF & Automation. This project enables users to participate in a transparent and trustless raffle system where winners are selected using verifiable on-chain randomness.

---

# Project Overview

This project demonstrates a fully automated decentralized raffle system running on Ethereum-compatible blockchains.

Users can enter the raffle by paying a fixed entrance fee. After a predefined time interval, Chainlink Automation automatically triggers the winner selection process.

The randomness is generated using Chainlink VRF (Verifiable Random Function), ensuring that the winner selection process is fair, tamper-proof, and decentralized.

---

# How the Raffle Works

1. Users enter the raffle by sending ETH.
2. The contract stores all participant addresses.
3. After the configured interval passes:
   - Chainlink Automation calls `performUpkeep()`
   - The contract requests randomness from Chainlink VRF
4. Chainlink VRF returns a verifiable random number.
5. A random winner is selected.
6. The winner receives the entire raffle balance.
7. The raffle resets automatically for the next round.

---

# Key Features

- Fully decentralized raffle system
- Automated winner selection
- Provably fair randomness using Chainlink VRF
- Automated execution using Chainlink Automation
- Built with Foundry for fast testing and deployment
- Unit testing and local mock testing included
- Gas-efficient Solidity smart contracts
- Secure and transparent lottery mechanism

---

# Tech Stack

- Solidity
- Foundry
- Chainlink VRF v2.5
- Chainlink Automation
- OpenZeppelin Contracts
- Forge Testing Framework

---

# Project Structure

```bash
src/        # Smart contracts
script/     # Deployment and interaction scripts
test/       # Unit tests
lib/        # Dependencies
broadcast/  # Deployment transaction data

---

Author

GitHub: https://github.com/Koushikrawal22

Built as part of a deep dive into Solidity smart contract development, testing, and decentralized application architecture. 