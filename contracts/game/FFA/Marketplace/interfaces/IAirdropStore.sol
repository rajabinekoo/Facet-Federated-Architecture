// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IData} from "./IData.sol";

interface IAirdropStore is IData {
    function getOne(uint256 index) external view returns (Airdrop memory);

    function getAll(
        uint256 page,
        uint256 size
    ) external view returns (Airdrop[] memory);

    function remove(uint256 index) external;

    function create(Airdrop memory airdrop) external;

    function updateCount(uint256 index, uint256 newCount) external;
}
