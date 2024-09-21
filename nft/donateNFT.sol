// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./RoyaltyStandard.sol";
import "../donate/donateManage.sol";

contract donateNFT is ERC721Enumerable, RoyaltyStandard {
    string private _customName;
    string private _customSymbol;
    uint256 public _lastTokenId;
    address public _owner;
    uint256 public _usePoint;
    uint256 public _feeRate;
    mapping(uint256 => string) private _metaUrl;
    address payable public _donateManageAddress;
    donateManage private _donateManageContract;

    /*
    * name NFT名称
    * symbol 単位
    */
    constructor(
        address payable donateManageAddress,
        string memory _name,
        string memory _symbol,
        uint256 feeRate
    ) ERC721(_name, _symbol) {
        _customName = _name;
        _customSymbol = _symbol;
		_owner = msg.sender;
        _feeRate = feeRate;
        _donateManageAddress = donateManageAddress;
        _donateManageContract = donateManage(_donateManageAddress);
        _usePoint = 5 ether;
    }

    /*
    * to 転送先
    * metaUrl メタ情報URL
    */
    function mint(address to, string memory metaUrl) public {
        uint256 usepoint = _usePoint;
        uint256 availablePoints = _donateManageContract.latestPoint(msg.sender);
        require(availablePoints >= usepoint, "You do not have enough points to mint");

        // Update usedPoints
        _donateManageContract.usePoint(msg.sender, usepoint);

        _lastTokenId ++;
        uint256 tokenId = _lastTokenId;
        _metaUrl[tokenId] = metaUrl;
        _mint(to, tokenId);
        _setTokenRoyalty(tokenId, msg.sender, _feeRate * 100);
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

    function setConfig(address owner, uint256 usePoint) external {
        require(_owner == msg.sender ,"Can't set. owner only");
        _owner = owner;
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

    function getInfo() external view returns (address, uint256, bool) {
        return (_owner, _lastTokenId, false);
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId) , "Can't burn. owner only");
        _metaUrl[tokenId] = "";
        _burn(tokenId);
    }

    function burnable(uint256 tokenId) external view returns (bool) {
        require(_isApprovedOrOwner(_msgSender(), tokenId) , "Can't burn. owner only");
        return true;
    }
}
