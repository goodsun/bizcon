// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// DonateManager
contract Orders {
    address public owner;
    address[] public admins;

    uint256 public lastOrderNum;
    address[] private eoas;
    uint256[] private dates;
    uint256[] private prices;
    string[] private urls;
    mapping(address => uint256[]) private assets;

    constructor() {
        owner = msg.sender;
        admins.push(msg.sender);
        lastOrderNum = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Caller is not an admin");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == account) {
                return true;
            }
        }
        return false;
    }

    function addAdmin(address account) external onlyOwner {
        require(!isAdmin(account), "Account is already an admin");
        admins.push(account);
    }

    function removeAdmin(address account) external onlyOwner {
        require(isAdmin(account), "Account is not an admin");
        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == account) {
                admins[i] = admins[admins.length - 1];
                admins.pop();
                break;
            }
        }
    }

    event OrderPlaced(uint256 orderNum, address indexed sender, uint256 timestamp, uint256 value, string url);

    function order() public payable returns (uint256) {
        require(msg.value > 0, "Donation amount must be greater than zero");
        eoas.push(msg.sender);
        dates.push(block.timestamp);
        prices.push(msg.value);
        urls.push("upload_waiting");
        assets[msg.sender].push(lastOrderNum);
        emit OrderPlaced(lastOrderNum, msg.sender, block.timestamp, msg.value, "upload_waiting");
        lastOrderNum++;
        return lastOrderNum - 1;
    }

    function setUrl(uint256 orderNum, string memory url) external {
        require(eoas[orderNum] == msg.sender, "Can't set URL. File owner only");
        urls[orderNum] = url;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance in contract");
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // Getter functions for private variables
    function getOrderDetails(uint256 orderNum) public view returns (address, uint256, uint256, string memory) {
        require(orderNum < lastOrderNum, "Invalid order number");
        return (eoas[orderNum], dates[orderNum], prices[orderNum], urls[orderNum]);
    }

    function getAssets(address user) public view returns (uint256[] memory) {
        return assets[user];
    }

    // Function to get order list by EOA
    function getOrdersByEOA(address eoa) public view returns (uint256[] memory orderNums, uint256[] memory orderPrices, string[] memory orderUrls, uint256[] memory orderDates) {
        uint256[] memory userOrders = assets[eoa];
        orderNums = new uint256[](userOrders.length);
        orderPrices = new uint256[](userOrders.length);
        orderUrls = new string[](userOrders.length);
        orderDates = new uint256[](userOrders.length);

        for (uint256 i = 0; i < userOrders.length; i++) {
            uint256 orderNum = userOrders[i];
            orderNums[i] = orderNum;
            orderPrices[i] = prices[orderNum];
            orderUrls[i] = urls[orderNum];
            orderDates[i] = dates[orderNum];
        }
        return (orderNums, orderPrices, orderUrls, orderDates);
    }
}
