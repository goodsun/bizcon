// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract manage {
    address private _owner;
    address[] private _admins;
    address[] private _creators;
    address[] private _contracts;
    mapping(address => string) private _names;
    mapping(address => string) private _types;
    mapping(address => bool) private _public;

    constructor() {
        _owner = msg.sender;
        _admins.push(msg.sender);
    }

    function checkUser() external view returns (string memory) {
        for (uint i = 0; i < _admins.length; i++) {
            if (_admins[i] == msg.sender) {
                return "admin";
            }
        }
        for (uint i = 0; i < _creators.length; i++) {
            if (_creators[i] == msg.sender) {
                return "creator";
            }
        }
        return "user";
    }

    function chkAdmin() internal view returns (bool) {
        bool val = false;
        for (uint i = 0; i < _admins.length; i++) {
            if (_admins[i] == msg.sender) {
                val = true;
            }
        }
        return val;
    }

    function chkExist(address account) internal view returns (bool) {
        bool val = false;
        for (uint i = 0; i < _contracts.length; i++) {
            if (_contracts[i] == account) {
                val = true;
            }
        }
        return val;
    }

    function chkCreatorExist(address account) internal view returns (bool) {
        bool val = false;
        for (uint i = 0; i < _creators.length; i++) {
            if (_creators[i] == account) {
                val = true;
            }
        }
        return val;
    }

    function isEOA(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size == 0;
    }

    function setAdmin(address account) external {
        require(chkAdmin(), "You can't set admin.");
        for (uint i = 0; i < _admins.length; i++) {
            if (_admins[i] == account) {
                require(false, "it's exist");
            }
        }
        _admins.push(account);
    }

    function delAdmin(address account) external {
        require(account != msg.sender, "Can't delete yourself.");
        require(chkAdmin(), "You can't delete admin.");
        for (uint i = 0; i < _admins.length; i++) {
            if (_admins[i] == account) {
                _admins[i] = _admins[_admins.length - 1];
                _admins.pop();
                return;
            }
        }
    }

    function getAdmins() public view returns (address[] memory, uint256) {
        return (_admins, _admins.length);
    }

    function setCreator(
        address account,
        string memory name,
        string memory typename
    ) external {
        require(chkAdmin(), "You can't set creator.");
        for (uint i = 0; i < _creators.length; i++) {
            if (_creators[i] == account) {
                require(false, "it's exist");
            }
        }
        _creators.push(account);
        _names[account] = name;
        _types[account] = typename;
        _public[account] = true;
    }

    function setCreatorInfo(
        address account,
        string memory name,
        string memory typename
    ) external {
        require(chkAdmin(), "You can't set contract.");
        require(chkCreatorExist(account), "it's not exist.");
        _names[account] = name;
        _types[account] = typename;
    }

    function publicCreator(address account) external {
        require(chkAdmin(), "You can't set contract.");
        require(!_public[account], "it's already public");
        require(chkCreatorExist(account), "it's not exist.");
        _public[account] = true;
    }

    function hiddenCreator(address account) external {
        require(chkAdmin(), "You can't set contract.");
        require(_public[account], "it's already hidden");
        require(chkCreatorExist(account), "it's not exist.");
        _public[account] = false;
    }

    function delCreator(address account) external {
        require(chkAdmin(), "You can't delete creator.");
        require(chkCreatorExist(account), "It's not exist.");
        for (uint256 i = 0; i < _creators.length; i++) {
            if (_creators[i] == account) {
                delete _names[_creators[i]];
                delete _types[_creators[i]];
                delete _public[_creators[i]];
                _creators[i] = _creators[_creators.length - 1];
                _creators.pop();
                break;
            }
        }
    }

    function getAllCreators()
        public
        view
        returns (
            address[] memory,
            string[] memory,
            string[] memory,
            bool[] memory
        )
    {
        uint256 length = _creators.length;
        address[] memory addresses = new address[](length);
        string[] memory names = new string[](length);
        string[] memory types = new string[](length);
        bool[] memory publicStatus = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            addresses[i] = _creators[i];
            names[i] = _names[_creators[i]];
            types[i] = _types[_creators[i]];
            publicStatus[i] = _public[_creators[i]];
        }

        return (addresses, names, types, publicStatus);
    }

    function setContract(
        address account,
        string memory name,
        string memory typename
    ) external {
        require(chkAdmin(), "You can't set contract.");
        require(!isEOA(account), "Can't set EOA.");
        for (uint i = 0; i < _contracts.length; i++) {
            if (_contracts[i] == account) {
                require(false, "it's exist");
            }
        }
        _contracts.push(account);
        _names[account] = name;
        _types[account] = typename;
        _public[account] = true;
    }

    function setContractInfo(
        address account,
        string memory name,
        string memory typename
    ) external {
        require(chkAdmin(), "You can't set contract.");
        require(chkExist(account), "it's not exist.");
        _names[account] = name;
        _types[account] = typename;
    }

    function publicContract(address account) external {
        require(chkAdmin(), "You can't set contract.");
        require(!_public[account], "it's already public");
        require(chkExist(account), "it's not exist.");
        _public[account] = true;
    }

    function hiddenContract(address account) external {
        require(chkAdmin(), "You can't set contract.");
        require(_public[account], "it's already hidden");
        require(chkExist(account), "it's not exist.");
        _public[account] = false;
    }

    function getContract(
        address account
    ) external view returns (address, string memory, string memory, bool) {
        return (account, _names[account], _types[account], _public[account]);
    }

    function getAllContracts()
        public
        view
        returns (
            address[] memory,
            string[] memory,
            string[] memory,
            bool[] memory
        )
    {
        uint256 length = _contracts.length;
        address[] memory addresses = new address[](length);
        string[] memory names = new string[](length);
        string[] memory types = new string[](length);
        bool[] memory publicStatus = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            addresses[i] = _contracts[i];
            names[i] = _names[_contracts[i]];
            types[i] = _types[_contracts[i]];
            publicStatus[i] = _public[_contracts[i]];
        }

        return (addresses, names, types, publicStatus);
    }

    function deleteContract(address account) external {
        require(chkAdmin(), "You can't delete contract.");
        require(chkExist(account), "It's not exist.");
        for (uint256 i = 0; i < _contracts.length; i++) {
            if (_contracts[i] == account) {
                delete _names[_contracts[i]];
                delete _types[_contracts[i]];
                delete _public[_contracts[i]];
                _contracts[i] = _contracts[_contracts.length - 1];
                _contracts.pop();
                break;
            }
        }
    }
}
