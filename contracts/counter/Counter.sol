// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CounterStorageLib} from "./CounterStorageLib.sol";
import {FederalStorageLib} from "../core/FederalStorageLib.sol";
import {
    IFederalReceiptsLink
} from "../core/interfaces/IFederalReceiptsLink.sol";

contract Counter {
    bytes32 private constant DOMAIN_ID = keccak256("ffa.domain.counter");
    bytes32 private constant COUNTER_INCREMENTED_EVENT =
        keccak256("CounterIncremented");

    event CounterIncremented(uint256 newValue);

    function increment() public {
        CounterStorageLib.CounterStorage storage ds = CounterStorageLib
            .counterStorageLayout();
        ds.count++;

        address receiptsAddress = FederalStorageLib
            .federalCoreStorageLayout()
            .receiptsAddress;

        IFederalReceiptsLink(receiptsAddress).emitReceipt(
            DOMAIN_ID,
            COUNTER_INCREMENTED_EVENT,
            abi.encode(ds.count)
        );
    }

    function get() public view returns (uint256) {
        CounterStorageLib.CounterStorage storage ds = CounterStorageLib
            .counterStorageLayout();
        return ds.count;
    }
}
