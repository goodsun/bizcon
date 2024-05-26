// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC5192} from "./ERC5192/ERC5192.sol";

contract basicSBT is ERC5192 {
    bool public _creatorOnly;
    address public _creator;
    bool private isLocked;
    address private _owner;
    uint256 public _lastTokenId;
    mapping(uint256 => string) private _metaUrl;

    constructor(
        string memory _name,
        string memory _symbol,
        address creator,
        bool _isLocked
    ) ERC5192(_name, _symbol, _isLocked) {
        _owner = msg.sender;
        _creator = creator;
        isLocked = _isLocked;
    }

    function mint(address to, string memory metaUrl) external {
        require(
            (!_creatorOnly || msg.sender == _creator || msg.sender == _owner),
            "this NFT is can mint creator only"
        );
        _lastTokenId++;
        uint256 tokenId = _lastTokenId;
        _metaUrl[tokenId] = metaUrl;
        _mint(to, tokenId);
        if (isLocked) emit Locked(tokenId);
    }

    function safeMint(address to, string memory metaUrl) external {
        _lastTokenId++;
        uint256 tokenId = _lastTokenId;
        _metaUrl[tokenId] = metaUrl;
        _safeMint(to, tokenId);
        if (isLocked) emit Locked(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(_metaUrl[tokenId]));
    }

    function setConfig(address creator, bool creatorOnly) external {
        require(_owner == msg.sender, "Can't set. owner only");
        _creator = creator;
        _creatorOnly = creatorOnly;
    }

    function getInfo() external view returns (address, uint256, bool) {
        return (_creator, _lastTokenId, _creatorOnly);
    }

    function burn(uint256 tokenId) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Caller is not owner nor approved"
        );
        _metaUrl[tokenId] = "";
        _burn(tokenId);
    }
}
