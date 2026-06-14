// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

library MarketplaceStorageLib {
    bytes32 constant MARKETPLACE_POSITION =
        keccak256("federal.architecture.marketplace.storage");

    struct MarketplaceStorage {
        address treasury;
        address airdropStore;
        uint256 storeIndex;
        mapping(uint256 => address) stores;
    }

    function marketplaceStorageLayout()
        internal
        pure
        returns (MarketplaceStorage storage ds)
    {
        bytes32 position = MARKETPLACE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function storeAddress() internal view returns (address) {
        return
            marketplaceStorageLayout().stores[
                marketplaceStorageLayout().storeIndex
            ];
    }
}
