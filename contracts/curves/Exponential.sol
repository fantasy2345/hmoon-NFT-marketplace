// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Exponential is Ownable {
    uint256 constant public decimals = 10**18;

    AggregatorV3Interface  internal HMOONUSDAggregator;

    function calculatePrice(
    )   public
        view
        returns (uint256)
    {
        (,int256 resSTMX,,,) = HMOONUSDAggregator.latestRoundData();

        return uint256(resSTMX);
    }

    /**
     * @dev Owner can set HMOON / USD Aggregator contract
     * @param _addr Address of aggregator contract
     */
    function setHMOONUSDAggregatorContract(address _addr) public onlyOwner {
        HMOONUSDAggregator = AggregatorV3Interface(address(_addr));
    }
}