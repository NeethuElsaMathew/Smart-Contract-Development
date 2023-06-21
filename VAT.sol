// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VAT is ERC20 {
    constructor() ERC20("VAT Token", "VAT") {}

    enum State {
        EndCustomer,
        Retailer
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
