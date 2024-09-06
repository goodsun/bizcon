// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.0;
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./RoyaltyStandard.sol";

contract enumerableNFT is ERC721Enumerable, RoyaltyStandard {
    bool public _creatorOnly;
    address public _creator;
    uint256 public _lastTokenId;
    address public _owner;
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
        _owner = msg.sender;
        _creator = creator;
        _feeRate = feeRate;
        _creatorOnly = true;
    }

    /*
     * to 転送先
     * metaUrl メタ情報URL
     */
    function mint(address to, string memory metaUrl) public {
        require(
            (!_creatorOnly || msg.sender == _creator || msg.sender == _owner),
            "Only the creator can mint this NFT"
        );
        _lastTokenId++;
        uint256 tokenId = _lastTokenId;
        _metaUrl[tokenId] = metaUrl;
        _mint(to, tokenId);
        _setTokenRoyalty(tokenId, _creator, _feeRate * 100); // 100 = 1%
    }

    /*
     * ERC721 0x80ac58cd
     * ERC165 0x01ffc9a7 (RoyaltyStandard)
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Enumerable, RoyaltyStandard)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return _metaUrl[tokenId];
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
