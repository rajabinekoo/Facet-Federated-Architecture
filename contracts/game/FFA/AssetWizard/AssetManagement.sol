// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IAssetCollection} from "./interfaces/IAssetCollection.sol";
import {FederalStorageLib} from "../../../core/FederalStorageLib.sol";
import {
    IFederalReceiptsLink
} from "../../../core/interfaces/IFederalReceiptsLink.sol";

contract AssetManagement {
    bytes32 private constant DOMAIN_ID = keccak256("ffa.domain.AssetWizard");
    bytes32 private constant TRANSFER_SINGLE = keccak256("TransferSingle");
    bytes32 private constant TRANSFER_BATCH = keccak256("TransferBatch");

    modifier onlyManager() {
        require(
            FederalStorageLib.isManager(msg.sender),
            "Caller is not a manager"
        );
        _;
    }

    function mint(
        address collection,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external onlyManager {
        IAssetCollection(collection).mint(to, tokenId, amount, data);
        address receiptsAddress = FederalStorageLib
            .federalCoreStorageLayout()
            .receiptsAddress;
        IFederalReceiptsLink(receiptsAddress).emitReceipt(
            DOMAIN_ID,
            TRANSFER_SINGLE,
            abi.encode(msg.sender, address(0), to, tokenId, amount)
        );
    }

    function batchMint(
        address collection,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyManager {
        IAssetCollection(collection).batchMint(to, tokenIds, amounts, data);
        address receiptsAddress = FederalStorageLib
            .federalCoreStorageLayout()
            .receiptsAddress;
        IFederalReceiptsLink(receiptsAddress).emitReceipt(
            DOMAIN_ID,
            TRANSFER_BATCH,
            abi.encode(msg.sender, address(0), to, tokenIds, amounts)
        );
    }

    function burn(
        address collection,
        address from,
        uint256 tokenId,
        uint256 amount
    ) external onlyManager {
        IAssetCollection(collection).burn(from, tokenId, amount);
        address receiptsAddress = FederalStorageLib
            .federalCoreStorageLayout()
            .receiptsAddress;
        IFederalReceiptsLink(receiptsAddress).emitReceipt(
            DOMAIN_ID,
            TRANSFER_SINGLE,
            abi.encode(msg.sender, from, address(0), tokenId, amount)
        );
    }

    function batchBurn(
        address collection,
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external onlyManager {
        IAssetCollection(collection).batchBurn(from, tokenIds, amounts);
        address receiptsAddress = FederalStorageLib
            .federalCoreStorageLayout()
            .receiptsAddress;
        IFederalReceiptsLink(receiptsAddress).emitReceipt(
            DOMAIN_ID,
            TRANSFER_BATCH,
            abi.encode(msg.sender, from, address(0), tokenIds, amounts)
        );
    }

    function setBaseURI(
        address collection,
        string calldata newBaseURI
    ) external onlyManager {
        IAssetCollection(collection).setBaseURI(newBaseURI);
    }
}
