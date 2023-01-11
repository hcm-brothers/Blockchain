// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/utils/Context.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/access/AccessControlEnumerable.sol";

interface IHeroNFT {
    function mint(address to, uint256 heroType) external returns (uint256);
}

contract HeroNFT is
    ERC721Enumerable,
    Ownable,
    AccessControlEnumerable,
    IHeroNFT
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    //* base URI for token metadata
    string private _baseTokenURI;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event HeroMinted(address to, uint256 heroType, uint256 tokenId);

    constructor() ERC721("Stickman Hero", "Hero") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mint(
        address to,
        uint256 heroType
    ) public override onlyMinter returns (uint256) {
        _tokenIdTracker.increment();
        uint256 newTokenId = _tokenIdTracker.current();
        _safeMint(to, newTokenId);
        emit HeroMinted(to, heroType, newTokenId);
        return newTokenId;
    }

    modifier onlyMinter() {
        require(
            owner() == _msgSender() || hasRole(MINTER_ROLE, _msgSender()),
            "HeroNFT: Caller is not a minter"
        );
        _;
    }

    function listTokenIds(
        address owner
    ) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
