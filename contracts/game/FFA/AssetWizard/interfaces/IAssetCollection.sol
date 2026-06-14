// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

interface IAssetCollection {
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external;

    function batchMint(
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function burn(address from, uint256 tokenId, uint256 amount) external;

    function batchBurn(
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    function setBaseURI(string calldata newBaseURI) external;

    function balance(
        address account,
        uint256 id
    ) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
