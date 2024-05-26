// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.0;
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC721/ERC721.sol";
import "./RoyaltyStandard.sol";

contract freeNFT is ERC721, RoyaltyStandard {
    bool public _creatorOnly;
    uint256 public _lastTokenId;
    address public _creator;
    address private _owner;
    string private _name;
    uint256 private _feeRate;
    mapping(uint256 => string) private _metaUrl;

    /*
     * name NFT名称
     * symbol 単位
     */
    constructor(
        string memory name,
        string memory symbol,
        address creator,
        uint256 feeRate
    ) ERC721(name, symbol) {
        _name = name;
        _owner = msg.sender;
        _creator = creator;
        _feeRate = feeRate;
        _name = name;
    }

    /*
     * to 転送先
     * metaUrl メタ情報URL
     */
    function mint(address to, string memory metaUrl) public {
        require(
            (_creatorOnly  && (msg.sender != _creator || msg.sender != _owner)),
            "this NFT is can mint creator only"
        );
        _lastTokenId++;
        uint256 tokenId = _lastTokenId;
        _metaUrl[tokenId] = metaUrl;
        _mint(to, tokenId);
        _setTokenRoyalty(tokenId, _creator, _feeRate * 100); //100 = 1%
    }

    /*
     * ERC721 0x80ac58cd
     * ERC165 0x01ffc9a7 (RoyaltyStandard)
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, RoyaltyStandard) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(_metaUrl[tokenId]));
    }

    function setConfig(
        address creator,
        uint256 feeRate,
        bool creatorOnly
    ) external {
        require(_owner == msg.sender, "Can't set. owner only");
        _creator = creator;
        _feeRate = feeRate;
        _creatorOnly = creatorOnly;
    }

    function getInfo() external view returns (string memory, uint256) {
        return ("free", _lastTokenId);
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
