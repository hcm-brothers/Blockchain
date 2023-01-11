// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

contract HeroMarketPlace is IERC721Receiver, Ownable {
    using SafeERC20 for IERC20;
    IERC721Enumerable private nft;
    IERC20 private token;

    uint256 private tax = 10; //* 10%
    mapping(uint256 => NFTDetail) public listDetail;

    struct NFTDetail {
        address payable author;
        uint256 price;
        uint256 tokenId;
    }

    event ListNFT(address _from, uint256 _tokenId, uint256 _price);
    event UnListNFT(address _from, uint256 _tokenId);
    event BuyNFT(address _from, uint256 _tokenId, uint256 _price);
    event UpdateListingNFTPirce(uint256 _tokenId, uint256 _price);
    event SetToken(IERC20 _token);
    event SetTax(uint256 _tax);
    event SetNFT(IERC721Enumerable _nft);

    constructor(IERC20 _token, IERC721Enumerable _nft) {
        //* Which token this marketplace accepts
        token = _token;
        //* Which NFT this marketplace will handle
        nft = _nft;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function setTax(uint256 _tax) public onlyOwner {
        tax = _tax;
        emit SetTax(_tax);
    }

    function setToken(IERC20 _token) public onlyOwner {
        token = _token;
        emit SetToken(_token);
    }

    function setNFT(IERC721Enumerable _nft) public onlyOwner {
        nft = _nft;
        emit SetNFT(_nft);
    }

    function getListedNft() public view returns (NFTDetail[] memory) {
        uint balance = nft.balanceOf(address(this));
        NFTDetail[] memory listedNfts = new NFTDetail[](balance);

        for (uint i = 0; i < balance; i++) {
            listedNfts[i] = listDetail[
                nft.tokenOfOwnerByIndex(address(this), i)
            ];
        }
        return listedNfts;
    }

    //* this function use to list NFT on to marketplace
    function listNft(uint256 _tokenId, uint256 _price) public {
        require(
            nft.ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this NFT"
        );
        require(
            listDetail[_tokenId].author == address(0),
            "This NFT is already listed"
        );
        require(
            nft.getApproved(_tokenId) == address(this),
            "Marketplace is not approved to transfer this NFT"
        );

        nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        listDetail[_tokenId] = NFTDetail(payable(msg.sender), _price, _tokenId);
        emit ListNFT(msg.sender, _tokenId, _price);
    }

    function unlistNft(uint256 _tokenId) public {
        require(
            listDetail[_tokenId].author == msg.sender,
            "Only author can unlist this NFT"
        );
        require(
            nft.ownerOf(_tokenId) == address(this),
            "This NFT is not listed on marketplace"
        );

        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete listDetail[_tokenId];
        emit UnListNFT(msg.sender, _tokenId);
    }

    function updateListingNftPrice(uint256 _tokenId, uint256 _price) public {
        require(
            listDetail[_tokenId].author == msg.sender,
            "Only author can update price of this NFT"
        );
        require(
            nft.ownerOf(_tokenId) == address(this),
            "This NFT is not listed on marketplace"
        );

        listDetail[_tokenId].price = _price;
        emit UpdateListingNFTPirce(_tokenId, _price);
    }

    function buyNft(uint256 _tokenId, uint256 _price) public {
        require(
            token.balanceOf(msg.sender) >= _price,
            "Insufficient account balance"
        );
        require(
            nft.ownerOf(_tokenId) == address(this),
            "This NFT is not listed on marketplace"
        );
        require(listDetail[_tokenId].price <= _price, "Minimum price not met");

        //* transfer token from buyer to marketplace
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), _price);

        //* transfer token from marketplace to author
        token.transfer(
            listDetail[_tokenId].author,
            (_price * (100 - tax)) / 100
        );

        //* transfer NFT from marketplace to buyer
        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        delete listDetail[_tokenId];
        emit BuyNFT(msg.sender, _tokenId, _price);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(uint256 _amount) public onlyOwner {
        require(
            token.balanceOf(address(this)) >= _amount,
            "Insufficient token balance"
        );
        token.transfer(msg.sender, _amount);
    }

    function withdrawErc20() public onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}
