// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {ERC20} from "../../../vendors/solmate/tokens/ERC20.sol";

contract MockUSDT is ERC20 {
    address public owner;

    error NotOwner();

    constructor() ERC20("Tether USD", "USDT", 6) {
        owner = msg.sender;
        _mint(msg.sender, 1_000_000 * 10 ** 6);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}
