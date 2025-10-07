// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// upgrade contract
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

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

    mapping(address => AggregatorV3Interface) public priceFeed;
    function setPriceFeed(address token, address _priceFeed) public {
        priceFeed[token] = AggregatorV3Interface(_priceFeed);
    }

    function getChainlinkDataFeedLatestAnswer(address token) public view returns (int) {
        AggregatorV3Interface priceFeedItem = priceFeed[token];
        // prettier-ignore
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = priceFeedItem.latestRoundData();
        return answer;
    }

    
    // 创建拍卖
    function createAuction(uint256 _duration, uint256 _startPrice, address _nftAddress, uint256 _tokenId) public {
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

        if (tokenAddress != address(0)) {
            uint ERC20Value = _amount * uint(getChainlinkDataFeedLatestAnswer(auction.tokenAddress));
            uint startPriceValue = auction.startPrice * uint(getChainlinkDataFeedLatestAnswer(auction.tokenAddress));
            uint highestBidValue = auction.highestBid * uint(getChainlinkDataFeedLatestAnswer(auction.tokenAddress));

            require(ERC20Value > highestBidValue && ERC20Value >= startPriceValue, "Bid must be higher than current highest bid");
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), ERC20Value);
            if (auction.highestBidder != address(0)) {
                IERC20(tokenAddress).transfer(auction.highestBidder, highestBidValue);
            } else {
                // 退回 ERC20 代币
                IERC20(auction.tokenAddress).transfer(auction.highestBidder, auction.highestBid);
            }
            auction.highestBidder = msg.sender;
            auction.highestBid = ERC20Value;
        }


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

    function _authorizeUpgrade(address newImplementation) internal override view{
        require(msg.sender == admin, "only admin can upgrade");
    }

}