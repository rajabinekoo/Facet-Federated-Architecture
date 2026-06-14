// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IFederalRegistry} from "./interfaces/IFederalRegistry.sol";
import {IFederalRegistryLink} from "./interfaces/IFederalRegistryLink.sol";

contract FederalRegistry is IFederalRegistry, IFederalRegistryLink {
    address public owner;
    mapping(bytes4 => address) public facets;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function transferOwnership(address _owner) external {
        require(_owner != address(0), "FederalRegistry: Invalid owner address");
        owner = _owner;
    }

    function selectorToFacet(bytes4 sig) external view returns (address) {
        return facets[sig];
    }

    function diamondCut(FacetCut[] memory _facetCuts) external onlyOwner {
        for (uint256 facetIndex; facetIndex < _facetCuts.length; facetIndex++) {
            FacetCut memory cut = _facetCuts[facetIndex];
            require(
                cut.facetAddress != address(0),
                "FederalRegistry: facet address can't be address(0)"
            );
            require(
                cut.functionSelectors.length > 0,
                "FederalRegistry: No selectors in facet to cut"
            );
            if (cut.action == FacetCutAction.Add) {
                addFunctions(cut);
            } else if (cut.action == FacetCutAction.Remove) {
                removeFunctions(cut);
            } else {
                revert("FederalRegistry: Incorrect FacetCutAction");
            }
        }
        emit FederalRegistryCut(_facetCuts);
    }

    function addFunctions(FacetCut memory _facetCut) internal {
        for (
            uint256 selectorIndex;
            selectorIndex < _facetCut.functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _facetCut.functionSelectors[selectorIndex];
            if (facets[selector] != address(0)) {
                revert AddSelectorError(
                    selector,
                    "FederalRegistry: Can't add function that already exists"
                );
            }
            facets[selector] = _facetCut.facetAddress;
        }
    }

    function removeFunctions(FacetCut memory _facetCut) internal {
        for (
            uint256 selectorIndex;
            selectorIndex < _facetCut.functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _facetCut.functionSelectors[selectorIndex];
            if (facets[selector] == address(0)) {
                revert RemoveSelectorError(
                    selector,
                    "FederalRegistry: Can't remove a non-existent function"
                );
            }
            delete facets[selector];
        }
    }
}
