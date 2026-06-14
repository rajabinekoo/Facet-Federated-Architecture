// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IAirdropStore} from "./interfaces/IAirdropStore.sol";
import {FederalSatellite} from "../../../core/FederalSatellite.sol";

contract AirdropStore is IAirdropStore, FederalSatellite {
    mapping(uint256 => Airdrop) private _airdrops;
    uint256 private _airdropsCount;

    error NotFound();
    error AlreadyInactive();

    constructor(address federalCore) FederalSatellite(federalCore) {}

    function create(Airdrop memory airdrop) external onlyFederalCore {
        uint256 index = ++_airdropsCount;
        _airdrops[index] = airdrop;
    }

    function updateCount(
        uint256 index,
        uint256 newCount
    ) external onlyFederalCore {
        Airdrop storage item = _airdrops[index];

        if (item.collection == address(0)) revert NotFound();
        if (item.quantity == 0) revert AlreadyInactive();

        item.quantity = newCount;
    }

    function getOne(uint256 index) external view returns (Airdrop memory) {
        return _airdrops[index];
    }

    function getAll(
        uint256 page,
        uint256 size
    ) external view returns (Airdrop[] memory) {
        uint256 count = _airdropsCount;
        uint256 start = (page - 1) * size;
        uint256 end = start + size;

        Airdrop[] memory result = new Airdrop[](count);

        uint256 j;

        for (uint256 i = start; i < end && i < count; i++) {
            Airdrop memory item = _airdrops[i];

            if (item.collection != address(0)) {
                result[j] = item;
                unchecked {
                    ++j;
                }
            }
        }

        return result;
    }

    function remove(uint256 index) external onlyFederalCore {
        Airdrop storage item = _airdrops[index];

        if (item.collection == address(0)) revert NotFound();

        delete _airdrops[index];
    }
}
