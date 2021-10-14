// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRandomNumberGenerator.sol";

/**
 * @title Full ERC721 Token with support for baseURI
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
  contract Sale is ERC721 {

    /// @notice Event emitted only on construction. To be used by indexers
    event SaleFinished( address buyer, uint256 chestType);
    event FirstPresaleStarted( address buyer, uint256 chestType, uint256 value, bytes32 requestId );
    event SecondPresaleStarted( address buyer, uint256 chestType, uint256 value, bytes32 requestId );
    event PublicsaleStarted( address buyer, uint256 chestType, uint256 value, bytes32 requestId );

    /// @notice Information about the buyer and random number that buy a chest.
    struct SaleInfo {
        address buyer;
        uint256 chestType;
        bytes32 requestId;
    }

    /// @notice buyer information based random number request
    mapping(bytes32 => SaleInfo) public requestToSale;

    // @notice ERC20 hmoon token
    IERC20 public hmoon;

    /// @notice first presale starting time
    uint256 private _firstPresale;

    /// @notice first presale duration
    uint256 private _firstduration;

    /// @notice second presale starting time
    uint256 private _secondPresale;

    /// @notice second presale duration
    uint256 private _secondduration;

    /// @notice public sale starting time
    uint256 private _startPublicsale;

    /// @notice total NFT count
    uint256 private _totalCount;

    /// @notice NFT minted count
    uint256 private _usedCount;

    /// @notice interface for random number generator
    IRandomNumberGenerator public RNG;

    

    modifier duringFirstPresale() {
        require( block.timestamp >= _firstPresale && block.timestamp <= _firstPresale + _firstduration, "not first presale");
        _;
    }

    modifier duringSecondPresale() {
        require( block.timestamp >= _secondPresale && block.timestamp <= _secondPresale + _secondduration, "not second presale");
        _;
    }

    modifier duringPublicsale() {
        require( block.timestamp >= _startPublicsale, "public sale does not start");
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
    constructor(IERC20 _hmoon, string memory name, string memory symbol, uint256 startPresaleDate, uint256 firstduration, uint256 secondPresaleDate, 
        uint256 secondDuration, uint256 startPublicsaleDate, IRandomNumberGenerator _RNG) ERC721(name,symbol) {
        hmoon = _hmoon;
        RNG = _RNG;

        _firstPresale = startPresaleDate;
        _firstduration = firstduration;

        _secondPresale = secondPresaleDate;
        _secondduration = secondDuration;

        _startPublicsale = startPublicsaleDate;

        //set Total Count here

    }

    /**
     * @notice First Presale function
     * @dev Only during first presale
     * @param _chestType type of chest(0: gold 100$, 1: platinum 150$, 2: diamond 200$ )
    */
    function firstPresale( uint256 _chestType ) external duringFirstPresale{
        require( _chestType >= 0 && _chestType <= 2, "type has to be 0 to 2 value");
        uint256 value = 100 + _chestType * 50;
        require( hmoon.balanceOf(msg.sender) >= value, "not enough hmoon token");
        require( _usedCount + _chestType + 1 <= _totalCount,"All nfts are sold");
        
        bytes32 requestId = RNG.requestRandomNumber();
        requestToSale[requestId] = SaleInfo(
            msg.sender,
            _chestType,
            requestId
        );
        emit FirstPresaleStarted( msg.sender, _chestType, value, requestId );
    }

    /**
     * @notice Second Presale function
     * @dev Only during second presale
     * @param _chestType type of chest(0: gold 150$, 1: platinum 200$, 2: diamond 250$ )
    */
    function secondPresale( uint256 _chestType ) external duringSecondPresale {
        require( _chestType >= 0 && _chestType <= 2, "type has to be 0 to 2 value");
        uint256 value = 150 + _chestType * 50;
        require( hmoon.balanceOf(msg.sender) >= value, "not enough hmoon token");
        require( _usedCount + _chestType + 1 <= _totalCount,"All nfts are sold");

        bytes32 requestId = RNG.requestRandomNumber();
        requestToSale[requestId] = SaleInfo(
            msg.sender,
            _chestType,
            requestId
        );
        emit SecondPresaleStarted( msg.sender, _chestType, value, requestId );
    }

    /**
     * @notice Public Presale function
     * @dev Only during public presale
     * @param _chestType type of chest(0: gold 200$, 1: platinum 250$, 2: diamond 300$ )
    */
    function publicSale( uint256 _chestType ) external duringPublicsale {
        require( _chestType >= 0 && _chestType <= 2, "type has to be 0 to 2 value");
        uint256 value = 200 + _chestType * 50;
        require( hmoon.balanceOf(msg.sender) >= value, "not enough hmoon token");
        require( _usedCount + _chestType + 1 <= _totalCount,"All nfts are sold");

        bytes32 requestId = RNG.requestRandomNumber();
        requestToSale[requestId] = SaleInfo(
            msg.sender,
            _chestType,
            requestId
        );
        emit PublicsaleStarted( msg.sender, _chestType, value, requestId );
    }

    /**
     * @notice get total NFT count
    */
    function getTotalCount() public view returns(uint256) {
        return _totalCount;
    }

    /**
     * @notice get minted NFT count
    */
    function getUsedCount() public view returns(uint256) {
        return _usedCount;
    }

    /**
     * @notice increase minted NFT
    */
    function increaseUsedCount() public {
        _usedCount++;
    }
    }