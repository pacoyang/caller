// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRandOracle.sol";

// Uncomment this line to use console.log
import "hardhat/console.sol";

contract Caller is Ownable {
    IRandOracle private randOracle;

    // keep track of active request IDs
    mapping(uint256 => bool) requests;
    // which store the random numbers received for each request ID
    mapping(uint256 => uint256) results;

    event OracleAddressChanged(address oracleAddress);
    event RandomNumberRequested(uint256 id);
    event RandomNumberReceived(uint256 number, uint256 id);

    modifier onlyRandOracle() {
        require(msg.sender == address(randOracle), "Unauthorized.");
        _;
    }

    function setRandOracleAddress(address newAddress) external onlyOwner {
        randOracle = IRandOracle(newAddress);
        console.log("setRandOracleAddress", newAddress);
        emit OracleAddressChanged(newAddress);
    }

    function getRandomNumber() external {
        require(
            randOracle != IRandOracle(address(0)),
            "Oracle not initialized."
        );
        uint256 id = randOracle.requestRandomNumber();
        requests[id] = true;
        emit RandomNumberRequested(id);
    }

    function fulfillRandomNumberRequest(
        uint256 randomNumber,
        uint256 id
    ) external onlyRandOracle {
        require(requests[id], "Request is invalid or already fulfilled.");
        results[id] = randomNumber;
        delete requests[id];
        emit RandomNumberReceived(randomNumber, id);
    }
}
