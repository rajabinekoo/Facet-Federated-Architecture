// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IMarketStore} from "./interfaces/IMarketStore.sol";
import {FederalSatellite} from "../../../core/FederalSatellite.sol";

contract MarketStore is IMarketStore, FederalSatellite {
    // collection => tokenId => listingId => Listing
    mapping(address => mapping(uint256 => mapping(uint256 => Listing)))
        private _fixedPrices;

    mapping(address => mapping(uint256 => uint256)) private _listingCount;

    error NotFound();
    error AlreadyInactive();

    constructor(address federalCore) FederalSatellite(federalCore) {}

    function create(
        address collection,
        address currency,
        uint256 tokenId,
        uint256 quantity,
        uint256 price,
        uint256 duration,
        uint256 startTime
    ) external onlyFederalCore {
        uint256 listingId = ++_listingCount[collection][tokenId];

        _fixedPrices[collection][tokenId][listingId] = Listing({
            collection: collection,
            currency: currency,
            tokenId: tokenId,
            quantity: quantity,
            price: price,
            duration: duration,
            startTime: startTime
        });
    }

    function getOne(
        address collection,
        uint256 tokenId,
        uint256 index
    ) external view returns (Listing memory) {
        Listing memory item = _fixedPrices[collection][tokenId][index];

        if (item.collection == address(0)) revert NotFound();

        return item;
    }

    function getAll(
        address collection,
        uint256 tokenId
    ) external view returns (Listing[] memory) {
        uint256 count = _listingCount[collection][tokenId];

        Listing[] memory result = new Listing[](count);

        uint256 j;

        for (uint256 i = 1; i <= count; i++) {
            Listing memory item = _fixedPrices[collection][tokenId][i];

            if (item.collection != address(0)) {
                result[j] = item;
                unchecked {
                    ++j;
                }
            }
        }

        return result;
    }

    function remove(
        address collection,
        uint256 tokenId,
        uint256 index
    ) external onlyFederalCore {
        Listing storage item = _fixedPrices[collection][tokenId][index];

        if (item.collection == address(0)) revert NotFound();

        delete _fixedPrices[collection][tokenId][index];
    }
}
