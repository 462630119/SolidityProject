const fs = require("fs");
const path = require("path");

const {deployments, upgrades} = require("hardhat");

module.exports = async ({getNamedAccounts, deployments}) => {
  const {save} = deployments;
  const {deployer} = await getNamedAccounts();

  console.log("Deployer address:", deployer);
  const NFTAuction = await ethers.getContractFactory("NFTAuction");
  
  // Upgradeable proxy deployment
  const nftAuctionProxy = await upgrades.deployProxy(NFTAuction, [], {initializer: "initialize"});

  await nftAuctionProxy.waitForDeployment();
  const proxyAddress = await nftAuctionProxy.getAddress();
  console.log("NFTAuction deployed to:", proxyAddress);
  const implAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
  console.log("Implementation address:", implAddress);
  //console.log("Transaction hash:", await upgrades.erc1967.getImplementationAddress(proxyAddress));

  const storePath = path.resolve(__dirname, "../deployedAddresses.json");

  fs.writeFileSync(
    storePath,
    JSON.stringify({
      proxyAddress,
      implAddress,
      abi: NFTAuction.interface.format("json"),
    })
  );
  await save("NFTAuction", {
    abi: NFTAuction.interface.format("json"),
    address: proxyAddress,
    args: [],
    log: true,
  });

//   await deploy("NFTAuction", {
//     from: deployer,
//     args: [],
//     log: true,
//   });
};

module.exports.tags = ["deployNFTAuction"];