import {
  type Abi,
  type Hash,
  type Address,
  type AbiFunction,
  toFunctionSelector,
} from "viem";

export function getSelectors(abi: Abi): Hash[] {
  return abi
    .filter((item): item is AbiFunction => item.type === "function")
    .map((fn) => {
      const signature = `${fn.name}(${fn.inputs
        .map((input) => input.type)
        .join(",")})`;

      return toFunctionSelector(signature);
    });
}

export function parseAbiInputs(inputs: any[]): string {
  if (!Array.isArray(inputs) || !inputs.length) return "";
  return inputs
    .map((input) => {
      if (input.type === "tuple") {
        return `(${parseAbiInputs(input.components)})`;
      }
      return input.type;
    })
    .join(",");
}

export enum FacetCutAction {
  Add = 0,
  Remove = 1,
}

export class FacetCut {
  public action: number;
  public facetAddress: Address;
  public functionSelectors: Hash[];

  constructor(abi: Abi, address: Address, action: FacetCutAction) {
    const selectors = getSelectors(abi);
    this.action = action;
    this.functionSelectors = selectors;
    this.facetAddress = address;
  }
}
