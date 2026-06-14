// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IData} from "./IData.sol";

interface IAirdrop is IData {
    function newAirdrop(
        address collection,
        uint256 tokenId,
        uint256 quantity,
        uint256 count,
        uint256 duration,
        uint256 startTime
    ) external;

    function claim(uint256 index) external;

    function remove(uint256 index) external;

    function initAirdrop(address store_) external;
}
