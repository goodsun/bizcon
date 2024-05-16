// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./RoyaltyStandard.sol";
import "../donate/donateManage.sol";

contract donateNFT is ERC721Enumerable, RoyaltyStandard {
    uint256 public _lastTokenId;
    address public _creator;
    address private _owner;
    string private _name;
    uint256 public _usePoint;
    mapping(uint256 => string) private _metaUrl;
    address private _donateManageAddress;
    donateManage private _donateManageContract;

    /*
    * name NFT名称
    * symbol 単位
    */
    constructor(address donateManageAddress, string memory name, string memory symbol) ERC721(name, symbol) {
        _name = name;
		_owner = msg.sender;
        _name = name;
        _donateManageAddress = donateManageAddress;
        _donateManageContract = donateManage(_donateManageAddress);
        _usePoint = 5 ether;
    }

    /*
    * to 転送先
    * metaUrl メタ情報URL
    */
    function mint(address to, string memory metaUrl, uint256 feeRate)
    public {
        uint256 usepoint = _usePoint;
        uint256 availablePoints = _donateManageContract.latestPoint(msg.sender);
        require(availablePoints >= usepoint, "You do not have enough points to mint");

        // Update usedPoints
        _donateManageContract.usePoint(msg.sender, usepoint);

        _lastTokenId ++;
        uint256 tokenId = _lastTokenId;
        _metaUrl[tokenId] = metaUrl;
        _mint(to, tokenId);
        _setTokenRoyalty(tokenId, msg.sender, feeRate * 100);
    }

    /*
    * ERC721 0x80ac58cd
    * ERC165 0x01ffc9a7 (RoyaltyStandard)
    */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, RoyaltyStandard)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(_metaUrl[tokenId]));
    }

    function setConfig(uint256 usePoint) external {
        require(_owner == msg.sender ,"Can't set. owner only");
        _usePoint = usePoint;
    }

    function getInfo() external view returns (string memory, uint256) {
		return ("free", _lastTokenId);
	}

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _metaUrl[tokenId] = "";
        _burn(tokenId);
    }
}
