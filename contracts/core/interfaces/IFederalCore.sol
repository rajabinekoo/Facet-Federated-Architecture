// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

interface IFederalCore {
    event RegistryAdded(
        bytes32 indexed domainId,
        address indexed registryAddress
    );
    event RegistryRemoved(bytes32 indexed domainId);
}
