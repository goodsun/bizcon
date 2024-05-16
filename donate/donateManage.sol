// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
// DonateManager
contract donateManage {
    address private _owner;
    uint256 public _lastDonateId;
    uint256 public _lastUseId;
    address[] public _admins;
    address[] public _donors;
    address[] public _senders;
    uint256[] public _donationAmounts;
    uint256[] public _donationDates;
    address[] public _useDonors;
    uint256[] public _usePoints;
    uint256[] public _useDates;
    mapping(address => uint256) public _totalDonations;
    mapping(address => uint256) public _usedPoints;
    uint256 public _allTotalDonations;
    uint256 public _allUsedPoints;

    constructor() {
        _owner = msg.sender;
        _admins.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Caller is not an admin");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        for (uint i = 0; i < _admins.length; i++) {
            if (_admins[i] == account) {
                return true;
            }
        }
        return false;
    }

    function addAdmin(address account) external onlyOwner {
        require(!isAdmin(account), "Account is already an admin");
        _admins.push(account);
    }

    function removeAdmin(address account) external onlyOwner {
        require(isAdmin(account), "Account is not an admin");
        for (uint i = 0; i < _admins.length; i++) {
            if (_admins[i] == account) {
                _admins[i] = _admins[_admins.length - 1];
                _admins.pop();
                break;
            }
        }
    }

    function donate(address donor) public payable {
        require(msg.value > 0, "Donation amount must be greater than zero");

        // Calculate gas cashback (1% of donation amount)
        uint256 gasCashback = msg.value / 100;

        // Send gas cashback to donor
        (bool success, ) = payable(donor).call{value: gasCashback}("");
        require(success, "Failed to send gas cashback");

        // Record donation
        _lastDonateId++;
        _donors.push(donor);
        _senders.push(msg.sender);
        _donationAmounts.push(msg.value);
        _donationDates.push(block.timestamp);
        _totalDonations[donor] += msg.value;
        _allTotalDonations += msg.value;
    }

    function usePoint(address donor, uint256 usepoint) external {
        require(
            _totalDonations[donor] - _usedPoints[donor] > usepoint,
            "not enough points"
        );
        _lastUseId++;
        _useDonors.push(donor);
        _usePoints.push(usepoint);
        _useDates.push(block.timestamp);
        _usedPoints[donor] += usepoint;
        _allUsedPoints += usepoint;
    }

    function latestPoint(address donor) external view returns (uint256) {
        return _totalDonations[donor] - _usedPoints[donor];
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(
            address(this).balance >= amount,
            "Insufficient balance in contract"
        );
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function totalSupply() external view returns (uint256) {
        return _allTotalDonations - _allUsedPoints;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _totalDonations[account] - _usedPoints[account];
    }
    function transfer(
        address /* recipient */,
        uint256 /* amount */
    ) external pure returns (bool) {
        revert("Token transfers are disabled");
    }

    function allowance(
        address /* owner */,
        address /* spender */
    ) external pure returns (uint256) {
        return 0;
    }

    function approve(
        address /* spender */,
        uint256 /* amount */
    ) external pure returns (bool) {
        revert("Token approvals are disabled");
    }

    function transferFrom(
        address /* sender */,
        address /* recipient */,
        uint256 /* amount */
    ) external pure returns (bool) {
        revert("Token transfers are disabled");
    }
}
