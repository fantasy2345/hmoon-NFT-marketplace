/**
 * @title RandomNumberGenerator interface
 */
 interface IRandomNumberGenerator {
    /**
     * @dev External function for playing. This function can be called by only RandomNumberGenerator.
     */
    function requestRandomNumber() external returns (bytes32);
}