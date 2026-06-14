// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

library FederalStorageLib {
    bytes32 constant FEDERAL_CORE_POSITION =
        keccak256("federal.architecture.core.storage");

    struct FederalCoreStorage {
        address core;
        address owner;
        address receiptsAddress;
        mapping(address => bool) managers;
        mapping(bytes32 => address) federalRegistries;
    }

    function federalCoreStorageLayout()
        internal
        pure
        returns (FederalCoreStorage storage ds)
    {
        bytes32 position = FEDERAL_CORE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function isManager(address account) internal view returns (bool) {
        return
            federalCoreStorageLayout().managers[account] ||
            account == federalCoreStorageLayout().owner;
    }
}
