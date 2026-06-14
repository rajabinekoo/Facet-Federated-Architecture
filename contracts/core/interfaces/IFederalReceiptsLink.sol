// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

interface IFederalReceiptsLink {
    function emitReceipt(
        bytes32 domainId,
        bytes32 eventType,
        bytes calldata data
    ) external;
    function addWhitelist(address addr, bool whitelisted) external;
}

interface IFederalReceipts {
    event Whitelist(address indexed addr, bool isWhitelisted);

    function addWhitelist(address addr, bool whitelisted) external;

    function emitReceipt(
        bytes32 domainId,
        bytes32 eventType,
        bytes calldata data
    ) external;

    function getCoreAddress() external view returns (address);

    function isWhitelisted(address addr, bool whitelisted) external view returns (bool);
}
