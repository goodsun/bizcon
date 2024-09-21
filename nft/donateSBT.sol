// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../donate/donateManage.sol";

contract donateSBT is ERC721Enumerable {
    string private _customName;
    string private _customSymbol;
    address public _owner;
    uint256 public _lastTokenId;
    uint256 public _usePoint;
    bool public _minterDelete;
    mapping(uint256 => string) private _metaUrl;
    address payable private _donateManageAddress;
    donateManage private _donateManageContract;
    mapping(uint256 => bool) private _lockedTokens;
    mapping(uint256 => address) private _minter;

    constructor(
        address payable donateManageAddress,
        string memory _name,
        string memory _symbol,
        bool minterDelete
    ) ERC721(_name, _symbol) {
        _customName = _name;
        _customSymbol = _symbol;
        _minterDelete = minterDelete;
        _owner = msg.sender;
        _donateManageAddress = donateManageAddress;
        _donateManageContract = donateManage(_donateManageAddress);
        _usePoint = 2 ether;
    }

    function mint(address to, string memory metaUrl) external {
        uint256 usepoint = _usePoint;
        uint256 availablePoints = _donateManageContract.latestPoint(msg.sender);
        require(
            availablePoints >= usepoint,
            "You do not have enough points to mint"
        );

        // Update usedPoints
        _donateManageContract.usePoint(msg.sender, usepoint);

        _lastTokenId++;
        uint256 tokenId = _lastTokenId;
        _metaUrl[tokenId] = metaUrl;
        _minter[tokenId] = msg.sender;
        _mint(to, tokenId);
        _lockedTokens[tokenId] = true;
    }

    function minter(
        uint256 tokenId
    ) external view returns (address) {
        _requireMinted(tokenId);
        return _minter[tokenId];
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(_metaUrl[tokenId]));
    }

    function getInfo() external view returns (address, uint256, bool) {
        return (_owner, _lastTokenId, false);
    }

    function setConfig(uint256 usePoint) external {
        require(_owner == msg.sender, "Can't set. owner only");
        _usePoint = usePoint;
    }

    function name() public view override returns (string memory) {
        return _customName;
    }

    function symbol() public view override returns (string memory) {
        return _customSymbol;
    }

    function setName(string memory newName,string memory newSymbol  ) external {
        require(_owner == msg.sender, "Can't set. owner only");
        _customName = newName;
        _customSymbol = newSymbol;
    }

    function burn(uint256 tokenId) external {
        require(_owner == msg.sender || (_minter[tokenId] == msg.sender || _minterDelete) , "Can't burn. owner only");
        _metaUrl[tokenId] = "";
        _lockedTokens[tokenId] = false;
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!_lockedTokens[tokenId], "Token transfer is locked");
    }
}
