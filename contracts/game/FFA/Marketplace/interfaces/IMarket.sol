// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IData} from "./IData.sol";

interface IMarket is IData {
    function remove(
        address collection,
        uint256 tokenId,
        uint256 listingId
    ) external;

    function create(
        address collection,
        address currency,
        uint256 tokenId,
        uint256 quantity,
        uint256 price,
        uint256 duration,
        uint256 startTime
    ) external;

    function buyout(
        address collection,
        uint256 tokenId,
        uint256 listingId
    ) external;
}
