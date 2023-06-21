// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./DonaToken.sol";
import "./TaxAuthority.sol";

contract Donation {
    DONA donaToken;
    TaxAuthority taxAuthority;

    constructor(address _taxAuthority, address _donaTokenAddress) {
        donaToken = DONA(_donaTokenAddress);
        taxAuthority = TaxAuthority(_taxAuthority);
    }

    function disburseDonaToken(address _donator, uint256 _tokenValue) external {
        require(
            taxAuthority.isAddressRegistered(msg.sender),
            "Address not Registered with Tax Authority"
        );
        if (
            keccak256(
                abi.encodePacked(
                    taxAuthority
                        .getOrganisationTaxDetails(msg.sender)
                        .taxCategory
                )
            ) == keccak256(abi.encodePacked("CharitableOrganisations"))
        ) {
            donaToken.mint(_donator, _tokenValue);
        }
    }
}
