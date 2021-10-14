// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/**
 * @title Game interface
 */
interface INFTMarketplace {
    /**
     * @dev External function for playing. This function can be called by only RandomNumberGenerator.
     * @param _requestId Request Id
     * @param _randomness Random Number
     */
    function sale(bytes32 _requestId, uint256 _randomness) external;
}
