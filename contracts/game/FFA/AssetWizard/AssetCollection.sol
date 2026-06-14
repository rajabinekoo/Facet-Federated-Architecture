// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IAssetCollection} from "./interfaces/IAssetCollection.sol";
import {FederalSatellite} from "../../../core/FederalSatellite.sol";
import {
    IFederalReceiptsLink
} from "../../../core/interfaces/IFederalReceiptsLink.sol";
import {
    ERC1155,
    ERC1155TokenReceiver
} from "../../../vendors/solmate/tokens/ERC1155.sol";

contract AssetCollection is ERC1155, FederalSatellite, IAssetCollection {
    bytes32 private constant DOMAIN_ID =
        keccak256("ffa.domain.AssetWizard");
    bytes32 private constant TRANSFER_SINGLE = keccak256("TransferSingle");
    bytes32 private constant TRANSFER_BATCH = keccak256("TransferBatch");

    string public name;
    string public symbol;
    string private _baseURI;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory baseURI_
    ) FederalSatellite(msg.sender) {
        name = _name;
        symbol = _symbol;
        _baseURI = baseURI_;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string.concat(_baseURI, _toString(id));
    }

    function balance(
        address account,
        uint256 id
    ) public view returns (uint256) {
        return balanceOf[account][id];
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external onlyFederalCore {
        _mint(to, tokenId, amount, data);
    }

    function batchMint(
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyFederalCore {
        _batchMint(to, tokenIds, amounts, data);
    }

    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external onlyFederalCore {
        _burn(from, tokenId, amount);
    }

    function batchBurn(
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external onlyFederalCore {
        _batchBurn(from, tokenIds, amounts);
    }

    function setBaseURI(string calldata newBaseURI) external onlyFederalCore {
        _baseURI = newBaseURI;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override(ERC1155, IAssetCollection) {
        bool isOwnerOrApproved = msg.sender == from ||
            isApprovedForAll[from][msg.sender];

        bool isFederalCore = msg.sender == federalCore;

        require(isOwnerOrApproved || isFederalCore, "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        address receiptsAddress = getReceiptsAddress();
        IFederalReceiptsLink(receiptsAddress).emitReceipt(
            DOMAIN_ID,
            TRANSFER_SINGLE,
            abi.encode(msg.sender, from, to, id, amount)
        );

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override(ERC1155, IAssetCollection) {
        bool isOwnerOrApproved = msg.sender == from ||
            isApprovedForAll[from][msg.sender];

        bool isFederalCore = msg.sender == federalCore;

        require(isOwnerOrApproved || isFederalCore, "NOT_AUTHORIZED");

        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i; i < ids.length; ) {
            balanceOf[from][ids[i]] -= amounts[i];
            balanceOf[to][ids[i]] += amounts[i];

            unchecked {
                ++i;
            }
        }

        address receiptsAddress = getReceiptsAddress();
        IFederalReceiptsLink(receiptsAddress).emitReceipt(
            DOMAIN_ID,
            TRANSFER_BATCH,
            abi.encode(msg.sender, from, to, ids, amounts)
        );

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}
