// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {FederalStorageLib} from "./FederalStorageLib.sol";
import {IFederalCore} from "./interfaces/IFederalCore.sol";
import {IFederalRegistryLink} from "./interfaces/IFederalRegistryLink.sol";

contract FederalCore is IFederalCore {
    modifier onlyOwner() {
        require(
            msg.sender == FederalStorageLib.federalCoreStorageLayout().owner,
            "Not owner"
        );
        _;
    }

    constructor(address _owner) {
        FederalStorageLib.federalCoreStorageLayout().owner = _owner;
        FederalStorageLib.federalCoreStorageLayout().core = address(this);
    }

    function getReceiptsAddress() external view returns (address) {
        return FederalStorageLib.federalCoreStorageLayout().receiptsAddress;
    }

    function changeReceipts(address newReceiptsAddress) external onlyOwner {
        FederalStorageLib
            .federalCoreStorageLayout()
            .receiptsAddress = newReceiptsAddress;
    }

    function addRegistries(
        bytes32[] calldata domainIds,
        address[] calldata registries
    ) external onlyOwner {
        require(domainIds.length == registries.length, "Mismatched lengths");
        require(domainIds.length != 0, "Empty arrays");

        uint256 len = domainIds.length;
        for (uint256 i = 0; i < len; i++) {
            bytes32 domainId = domainIds[i];
            address registry = registries[i];

            require(domainId != bytes32(0), "Invalid domain ID");
            require(registry != address(0), "Invalid registry address");

            FederalStorageLib.federalCoreStorageLayout().federalRegistries[
                domainId
            ] = registry;
            emit RegistryAdded(domainId, registry);
        }
    }

    function removeRegistries(bytes32[] calldata domainIds) external onlyOwner {
        require(domainIds.length != 0, "Empty array");

        uint256 len = domainIds.length;
        for (uint256 i = 0; i < len; i++) {
            bytes32 domainId = domainIds[i];
            if (
                FederalStorageLib.federalCoreStorageLayout().federalRegistries[
                    domainId
                ] != address(0)
            ) {
                FederalStorageLib.federalCoreStorageLayout().federalRegistries[
                    domainId
                ] = address(0);
                emit RegistryRemoved(domainId);
            }
        }
    }

    function getRegistryAddress(
        bytes32 domainId
    ) external view returns (address) {
        return
            FederalStorageLib.federalCoreStorageLayout().federalRegistries[
                domainId
            ];
    }

    receive() external payable {}

    fallback() external payable {
        bytes32 domainId;
        bytes4 selector;

        assembly {
            domainId := calldataload(0)
            selector := calldataload(32)
        }

        require(domainId != bytes32(0), "Invalid domain ID");
        address registry = FederalStorageLib
            .federalCoreStorageLayout()
            .federalRegistries[domainId];
        require(registry != address(0), "Registry not found for domain");

        address facetAddress = IFederalRegistryLink(registry).selectorToFacet(
            selector
        );
        require(facetAddress != address(0), "Function does not exist");

        assembly {
            let size := sub(calldatasize(), 32)

            calldatacopy(0, 32, size)

            let result := delegatecall(gas(), facetAddress, 0, size, 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
