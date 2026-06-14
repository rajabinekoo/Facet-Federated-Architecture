// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

interface IData {
    struct Listing {
        address collection;
        address currency;
        uint256 tokenId;
        uint256 quantity;
        uint256 price;
        uint256 duration;
        uint256 startTime;
    }

    struct Airdrop {
        address collection;
        uint256 tokenId;
        uint256 quantity;
        uint256 count;
        uint256 duration;
        uint256 startTime;
    }
}
