// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../donate/donateManage.sol";

contract donateSBT is ERC721Enumerable {
    address private _owner;
    uint256 public _lastTokenId;
    uint256 public _usePoint;
    mapping(uint256 => string) private _metaUrl;
    address private _donateManageAddress;
    donateManage private _donateManageContract;
    mapping(uint256 => bool) private _lockedTokens;

    constructor(address donateManageAddress, string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        _owner = msg.sender;
        _donateManageAddress = donateManageAddress;
        _donateManageContract = donateManage(_donateManageAddress);
        _usePoint = 2 ether;
    }

    function mint(address to, string memory metaUrl) external {
        uint256 usepoint = _usePoint;
        uint256 availablePoints = _donateManageContract.latestPoint(msg.sender);
        require(availablePoints >= usepoint, "You do not have enough points to mint");

        // Update usedPoints
        _donateManageContract.usePoint(msg.sender, usepoint);

        _lastTokenId++;
        uint256 tokenId = _lastTokenId;
        _metaUrl[tokenId] = metaUrl;
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(_metaUrl[tokenId]));
    }

    function getInfo() external view returns (string memory, uint256) {
        return ("free", _lastTokenId);
    }

    function setConfig(uint256 usePoint) external {
        require(_owner == msg.sender, "Can't set. owner only");
        _usePoint = usePoint;
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _metaUrl[tokenId] = "";
        _burn(tokenId);
    }

    function lockTransfer(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _lockedTokens[tokenId] = true;
    }

    function unlockTransfer(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _lockedTokens[tokenId] = false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!_lockedTokens[tokenId], "Token transfer is locked");
    }
}
