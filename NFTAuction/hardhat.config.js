require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("hardhat-deploy");

const { deploy } = require("@openzeppelin/hardhat-upgrades/dist/utils");


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  namedAccounts :{
    deployer: 0,
    user1: 1,
    user2: 2
  },
  // networks: {
  //   sepolia: {
  //     url: "https://sepolia.infura.io/v3/" + process.env.INFURA_API_KEY,
  //     accounts: [process.env.PRIVATE_KEY],
  //   },
  // },
};