// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./VAT.sol";

contract TaxAuthority {
    // Mapping from address to Tax Category and Tax Rate
    struct taxInfo {
        string taxCategory;
        uint256 taxRate;
    }
    taxInfo txinf;
    mapping(address => taxInfo) registeredOrganisations;
    address[] public registeredAddresses;
    string[] availableTaxCategories;
    mapping(string => uint256) public taxClass;

    uint256 public registerFee;

    VAT vat;

    constructor(uint256 _registerFee, address _vatTokenAddress) {
        registerFee = _registerFee;
        availableTaxCategories = [
            "Trade",
            "Manufacturing",
            "Construction",
            "AgricultureFishing",
            "Forestry",
            "Mining",
            "Services",
            "SmallBusinesses",
            "CharitableOrganisations",
            "GoodsServices"
        ];
        taxClass["Trade"] = 19;
        taxClass["Manufacturing"] = 19;
        taxClass["Construction"] = 19;
        taxClass["AgricultureFishing"] = 19;
        taxClass["Forestry"] = 19;
        taxClass["Mining"] = 19;
        taxClass["Services"] = 19;
        taxClass["SmallBusinesses"] = 16;
        taxClass["CharitableOrganisations"] = 0;
        taxClass["GoodsServices"] = 7;

        vat = VAT(_vatTokenAddress);
    }

    // Function to register a contract
    function register(
        string memory _category,
        address _address
    ) public payable returns (uint256) {
        require(msg.value == registerFee, "Incorrect fee");
        require(!isAddressRegistered(_address), "Address already Registered");
        txinf = taxInfo(_category, taxClass[_category]);
        registeredOrganisations[_address] = txinf;
        registeredAddresses.push(_address);
        return taxClass[_category];
    }

    function sendVatToken(address _association) external payable {
        uint256 tokenAmount = msg.value;
        if (isAddressRegistered(_association)) {
            vat.mint(_association, tokenAmount);
        }
    }

    function reimburseVatToken(uint256 vatToken) public payable {
        require(
            vat.balanceOf(msg.sender) >= vatToken,
            "Insufficient Token Balance"
        );
        vat.transferFrom(msg.sender, address(this), vatToken);
        payable(msg.sender).transfer(vatToken);
    }

    function getTaxCategories() public view returns (string[] memory) {
        return availableTaxCategories;
    }

    function getTaxRates(
        string memory _category
    ) public view returns (uint256) {
        return taxClass[_category];
    }

    function getRegisteredAddresses() public view returns (address[] memory) {
        return registeredAddresses;
    }

    function getOrganisationTaxDetails(
        address _address
    ) public view returns (taxInfo memory) {
        return registeredOrganisations[_address];
    }

    function isAddressRegistered(address _address) public view returns (bool) {
        for (uint256 i = 0; i < registeredAddresses.length; i++) {
            if (registeredAddresses[i] == _address) {
                return true;
            }
        }
        return false;
    }
}