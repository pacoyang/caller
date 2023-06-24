// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ICaller {
    function fulfillRandomNumberRequest(
        uint256 randomNumber,
        uint256 id
    ) external;
}
