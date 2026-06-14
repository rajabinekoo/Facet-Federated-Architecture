// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IData} from "./IData.sol";

interface IMarketStore is IData {
    function getOne(
        address collection,
        uint256 tokenId,
        uint256 index
    ) external view returns (Listing memory);

    function getAll(
        address collection,
        uint256 tokenId
    ) external view returns (Listing[] memory);

    function remove(
        address collection,
        uint256 tokenId,
        uint256 index
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
}
