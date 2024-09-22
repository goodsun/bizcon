// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.0;
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../manage/manage.sol";

contract enumerableSBT is ERC721Enumerable {
    address private _manageAddress;
    manage private _manageContract;
    string private _customName;
    string private _customSymbol;
    bool public _creatorOnly;
    address public _creator;
    uint256 public _lastTokenId;
    address public _owner;
    bool public _minterDelete;
    mapping(uint256 => string) private _metaUrl;
    mapping(uint256 => bool) private _lockedTokens;
    mapping(uint256 => address) private _minter;

    /*
     * name NFT名称
     * symbol 単位
     */
    constructor(
        address manageAddress,
        string memory _name,
        string memory _symbol,
        address creator
    ) ERC721(_name, _symbol) {
        _customName = _name;
        _customSymbol = _symbol;
        _manageAddress = manageAddress;
        _manageContract = manage(_manageAddress);
        _minterDelete = false;
        _owner = msg.sender;
        _creator = creator;
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

    function setConfig(address owner, address creator, bool creatorOnly, bool minterDelete) external {
        require(_owner == msg.sender || checkAdmin(), "Can't set. owner only");
        _owner = owner;
        _creator = creator;
        _creatorOnly = creatorOnly;
        _minterDelete = minterDelete;
    }

    function name() public view override returns (string memory) {
        return _customName;
    }

    function symbol() public view override returns (string memory) {
        return _customSymbol;
    }

    function checkAdmin() public view returns (bool) {
        return _manageContract.chkAdmin(msg.sender);
    }

    function setName(string memory newName,string memory newSymbol  ) external {
        require(_owner == msg.sender || checkAdmin(), "Can't set. owner only");
        _customName = newName;
        _customSymbol = newSymbol;
    }

    function getInfo() external view returns (address, uint256, bool) {
        return (_creator, _lastTokenId, _creatorOnly);
    }

    function burn(uint256 tokenId) external {
        require(_owner == msg.sender || checkAdmin() || (_minter[tokenId] == msg.sender && _minterDelete) , "Can't burn. minter only");
        _metaUrl[tokenId] = "";
        _lockedTokens[tokenId] = false;
        _burn(tokenId);
    }

   function burnable(uint256 tokenId) external view returns (bool) {
        require(_owner == msg.sender || checkAdmin() || (_minter[tokenId] == msg.sender && _minterDelete) , "Can't burn. minter only");
        if(_minter[tokenId] == 0x0000000000000000000000000000000000000000){
          return false;
        }
        return true;
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
