# Copilot Instructions for NFTAuction Solidity Project

## Project Overview
- This is a Hardhat-based Solidity project for NFT auctions.
- Key directories:
  - `contracts/`: Contains Solidity smart contracts (main: `NFTAuction.sol`).
  - `test/`: JavaScript tests for contracts (main: `Lock.js`).
  - `ignition/modules/`: Hardhat Ignition deployment modules (main: `Lock.js`).
  - `hardhat.config.js`: Hardhat configuration and plugin setup.

## Developer Workflows
- **Build/Test:**
  - Run all tests: `npx hardhat test`
  - Run with gas reporting: `REPORT_GAS=true npx hardhat test`
- **Deploy Contracts:**
  - Local node: `npx hardhat node`
  - Deploy with Ignition: `npx hardhat ignition deploy ./ignition/modules/Lock.js`
- **General Hardhat Tasks:**
  - List tasks: `npx hardhat help`

## Patterns & Conventions
- Contracts are written in Solidity and placed in `contracts/`.
- Tests use Hardhat and are written in JavaScript (see `test/Lock.js`).
- Deployment scripts use Hardhat Ignition modules (see `ignition/modules/Lock.js`).
- Use environment variables (e.g., `REPORT_GAS`) for optional features.
- Project structure follows Hardhat best practices.

## Integration Points
- Hardhat is the main build/test/deploy tool.
- No custom scripts or non-standard workflows detected; use Hardhat CLI for all major actions.
- External dependencies managed via `package.json`.

## Examples
- To test the main contract:
  ```shell
  npx hardhat test test/Lock.js
  ```
- To deploy using Ignition:
  ```shell
  npx hardhat ignition deploy ./ignition/modules/Lock.js
  ```

## Key Files
- `contracts/NFTAuction.sol`: Main contract implementation.
- `test/Lock.js`: Example test file.
- `ignition/modules/Lock.js`: Example deployment module.
- `hardhat.config.js`: Project configuration.

---
If any conventions or workflows are unclear or missing, please provide feedback to improve these instructions.
