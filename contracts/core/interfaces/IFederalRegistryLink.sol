// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

interface IFederalRegistryLink {
    function selectorToFacet(bytes4 sig) external view returns (address);
}
