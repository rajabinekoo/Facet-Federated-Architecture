// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {AssetCollection} from "./AssetCollection.sol";
import {FederalStorageLib} from "../../../core/FederalStorageLib.sol";
import {
    IFederalReceiptsLink
} from "../../../core/interfaces/IFederalReceiptsLink.sol";

contract AssetFactory {
    bytes32 private constant DOMAIN_ID = keccak256("ffa.domain.AssetWizard");
    bytes32 private constant COLLECTION_CREATED =
        keccak256("CollectionCreated");

    modifier onlyManager() {
        require(
            FederalStorageLib.isManager(msg.sender),
            "Caller is not a manager"
        );
        _;
    }

    function createCollection(
        string calldata name,
        string calldata symbol,
        string calldata baseURI
    ) external onlyManager returns (address collection) {
        AssetCollection assetCollection = new AssetCollection(
            name,
            symbol,
            baseURI
        );

        collection = address(assetCollection);

        address receiptsAddress = FederalStorageLib
            .federalCoreStorageLayout()
            .receiptsAddress;

        IFederalReceiptsLink(receiptsAddress).emitReceipt(
            DOMAIN_ID,
            COLLECTION_CREATED,
            abi.encode(collection, name, symbol, baseURI)
        );
    }
}
