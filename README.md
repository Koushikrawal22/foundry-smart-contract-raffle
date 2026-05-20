foundry-smart-contract-raffle

A decentralized lottery/raffle smart contract built using Solidity, Foundry, and Chainlink VRF & Automation. The project enables users to participate in a transparent and trustless raffle system where winners are selected using verifiable on-chain randomness.

Project Overview:

This project demonstrates a fully automated decentralized raffle system running on Ethereum-compatible blockchains.

Users can enter the raffle by paying a fixed entrance fee. After a predefined time interval, Chainlink Automation checks whether the raffle conditions are satisfied and automatically triggers the winner selection process.

The randomness is generated using Chainlink VRF (Verifiable Random Function), ensuring that the winner selection is provably fair, tamper-proof, and decentralized.

How the Raffle Works:
Users enter the raffle by sending ETH.
The contract stores all participant addresses.
After the configured time interval passes:
Chainlink Automation calls performUpkeep()
The contract requests a random number from Chainlink VRF.
Chainlink VRF returns a verifiable random number.
The contract selects a random winner.
The winner receives the entire raffle balance.
The raffle resets automatically for the next round.

Key Features:
Fully decentralized raffle system
Automated winner selection
Provably random winner generation using Chainlink VRF
Automated execution using Chainlink Automation
Built with Foundry for fast testing and deployment
Unit testing and local mock testing included
Gas-efficient Solidity smart contracts
Secure and transparent lottery mechanism

Tech Stack:
Solidity
Foundry
Chainlink VRF v2.5
Chainlink Automation
OpenZeppelin Contracts
Forge Testing Framework

Project Structure:
src/        → Smart contracts
script/     → Deployment and interaction scripts
test/       → Unit tests
lib/        → Dependencies
broadcast/  → Deployment transaction data

Benefits of the Project:
Eliminates centralized control in lottery systems
Ensures transparent and fair winner selection
Demonstrates real-world Web3 automation workflows
Showcases advanced Solidity development concepts


The project leverages Chainlink VRF to guarantee:
Unpredictable randomness
Verifiable winner selection
Protection against manipulation
All raffle operations are recorded on-chain, making the system fully transparent.

Future Improvements:
Frontend integration with React/Next.js
Multiple simultaneous raffles
NFT-based raffle tickets
Admin dashboard
Multi-chain deployment
Advanced analytics and events tracking

Author
GitHub: https://github.com/Koushikrawal22

Built as part of a deep dive into Solidity smart contract development, testing, and decentralized application architecture.