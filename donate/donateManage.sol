// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// DonateManager
contract donateManage {
    address public _owner;
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


    struct Donation {
        uint256 amount;
        uint256 date;
        string detail;
    }

    struct SubstituteDonation {
        uint256 amount;
        address donor;
        uint256 date;
        string detail;
    }

    struct UsePoints {
        uint256 amount;
        uint256 date;
        string detail;
    }
    
    mapping(address => Donation[]) public _donationHistory;
    mapping(address => SubstituteDonation[]) public _substituteDonationHistory;
    mapping(address => UsePoints[]) public _usePointsHistory;

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

    receive() external payable {
        require(msg.value > 0, "Please send some Ether");
        donate(msg.sender, "RECEIVE");
    }

    function donate(address donor, string memory detail) public payable {
        require(msg.value > 0, "Donation amount must be greater than zero");
        uint256 donateAmount = msg.value;
        _lastDonateId++;
        _donors.push(donor);
        _senders.push(msg.sender);
        _donationAmounts.push(donateAmount);
        _donationDates.push(block.timestamp);
        _totalDonations[donor] += donateAmount;
        _allTotalDonations += donateAmount;

        // Add to donation history
        _donationHistory[donor].push(Donation(donateAmount, block.timestamp, detail));
        if (msg.sender != donor) {
          _substituteDonationHistory[msg.sender].push(SubstituteDonation(donateAmount, donor, block.timestamp, detail));
        }
    }

    function donate(address donor, string memory detail, uint256 gasCashback) public payable {
        require(msg.value > 0, "Donation amount must be greater than zero");
        require(
            msg.value > gasCashback,
            "Donation amount must be greater than Cashback"
        );
        uint256 donateAmount = msg.value;
        if (msg.sender != donor) {
            donateAmount = msg.value - gasCashback;
            (bool success, ) = payable(donor).call{value: gasCashback}("");
            require(success, "Failed to send gas cashback");
        }
        _lastDonateId++;
        _donors.push(donor);
        _senders.push(msg.sender);
        _donationAmounts.push(donateAmount);
        _donationDates.push(block.timestamp);
        _totalDonations[donor] += donateAmount;
        _allTotalDonations += donateAmount;

        // Add to donation history
        _donationHistory[donor].push(Donation(donateAmount, block.timestamp, detail));
        if (msg.sender != donor) {
          _substituteDonationHistory[msg.sender].push(SubstituteDonation(donateAmount, donor, block.timestamp, detail));
        }
    }

    function usePoint(address donor, uint256 usepoint) external {
        require(
            _totalDonations[donor] - _usedPoints[donor] >= usepoint,
            "not enough points"
        );
        _lastUseId++;
        _useDonors.push(donor);
        _usePoints.push(usepoint);
        _useDates.push(block.timestamp);
        _usedPoints[donor] += usepoint;
        _allUsedPoints += usepoint;
        _usePointsHistory[donor].push(UsePoints(usepoint, block.timestamp, "NO_DETAIL"));
    }

    function usePoint(address donor, uint256 usepoint, string memory detail) external {
        require(
            _totalDonations[donor] - _usedPoints[donor] >= usepoint,
            "not enough points"
        );
        _lastUseId++;
        _useDonors.push(donor);
        _usePoints.push(usepoint);
        _useDates.push(block.timestamp);
        _usedPoints[donor] += usepoint;
        _allUsedPoints += usepoint;
        _usePointsHistory[donor].push(UsePoints(usepoint, block.timestamp, detail));
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

    // New function to get donation history for a specific sender
    function getDonationHistory(address sender) external view returns (Donation[] memory) {
        return _donationHistory[sender];
    }
    // New function to get donation history for a specific sender
    function getsubstituteDonationHistory(address sender) external view returns (SubstituteDonation[] memory) {
        return _substituteDonationHistory[sender];
    }
}
