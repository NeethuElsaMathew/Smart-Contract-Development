// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library StringUtils {
    function joinStrings(string[] memory strings) internal pure returns (string memory) {
        string memory separator = '", "';
        string memory result = string(abi.encodePacked('["', strings[0]));

        for (uint256 i = 1; i < strings.length; i++) {
            result = string(abi.encodePacked(result, separator, strings[i]));
        }

        result = string(abi.encodePacked(result, '"]'));
        return result;
    }

    function joinIntegers(uint256[] memory integers) internal pure returns (string memory) {
        string memory separator = '", "';
        string memory result = string(abi.encodePacked('["', Strings.toString(integers[0])));

        for (uint256 i = 1; i < integers.length; i++) {
            result = string(abi.encodePacked(result, separator, Strings.toString(integers[i])));
        }

        result = string(abi.encodePacked(result, '"]'));
        return result;
    }
}