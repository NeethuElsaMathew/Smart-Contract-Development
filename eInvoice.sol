// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./VAT.sol";
import "./Sale.sol";
import "./TaxAuthority.sol";
import "./SellerInterface.sol";
import "./StringUtils.sol";


contract eInvoice {
    using StringUtils for string[];
    using StringUtils for uint256[];
    struct Invoice {
        address seller;
        address buyer;
        string[] items;
        string itemsList;
        uint256[] qtys;
        string qtyList;
        uint256 totalPrice;
        uint256 netPrice;
        VAT.State state;
        uint256 vatAmount;
        uint256 vatTokenPassed;
        bool paid;
    }

    struct Item {
        uint256 pricePerUnit;
        uint256 quantity;
    }

    VAT vat;
    Invoice public invoice;
    address private association;
    TaxAuthority taxAuthority;
    Sale sale;
    SellerInterface sellerContract;
    uint256 balance;

    event InvoiceCreated(
        address indexed user,
        uint256 invoiceId,
        uint256 totalPrice,
        VAT.State state
        // uint256 vatPrice
    );

    constructor(
        address _sale,
        address _association,
        address _taxAuthority,
        address _vatTokenAddress
    ) {
        sale = Sale(_sale);
        association = _association;
        vat = VAT(_vatTokenAddress);
        taxAuthority = TaxAuthority(_taxAuthority);
        sellerContract = SellerInterface(_association);
    }

    // function calcVatAmount(string[] memory _items, uint256[] memory _qtys) private view returns (uint) {
    //     uint vatAmount = 0;
    //     for (uint i = 0; i < _items.length; i++) {
    //         vatAmount += (items[_items[i]].pricePerUnit * _qtys[i] * taxRate) / 100;
    //     }
    //     return vatAmount;
    // }

    function create(
        address _buyer,
        string[] memory _items,
        uint256[] memory _qtys,
        uint256 _netPrice,
        VAT.State _state
        // uint256 _vatAmount,
        // uint256 _vatToken
    ) external payable returns (Invoice memory) {
        uint256 invoiceId = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        );
        require(
            taxAuthority.isAddressRegistered(association),
            "Organisation not Registered with Tax Authority"
        );
        // uint256 netVatAmount = _vatAmount - _vatToken;
        uint256 taxRate = taxAuthority.getOrganisationTaxDetails(association).taxRate;
        uint256 _vatAmount = (_netPrice * taxRate)/100;
        uint256 _totalPrice = _netPrice + _vatAmount;
        invoice.seller = association;
        invoice.buyer = _buyer;
        invoice.items = _items;
        invoice.itemsList = _items.joinStrings();
        invoice.qtys = _qtys;
        invoice.qtyList = _qtys.joinIntegers();
        invoice.totalPrice = _totalPrice;
        invoice.netPrice = _netPrice;
        invoice.state = _state;
        invoice.vatAmount = _vatAmount;
        invoice.vatTokenPassed = 0;
        invoice.paid = false;
        emit InvoiceCreated(
            msg.sender,
            invoiceId,
            _totalPrice,
            _state
            // invoice.netVatAmount
        );
        return invoice;
    }

    function purchase(uint256 vatToken) public payable {
        require(
            msg.value == invoice.totalPrice - vatToken,
            "Total Amount Mismatch"
        );
        require(msg.sender == invoice.buyer, "Buyer Mismatch");
        require(
            vat.balanceOf(msg.sender) >= vatToken,
            "Insufficient Token Balance"
        );
        
        if (vatToken != 0) {
            sellerContract.deposit{value: invoice.totalPrice - vatToken}();
            vat.transferFrom(msg.sender, address(taxAuthority), vatToken);
        } else {
            sellerContract.deposit{value: invoice.netPrice}();
            taxAuthority.sendVatToken{value: invoice.vatAmount}(address(association));
        }

        invoice.paid = true;
        sale.updateItems(invoice.items, invoice.qtys);
    }

    function getAmount() public payable {
        balance += msg.value;
    }

    function getInvoiceDetails() public view returns (Invoice memory) {
        return invoice;
    }
}