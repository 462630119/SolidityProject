// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// upgrade contract
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


contract NFTAuction is Initializable, UUPSUpgradeable {
    // 初始化函数，替代构造函数
    function initialize() public initializer {
        admin = msg.sender;
    }

    // Auction contract code goes here
    struct Auction {
        address seller;
        uint256 duration;
        uint256 startTime;
        uint256 startPrice;
        bool ended;
        address highestBidder;
        uint256 highestBid;

        // NFT 合约地址
        address nftAddress;
        // NFT 代币ID
        uint256 tokenId;
        // 参与竞价的资产类型
        // 0: ETH
        // 1: ERC20
        address tokenAddress;
    }

    // 状态变量
    mapping(uint256 => Auction) public auctions;
    uint256 public nextAuctionId;
    address public admin;
    uint256 public platformFee; // 平台手续费，单位为百分比（例如：2 表示 2%）
    // constructor () {
    //     admin = msg.sender;
    // }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    AggregatorV3Interface internal priceFeed;
    function setPriceETHFeed(address _priceFeed) public onlyAdmin {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }
    // function getLatestPrice() public returns (int256) {
    //     (
    //         uint80 roundID,
    //         int256 price,
    //         uint startedAt,
    //         uint timeStamp,
    //         uint80 answeredInRound
    //     ) = priceFeed.latestRoundData();
        
    //     return price;
    // }

    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return answer;
    }

    
    // 创建拍卖
    function createAuction(uint256 _duration, uint256 _startPrice, address _nftAddress, uint256 _tokenId) public onlyAdmin {
        require(_duration > 1000 * 60, "Duration must be greater than 1 minute");
        require(_startPrice > 0, "Start price must be greater than 0");

        // 转移 NFT 到合约地址
        IERC721(_nftAddress).approve(address(this), _tokenId);
        IERC721(_nftAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            duration: block.timestamp + _duration,
            startTime: block.timestamp,
            startPrice: _startPrice,
            ended: false,
            highestBidder: address(0),
            highestBid: 0,
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            tokenAddress: address(0)
        });

        nextAuctionId++;
    }

    // 买家参与拍卖
    function placeBid(uint256 _auctionId, uint256 _amount, address tokenAddress) external payable {
        // ETH/USD 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // USDC/USD 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E

        Auction storage auction = auctions[_auctionId];
        // 拍卖结束flag && 拍卖时间未到
        require(!auction.ended && auction.startTime + auction.duration > block.timestamp, "Auction has ended");
        require(msg.value > auction.highestBid && msg.value >= auction.startPrice, "Bid must be higher than current highest bid");

        // Refund the previous highest bidder
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
    }

    // 结束拍卖
    function endAuction(uint256 _auctionId) external {
        Auction storage auction = auctions[_auctionId];
        require(!auction.ended, "Auction already ended");
        require(block.timestamp >= auction.startTime + auction.duration, "Auction duration not yet passed");
        // auction.ended = true;

        // Transfer the NFT to the highest bidder
        if (auction.highestBidder != address(0)) {
            IERC721(auction.nftAddress).safeTransferFrom(address(this), auction.highestBidder, auction.tokenId);
        } else {
            // If there were no bids, return the NFT to the seller
            IERC721(auction.nftAddress).safeTransferFrom(address(this), auction.seller, auction.tokenId);
        }
        // 转移剩余资金到卖家
        payable(address(this)).transfer(address(this).balance);
        auction.ended = true;
    
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {
        require(msg.sender == admin, "Only admin can upgrade the contract");
    }

}