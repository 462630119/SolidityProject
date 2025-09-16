// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// upgrade contract
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NFTAuction is Initializable {
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
    // 创建拍卖
    function createAuction(uint256 _duration, uint256 _startPrice, address _nftAddress, uint256 _tokenId) public onlyAdmin {
        require(_duration > 1000 * 60, "Duration must be greater than 1 minute");
        require(_startPrice > 0, "Start price must be greater than 0");

        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            duration: block.timestamp + _duration,
            startTime: block.timestamp,
            startPrice: _startPrice,
            ended: false,
            highestBidder: address(0),
            highestBid: 0,
            nftAddress: _nftAddress,
            tokenId: _tokenId
        });

        nextAuctionId++;
    }

    // 买家参与拍卖
    function placeBid(uint256 _auctionId) external payable {
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

}