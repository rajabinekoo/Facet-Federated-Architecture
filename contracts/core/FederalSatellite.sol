// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IFederalCoreSatelliteLink} from "./interfaces/IFederalCoreSatelliteLink.sol";

contract FederalSatellite {
    address public federalCore;

    modifier onlyFederalCore() {
        require(msg.sender == federalCore, "Not Federal Core");
        _;
    }

    constructor(address _federalCore) {
        federalCore = _federalCore;
    }

    function changeFederalCore(address newCore) external onlyFederalCore {
        federalCore = newCore;
    }

    function getReceiptsAddress() public view returns (address) {
        return IFederalCoreSatelliteLink(federalCore).getReceiptsAddress();
    }
}
