// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

interface IEvents {
    event AddListing(
        address collection,
        uint256 tokenId,
        uint256 quantity,
        address currency,
        uint256 price,
        uint256 duration,
        uint256 startTime
    );

    event RemoveListing(
        address collection,
        uint256 tokenId,
        uint256 quantity,
        address currency,
        uint256 price,
        uint256 duration,
        uint256 startTime
    );

    event Buyout(
        address collection,
        uint256 tokenId,
        uint256 quantity,
        address currency,
        uint256 price,
        address buyer
    );

    event AirdropCreated(
        address collection,
        uint256 tokenId,
        uint256 quantity,
        uint256 count,
        uint256 duration,
        uint256 startTime
    );

    event AirdropClaimed(
        address collection,
        uint256 tokenId,
        uint256 quantity,
        address claimer
    );

    event AirdropRemoved(
        address collection,
        uint256 tokenId,
        uint256 quantity,
        uint256 count,
        uint256 duration,
        uint256 startTime
    );
}
