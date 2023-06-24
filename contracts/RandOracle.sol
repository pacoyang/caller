// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ICaller.sol";

// AccessControl: role-based access control
contract RandOracle is AccessControl {
    bytes32 public constant PROVIDER_ROLE = keccak256("PROVIDER_ROLE");
    // total count of data providers
    uint private numProviders = 0;
    // minimum number of provider responses we need to consider a request fulfilled
    uint private providersThreshold = 1;

    uint private randNonce = 0;
    mapping(uint256 => bool) private pendingRequests;

    struct Response {
        address providerAddress;
        address callerAddress;
        uint256 randomNumber;
    }

    mapping(uint256 => Response[]) private idToResponses;

    // Events
    event RandomNumberRequested(address callerAddress, uint id);
    event RandomNumberReturned(
        uint256 randomNumber,
        address callerAddress,
        uint id
    );
    event ProviderAdded(address providerAddress);
    event ProviderRemoved(address providerAddress);
    event ProvidersThresholdChanged(uint threshold);

    constructor() {
        // assigns DEFAULT_ADMIN_ROLE to the contract's address
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function requestRandomNumber() external returns (uint256) {
        require(numProviders > 0, "No data providers not yet added.");
        randNonce++;
        uint id = uint(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))
        ) % 1000;
        pendingRequests[id] = true;

        emit RandomNumberRequested(msg.sender, id);
        return id;
    }

    // return number by provider
    function returnRandomNumber(
        uint256 randomNumber,
        address callerAddress,
        uint id
    ) external onlyRole(PROVIDER_ROLE) {
        require(pendingRequests[id], "Request not found.");
        Response memory res = Response(msg.sender, callerAddress, randomNumber);
        idToResponses[id].push(res);
        uint numResponses = idToResponses[id].length;

        // check if we've received enough response
        if (numResponses == providersThreshold) {
            uint compositeRandomNumber = 0;

            // Loop through the array and combine responses
            for (uint i = 0; i < idToResponses[id].length; i++) {
                compositeRandomNumber =
                    compositeRandomNumber ^
                    idToResponses[id][i].randomNumber; // bitwise XOR
            }

            // Clean up
            delete pendingRequests[id];
            delete idToResponses[id];

            ICaller(callerAddress).fulfillRandomNumberRequest(
                compositeRandomNumber,
                id
            );
            emit RandomNumberReturned(compositeRandomNumber, callerAddress, id);
        }
    }

    // Admin functions
    function addProvider(
        address provider
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!hasRole(PROVIDER_ROLE, provider), "Provider already added.");

        _grantRole(PROVIDER_ROLE, provider);
        numProviders++;

        emit ProviderAdded(provider);
    }

    function removeProvider(
        address provider
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            !hasRole(PROVIDER_ROLE, provider),
            "Address is not a recognized provider."
        );
        require(numProviders > 1, "Cannot remove the only provider.");

        _revokeRole(PROVIDER_ROLE, provider);
        numProviders--;

        emit ProviderRemoved(provider);
    }
}
