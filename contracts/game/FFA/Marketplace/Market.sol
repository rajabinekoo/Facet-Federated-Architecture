// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IERC20} from "./interfaces/IERC20.sol";
import {IMarket} from "./interfaces/IMarket.sol";
import {IMarketStore} from "./interfaces/IMarketStore.sol";
import {MarketplaceStorageLib} from "./MarketplaceStorageLib.sol";
import {FederalStorageLib} from "../../../core/FederalStorageLib.sol";
import {IAssetCollection} from "../AssetWizard/interfaces/IAssetCollection.sol";
import {
    IFederalReceiptsLink
} from "../../../core/interfaces/IFederalReceiptsLink.sol";

contract Market is IMarket {
    bytes32 private constant DOMAIN_ID = keccak256("ffa.domain.Marketplace");
    bytes32 private constant BUYOUT = keccak256("Buyout");
    bytes32 private constant ADD_FIXED_PRICE = keccak256("AddListing");
    bytes32 private constant REMOVE_FIXED_PRICE = keccak256("RemoveListing");

    error NotValid();
    error NotFound();
    error PaymentFailed();

    modifier onlyOwner() {
        require(
            FederalStorageLib.federalCoreStorageLayout().owner == msg.sender,
            "Caller is not the owner"
        );
        _;
    }

    modifier onlyManager() {
        require(
            FederalStorageLib.isManager(msg.sender),
            "Caller is not a manager"
        );
        _;
    }

    function init(
        address treasury_,
        address store_,
        uint256 index_
    ) external onlyOwner {
        MarketplaceStorageLib.marketplaceStorageLayout().stores[
            index_
        ] = store_;
        MarketplaceStorageLib.marketplaceStorageLayout().storeIndex = index_;
        MarketplaceStorageLib.marketplaceStorageLayout().treasury = treasury_;
    }

    function addStore(address store_, uint256 index_) external onlyManager {
        MarketplaceStorageLib.marketplaceStorageLayout().stores[
            index_
        ] = store_;
        MarketplaceStorageLib.marketplaceStorageLayout().storeIndex = index_;
    }

    function changeTreasury(address newTreasury) external onlyOwner {
        MarketplaceStorageLib.marketplaceStorageLayout().treasury = newTreasury;
    }

    function create(
        address collection,
        address currency,
        uint256 tokenId,
        uint256 quantity,
        uint256 price,
        uint256 duration,
        uint256 startTime
    ) external onlyManager {
        IMarketStore(MarketplaceStorageLib.storeAddress()).create(
            collection,
            currency,
            tokenId,
            quantity,
            price,
            duration,
            startTime
        );
        address receiptsAddress = FederalStorageLib
            .federalCoreStorageLayout()
            .receiptsAddress;
        IFederalReceiptsLink(receiptsAddress).emitReceipt(
            DOMAIN_ID,
            ADD_FIXED_PRICE,
            abi.encode(
                collection,
                tokenId,
                quantity,
                currency,
                price,
                duration,
                startTime
            )
        );
    }

    function remove(
        address collection,
        uint256 tokenId,
        uint256 listingId
    ) external onlyManager {
        address storeAddress = MarketplaceStorageLib.storeAddress();

        Listing memory fixedPrice = IMarketStore(storeAddress).getOne(
            collection,
            tokenId,
            listingId
        );

        if (fixedPrice.collection == address(0)) revert NotFound();

        IMarketStore(storeAddress).remove(collection, tokenId, listingId);

        address receiptsAddress = FederalStorageLib
            .federalCoreStorageLayout()
            .receiptsAddress;

        IFederalReceiptsLink(receiptsAddress).emitReceipt(
            DOMAIN_ID,
            REMOVE_FIXED_PRICE,
            abi.encode(
                fixedPrice.collection,
                fixedPrice.tokenId,
                fixedPrice.quantity,
                fixedPrice.currency,
                fixedPrice.price,
                fixedPrice.duration,
                fixedPrice.startTime
            )
        );
    }

    function buyout(
        address collection,
        uint256 tokenId,
        uint256 listingId
    ) external {
        address buyer = msg.sender;
        address treasury = MarketplaceStorageLib
            .marketplaceStorageLayout()
            .treasury;

        address storeAddress = MarketplaceStorageLib.storeAddress();

        Listing memory fixedPrice = IMarketStore(storeAddress).getOne(
            collection,
            tokenId,
            listingId
        );

        if (fixedPrice.collection == address(0)) revert NotFound();

        if (block.timestamp < fixedPrice.startTime) revert NotValid();
        if (block.timestamp > fixedPrice.startTime + fixedPrice.duration)
            revert NotValid();

        bool ok = IERC20(fixedPrice.currency).transferFrom(
            buyer,
            treasury,
            fixedPrice.price
        );

        if (!ok) revert PaymentFailed();

        IAssetCollection(fixedPrice.collection).mint(
            buyer,
            tokenId,
            fixedPrice.quantity,
            ""
        );

        IMarketStore(storeAddress).remove(collection, tokenId, listingId);

        address receiptsAddress = FederalStorageLib
            .federalCoreStorageLayout()
            .receiptsAddress;

        IFederalReceiptsLink(receiptsAddress).emitReceipt(
            DOMAIN_ID,
            BUYOUT,
            abi.encode(
                fixedPrice.collection,
                fixedPrice.tokenId,
                fixedPrice.quantity,
                fixedPrice.currency,
                fixedPrice.price,
                buyer
            )
        );
    }
}
