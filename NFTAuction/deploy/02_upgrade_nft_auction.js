const {ethers, upgrades} = require("hardhat");

module.exports = async ({getNamedAccounts, deployments}) => {
  const {save} = deployments;
  const {deployer} = await getNamedAccounts();
  console.log("部署用户地址:", deployer);

  const NFTAuctionV2 = await ethers.getContractFactory("NFTAuctionV2");
  const storePath = path.resolve(__dirname, "../deployments/localhost/NFTAuctionProxy.json");
  const {proxyAddress, implAddress, abi} = JSON.parse(fs.readFileSync(storePath, "utf-8"));

  const nftAuctionProxyV2 = await upgrades.upgradeProxy(proxyAddress, NFTAuctionV2);
  await nftAuctionProxyV2.waitForDeployment();
  console.log("NFTAuction upgraded at:", nftAuctionProxyV2.getAddress());
  const proxyAddressV2 = await nftAuctionProxyV2.getAddress();

    await save("NFTAuctionProxyV2", {
        abi,
        address: nftAuctionProxyV2,
    });

}
module.exports.tags = ["upgradeNFTAuction"];