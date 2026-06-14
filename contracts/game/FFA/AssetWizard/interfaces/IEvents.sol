// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

interface IEvents {
    event CollectionCreated(
        address collection,
        string name,
        string symbol,
        string baseURI
    );
}
