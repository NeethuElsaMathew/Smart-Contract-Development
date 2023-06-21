// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./VAT.sol";
import "./eInvoice.sol";
import "./TaxAuthority.sol";
import "./SellerInterface.sol";

contract Sale {
    //Initialize eInvoice and TaxAuthority
    VAT vat;
    SellerInterface sellerContract;
    address sellerAddress;
    address owner;
    uint256 taxRate;
    string[] itemList;
    address VATTokenContract;
    TaxAuthority taxAuthority;
    mapping(string => Item) items;
    struct Item {
        uint256 pricePerUnit;
        uint256 quantity;
    }

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

    struct Income {
        address spender;
        uint256 amount;
        uint256 timeOfIncome;
        bool feePayment;
    }

    Invoice invoicesNew;
    Income[] public incomes;
    address[] invoiceArray;
    eInvoice.Invoice invoice;
    address public eInvoiceAddress;
    mapping(address => Invoice[]) public invoiceDetails;
    mapping(address => Invoice[]) buyerToInvoices;

    constructor(
        address _Seller,
        address _TaxAuthority,
        address _VATTokenContract
    ) {
        //Initialize values for TaxAuthority and eInvoice
        //Initialize Store Items
        taxRate = 0;
        owner = msg.sender;
        VATTokenContract = _VATTokenContract;
        vat = VAT(_VATTokenContract);

        sellerAddress = _Seller;
        sellerContract = SellerInterface(_Seller);

        taxAuthority = TaxAuthority(_TaxAuthority);

        items["Book"] = Item(100 wei, 100);
        items["Magazine"] = Item(500 wei, 100);
        items["Newspaper"] = Item(200 wei, 200);
        itemList = ["Book", "Magazine", "Newspaper"];
    }

    /*
     *Registration in Tax Authority
     */

    function register(string memory _organisationCategory) public payable {
        require(
            sellerContract.isBoardMember(msg.sender),
            "Unauthorised Access"
        );
        taxRate = taxAuthority.register{value: msg.value}(
            _organisationCategory,
            sellerAddress
        );
    }

    function getNetPrice(
        string[] memory _items,
        uint256[] memory _qtys
    ) public view returns (uint256) {
        uint256 netPrice = 0;
        for (uint i = 0; i < _items.length; i++) {
            netPrice += items[_items[i]].pricePerUnit * _qtys[i];
        }
        return netPrice;
    }

    function exists(string[] memory _items) private view returns (bool) {
        for (uint i = 0; i < _items.length; i++) {
            bool found = false;
            for (uint j = 0; j < itemList.length; j++) {
                if (keccak256(abi.encodePacked(_items[i])) == keccak256(abi.encodePacked(itemList[j]))) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                return false;
            }
        }
        return true;
    }

    function qtyCheck(string[] memory _items, uint256[] memory _qtys) private view returns (bool) {
        require(_items.length == _qtys.length, "Input lists must have the same length");

        for (uint256 i = 0; i < _items.length; i++) {
            if (items[_items[i]].quantity < _qtys[i]) {
                return false;
            }
        }
        return true;
    }

    function updateItems(string[] memory _items, uint256[] memory _qtys) external {
        require(_items.length == _qtys.length, "Input lists must have the same length");
        for (uint i = 0; i < _items.length; i++) {
            string memory item = _items[i];
            uint256 qty = _qtys[i];
            items[item].quantity -= qty;
        }
    }

    function getInvoice(
        string[] memory _items,
        uint256[] memory _qtys,
        // uint256 _totalPrice,
        VAT.State _state
        // uint256 _vatToken
    ) public payable returns (address) {
        require(exists(_items), "Invalid Entry");
        require(qtyCheck(_items, _qtys), "Out of Stock");
        // uint256 vatAmount = calcVatAmount(_items, _qtys);
        eInvoice eInvoiceContract = new eInvoice(
            address(this),
            sellerAddress,
            address(taxAuthority),
            VATTokenContract
        );
        eInvoiceAddress = address(eInvoiceContract);
        invoice = eInvoiceContract.create(
            msg.sender,
            _items,
            _qtys,
            getNetPrice(_items, _qtys),
            _state
            // vatAmount,
            // _vatToken
        );
        Invoice memory inv = convert(invoice);
        buyerToInvoices[msg.sender].push(inv);
        invoiceDetails[eInvoiceAddress].push(inv);
        invoiceArray.push(eInvoiceAddress);
        return address(eInvoiceContract);
    }

    function deposit() public payable {
        incomes.push(Income(msg.sender, msg.value, block.timestamp, false));
    }

    function convert(
        eInvoice.Invoice memory _invoice
    ) private pure returns (Invoice memory) {
        Invoice memory newInvoice;
        newInvoice.seller = _invoice.seller;
        newInvoice.buyer = _invoice.buyer;
        newInvoice.items = _invoice.items;
        newInvoice.itemsList = _invoice.itemsList;
        newInvoice.qtys = _invoice.qtys;
        newInvoice.qtyList = _invoice.qtyList;
        newInvoice.totalPrice = _invoice.totalPrice;
        newInvoice.netPrice = _invoice.netPrice;
        newInvoice.state = _invoice.state;
        newInvoice.vatAmount = _invoice.vatAmount;
        newInvoice.vatTokenPassed = _invoice.vatTokenPassed;
        newInvoice.paid = _invoice.paid;
        return newInvoice;
    }

    function getInvoiceDetails(
        address _invoice
    ) public view returns (Invoice[] memory) {
        return invoiceDetails[_invoice];
    }

    function getDeployedInvoices() public view returns (address[] memory) {
        return invoiceArray;
    }

    function getBuyerInvoices(
        address _buyer
    ) public view returns (Invoice[] memory) {
        return buyerToInvoices[_buyer];
    }

    function restoreItem(string memory _item, uint256 _rstrVal) public {
        require(msg.sender == owner, "Unauthorized Access");
        items[_item].quantity += _rstrVal;
    }

    function getVatTokenBalance(
        address _address
    ) external view returns (uint256) {
        return vat.balanceOf(_address);
    }

    function getItemInfo(
        string memory itemName
    ) public view returns (string memory, uint256, uint256) {
        Item memory item = items[itemName];
        return (itemName, item.pricePerUnit, item.quantity);
    }

    function getItemInfoAll()
        public
        view
        returns (string[] memory, uint256[] memory, uint256[] memory)
    {
        uint256 itemCount = 3;
        string[] memory itemNames = new string[](itemCount);
        uint256[] memory itemPrices = new uint256[](itemCount);
        uint256[] memory itemQuantities = new uint256[](itemCount);

        itemNames[0] = "Book";
        itemPrices[0] = items["Book"].pricePerUnit;
        itemQuantities[0] = items["Book"].quantity;

        itemNames[1] = "Magazine";
        itemPrices[1] = items["Magazine"].pricePerUnit;
        itemQuantities[1] = items["Magazine"].quantity;

        itemNames[2] = "Newspaper";
        itemPrices[2] = items["Newspaper"].pricePerUnit;
        itemQuantities[2] = items["Newspaper"].quantity;

        return (itemNames, itemPrices, itemQuantities);
    }
}