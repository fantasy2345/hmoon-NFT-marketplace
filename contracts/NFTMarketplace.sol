// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Sale.sol";

/**
 * @title NFTMarketplace
 * @dev anyone can bid token and only TokenOwner can sell their token
 */
contract NFTMarketplace is Ownable, Sale {

    using Address for address;

    /// @notice Information about the sender that placed a bid on an NFT marketplace
    struct marketInfo {
        address bidder;
        uint256 bidAmount;
        uint256 bidTime;
    }

    /// @notice max bidders stack count
    uint256 public maxBidStackCount = 3;

    /// @notice basePrice informaation of tokenId
    mapping( uint256 => uint256 ) private basePrice;

    /// @notice token Status of tokenId(1: sold)
    mapping( uint256 => uint256 ) private _tokenStatus;

    /// @notice ERC721 Token ID -> bidder info (if a bid has been received)
    mapping( uint256 => marketInfo[] ) private bids;


    modifier onlyRNG() {
        require(
            msg.sender == address(RNG),
            "NFTMarketplace: Caller is not the RandomNumberGenerator"
        );
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId ) {
        require( msg.sender == ownerOf(_tokenId), "only token owner can sell token");
        _;
    }

    /**
     * @notice Sale Constructor
     * @param _hmoon hmoon Interface
     * @param name NFT name
     * @param symbol NFT symbol
     * @param startPresaleDate first presale starting time
     * @param firstduration first presale duration
     * @param secondPresaleDate second presale starting time
     * @param secondDuration second presale duration
     * @param startPublicsaleDate public sale starting time
     * @param _RNG random number generator interface
     */
    constructor(IERC20 _hmoon, string memory name, string memory symbol,uint256 startPresaleDate, uint256 firstduration, uint256 secondPresaleDate, 
                uint256 secondDuration, uint256 startPublicsaleDate, IRandomNumberGenerator _RNG) 
                Sale(_hmoon, name,symbol, startPresaleDate, firstduration, secondPresaleDate, secondDuration, startPublicsaleDate, _RNG)  {
                        
    }

  
    /**
     * @notice get tokenId based random number
     * @param _random random number from chain link
    */
    function getRealNumber( uint256 _random) internal returns(uint256) {
        uint256 totalCount = getTotalCount();
        uint256 usedCount = getUsedCount();

        uint256 randomNum = _random % ( totalCount - usedCount);
        uint256 itemIdx = 0;
        uint256 i = 0;
        for( i = 0; i < totalCount ; i++ ) {
            if( _tokenStatus[i] == 0 ) itemIdx++;
            if( itemIdx == randomNum ) break;
        }
        require( i < totalCount, "cannot buy item");
        _tokenStatus[i] = 1;
        increaseUsedCount();
        return itemIdx;
    }

    /**
     * @notice get hash number based random number
     * @param _random random number from chain link
    */
    function getHashNumber( uint256 _random ) internal view returns(uint256) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _random)));
    }

    /**
     * @notice sale NFT function
     * @dev Only Random number generator contract can call this function
     * @param _requestId requestID from chain link to get the random number
     * @param _randomness random number from chain link
    */
    function sale(bytes32 _requestId, uint256 _randomness) external onlyRNG {
        SaleInfo storage saleInfo = requestToSale[_requestId];
        uint256 itemIdx = getRealNumber(_randomness);
        super.safeTransferFrom( address(this), saleInfo.buyer, itemIdx );
        for( uint i = 0; i < saleInfo.chestType; i++ ) {
            itemIdx = getRealNumber( getHashNumber(_randomness) );
            super.safeTransferFrom( address(this), saleInfo.buyer, itemIdx );
        }
        emit SaleFinished( saleInfo.buyer, saleInfo.chestType);
    }

    /**
     * @notice Places a new bid.
     * @param _tokenId Token ID of the token being auctioned
     * @param _betPrice bid price of token
    */
    function bid( uint256 _tokenId, uint256 _betPrice ) external {
        require( ownerOf(_tokenId) != address(0), "not minted yet");
        uint256 tokenBasePrice = basePrice[_tokenId];
        require( _betPrice >= tokenBasePrice, "you should bet more than base price");
        uint256 value = _betPrice;
        require( hmoon.balanceOf(msg.sender) >= value, "you have not enoguh hmoon");
        marketInfo[] storage bidList = bids[_tokenId];
        uint256 betCount = bidList.length;
        uint256 i = 0;
        for( i = 0; i < betCount; i++ ) {
            require( msg.sender != bidList[i].bidder, "already bet");
        }
        marketInfo memory newBid;

        newBid.bidder = msg.sender;
        newBid.bidAmount = _betPrice;
        newBid.bidTime = block.timestamp;

        bidList.push(newBid);

    }

    /**
     * @notice Given a sender who is in the bid list of auction, allows them to withdraw their bid
     * @dev Only callable by the existing bidder
     * @param _tokenId Token ID of the token being auctioned
    */
    function withdrawBid( uint256 _tokenId) external {
        require( ownerOf(_tokenId) != address(0), "not minted yet");
        marketInfo[] storage bidList = bids[_tokenId];
        require( bidList.length > 0, "There is no bid");
        uint256 betCount = bidList.length;
        uint256 i = 0;
        for( i = 0;i < betCount; i++ ) {
            if( bidList[i].bidder == msg.sender ) {
                break;
            }
        }
        require( i < betCount, "Caller is not the bidder");
        //with draw money
        require( bidList[i].bidder != address(0),"bidder cannot be zero address");
        
        for (uint256  j= i; j < bidList.length - 1; j++) {
            bidList[j] = bidList[j + 1];
        }

        bidList.pop();
    }

    /**
     * @notice sell token
     * @param _tokenId Token ID of the token being auctioned
     * @param position seller index of bid list
    */
    function sell( uint256 _tokenId, uint256 position ) external onlyTokenOwner(_tokenId) {
        require( ownerOf(_tokenId) != address(0), "not minted yet");
        marketInfo[] storage bidList = bids[_tokenId];
        require( bidList.length > 0, "There is not bid");
        require( position <= bidList.length, "unknown bet" );
        
        //check hmoon and transfer it to my wallet
        _safeTransfer(msg.sender, bidList[position].bidder, _tokenId, "");

        //clear auction list
        delete bids[_tokenId];
    }

    /**
     * @notice Method for getting all info about the bids
     * @param _tokenId Token ID of the token being auctioned
     */
    function getBidList(uint256 _tokenId) external view returns (marketInfo[] memory) {
        return bids[_tokenId];
    }

}