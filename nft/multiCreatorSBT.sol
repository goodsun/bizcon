// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.0;
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract multiCreatorSBT is ERC721Enumerable {
    bool public _creatorOnly;
    uint256 public _lastTokenId;
    uint256 public _lastCreator;
    address public _owner;
    mapping(uint256 => address) public _creators;
    mapping(uint256 => string) private _metaUrl;
    mapping(uint256 => bool) private _lockedTokens;

    /*
     * name NFT名称
     * symbol 単位
     */
    constructor(
        string memory name,
        string memory symbol,
        address creator
    ) ERC721(name, symbol) {
        _owner = msg.sender;
        _lastCreator = 1;
        _creators[1] = creator;
        _creatorOnly = true;
    }

    function _creator() external view returns (address) {
        if (_isInCreators(msg.sender)) {
            return msg.sender;
        } else {
            return _owner;
        }
    }

    function _isInCreators(address account) internal view returns (bool) {
        for (uint256 i = 1; i <= _lastCreator; i++) {
            if (_creators[i] == account) {
                return true;
            }
        }
        return false;
    }

    /*
     * to 転送先
     * metaUrl メタ情報URL
     */
    function mint(address to, string memory metaUrl) public {
        require(
            (!_creatorOnly || _isInCreators(msg.sender) || msg.sender == _owner),
            "Only the creator can mint this SBT"
        );
        _lastTokenId++;
        uint256 tokenId = _lastTokenId;
        _metaUrl[tokenId] = metaUrl;
        _mint(to, tokenId);
    }

    /*
     * ERC721 0x80ac58cd
     * ERC165 0x01ffc9a7 (RoyaltyStandard)
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return _metaUrl[tokenId];
    }

    function setCreator(address creator) external {
        require(_owner == msg.sender, "Can't set. owner only");
        _lastCreator ++;
        _creators[_lastCreator] = creator;
    }

    function delCreator(uint256 creatorId) external {
        require(_owner == msg.sender, "Can't set. owner only");
        _creators[creatorId] = 0x000000000000000000000000000000000000dEaD;
    }

    function getInfo() external view returns (address, uint256, bool) {
        if (_isInCreators(msg.sender)) {
            return (msg.sender, _lastTokenId, true);
        } else {
            return (_owner, _lastTokenId, true);
        }
    }

    function burn(uint256 tokenId) external {
        require(_owner == msg.sender, "Can't set. owner only");
        _metaUrl[tokenId] = "";
        _burn(tokenId);
    }

    function lockTransfer(uint256 tokenId) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Caller is not owner nor approved"
        );
        _lockedTokens[tokenId] = true;
    }

    function unlockTransfer(uint256 tokenId) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Caller is not owner nor approved"
        );
        _lockedTokens[tokenId] = false;
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
