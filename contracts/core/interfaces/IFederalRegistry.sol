// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

interface IFederalRegistry {
    error AddSelectorError(bytes4 selector, string message);
    error RemoveSelectorError(bytes4 selector, string message);

    event FederalRegistryCut(FacetCut[] facetCuts);

    enum FacetCutAction {
        Add,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    function diamondCut(FacetCut[] memory _facetCuts) external;
}
