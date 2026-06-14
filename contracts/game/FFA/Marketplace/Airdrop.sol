// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IAirdrop} from "./interfaces/IAirdrop.sol";
import {IAirdropStore} from "./interfaces/IAirdropStore.sol";
import {MarketplaceStorageLib} from "./MarketplaceStorageLib.sol";
import {FederalStorageLib} from "../../../core/FederalStorageLib.sol";
import {IAssetCollection} from "../AssetWizard/interfaces/IAssetCollection.sol";
import {
    IFederalReceiptsLink
} from "../../../core/interfaces/IFederalReceiptsLink.sol";

contract Airdrop is IAirdrop {
    bytes32 private constant DOMAIN_ID = keccak256("ffa.domain.Marketplace");
    bytes32 private constant AIRDROP_CREATED = keccak256("AirdropCreated");
    bytes32 private constant AIRDROP_CLAIMED = keccak256("AirdropClaimed");
    bytes32 private constant AIRDROP_REMOVED = keccak256("AirdropRemoved");

    modifier onlyManager() {
        require(
            FederalStorageLib.isManager(msg.sender),
            "Caller is not a manager"
        );
        _;
    }

    function initAirdrop(address store_) external onlyManager {
        MarketplaceStorageLib.marketplaceStorageLayout().airdropStore = store_;
    }

    function newAirdrop(
        address collection,
        uint256 tokenId,
        uint256 quantity,
        uint256 count,
        uint256 duration,
        uint256 startTime
    ) external onlyManager {
        IAirdropStore store = IAirdropStore(
            MarketplaceStorageLib.marketplaceStorageLayout().airdropStore
        );
        Airdrop memory airdrop = Airdrop({
            collection: collection,
            tokenId: tokenId,
            quantity: quantity,
            count: count,
            duration: duration,
            startTime: startTime
        });
        store.create(airdrop);

        address receiptsAddress = FederalStorageLib
            .federalCoreStorageLayout()
            .receiptsAddress;
        IFederalReceiptsLink(receiptsAddress).emitReceipt(
            DOMAIN_ID,
            AIRDROP_CREATED,
            abi.encode(
                collection,
                tokenId,
                quantity,
                count,
                duration,
                startTime
            )
        );
    }

    function claim(uint256 index) external {
        IAirdropStore store = IAirdropStore(
            MarketplaceStorageLib.marketplaceStorageLayout().airdropStore
        );
        Airdrop memory airdrop = store.getOne(index);

        require(airdrop.collection != address(0), "Airdrop not found");
        require(airdrop.count > 0, "Airdrop is fully claimed");
        require(
            block.timestamp >= airdrop.startTime,
            "Airdrop has not started yet"
        );
        require(
            block.timestamp <= airdrop.startTime + airdrop.duration,
            "Airdrop has expired"
        );

        store.updateCount(index, airdrop.count - 1);

        IAssetCollection(airdrop.collection).mint(
            msg.sender,
            airdrop.tokenId,
            airdrop.quantity,
            ""
        );

        address receiptsAddress = FederalStorageLib
            .federalCoreStorageLayout()
            .receiptsAddress;
        IFederalReceiptsLink(receiptsAddress).emitReceipt(
            DOMAIN_ID,
            AIRDROP_CLAIMED,
            abi.encode(
                airdrop.collection,
                airdrop.tokenId,
                airdrop.quantity,
                msg.sender
            )
        );
    }

    function remove(uint256 index) external onlyManager {
        IAirdropStore store = IAirdropStore(
            MarketplaceStorageLib.marketplaceStorageLayout().airdropStore
        );
        Airdrop memory airdrop = store.getOne(index);

        require(airdrop.collection != address(0), "Airdrop not found");

        store.remove(index);
    }
}
