const {ethers, deployments } = require("hardhat");
const { expect } = require("chai");
const {fs} = require("fs");
const path = require("path");

describe("Test Update", function () {
    it("should deploy, upgrade, and test the NFTAuction contract", async function () {
        // 1. 部署初始版本的合约
        await deployments.fixture(["deployNFTAuction"]);
        const nftAuctionProxy = await deployments.get("NFTAuctionProxyV2");
        const nftAuctionContract = await ethers.getContractAt("NFTAuction", nftAuctionProxy.address);

        // 2. 调用 createAuction 方法创建一个拍卖
        await nftAuctionContract.createAuction(
            100*1000, 
            ethers.parseEther("0.01"),
            ethers.constants.AddressZero,
            1,
        );
        const auction = await nftAuctionContract.auctions(0);
        console.log("Auction created successfully", auction);

        // 3. 升级合约到新版本
        await deployments.fixture(["upgradeNFTAuction"]);

        // 4. 调用新版本的 testHello 方法，验证升级成功
        const auction2 = await nftAuctionContract.auctions(0);
        expect(auction2.startTime).to.equal(auction.startTime);
    });
});