// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IFederalReceipts} from "./interfaces/IFederalReceiptsLink.sol";

contract FederalReceipts is IFederalReceipts {
    address private _coreAddress;
    mapping(address => bool) private _whitelist;

    modifier onlyFederalCore() {
        require(msg.sender == _coreAddress, "FederalReceipts: Not federal core");
        _;
    }

    modifier onlyWhitelisted() {
        require(
            msg.sender == _coreAddress || _whitelist[msg.sender],
            "FederalReceipts: Not whitelisted"
        );
        _;
    }

    event ReceiptEmitted(
        bytes32 indexed domainId,
        bytes32 indexed eventType,
        bytes data,
        address indexed emitter
    );

    constructor(address coreAddress) {
        require(
            coreAddress != address(0),
            "FederalReceipts: Core address cannot be zero"
        );
        _coreAddress = coreAddress;
    }

    function addWhitelist(
        address addr,
        bool whitelisted
    ) external onlyFederalCore {
        _whitelist[addr] = whitelisted;
        emit Whitelist(addr, whitelisted);
    }

    function emitReceipt(
        bytes32 domainId,
        bytes32 eventType,
        bytes calldata data
    ) external onlyWhitelisted {
        emit ReceiptEmitted(domainId, eventType, data, msg.sender);
    }

    function getCoreAddress() external view returns (address) {
        return _coreAddress;
    }

    function isWhitelisted(
        address addr,
        bool whitelisted
    ) external view returns (bool) {
        return _whitelist[addr] == whitelisted;
    }
}
