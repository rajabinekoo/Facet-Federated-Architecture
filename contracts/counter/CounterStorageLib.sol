// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

library CounterStorageLib {
    bytes32 constant COUNTER_POSITION =
        keccak256("federal.architecture.counter.storage");

    struct CounterStorage {
        uint256 count;
    }

    function counterStorageLayout()
        internal
        pure
        returns (CounterStorage storage ds)
    {
        bytes32 position = COUNTER_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
