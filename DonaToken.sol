// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DONA is ERC20 {
    address private owner;

    // Initialize the contract with an initial supply of 1000 DONA
    constructor() ERC20("DONA", "DT") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
