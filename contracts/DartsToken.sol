// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "hardhat/console.sol";

contract Darts is ERC20("Darts", "DARTS"), Ownable, ERC20Burnable {
    uint private cap = 1000000000000000000000000; //* 1 million

    constructor() {
        //* mint 1 million DARTS to owner
        //* OpenZeppelin contracts automatically update totalSupply when you mint or burn tokens
        _mint(msg.sender, cap);
        //* transfer ownership to owner
        //* the owner in this case is the account that deployed the contract
        transferOwnership(msg.sender);
    }

    //* mint amount of DARTS to an address, only owner can call this function
    function mint(address to, uint256 amount) public onlyOwner {
        //* check if the total supply of DARTS is less than the cap
        require(
            ERC20.totalSupply() + amount <= cap,
            "ERC20Capped: cap exceeded"
        );
        _mint(to, amount);
    }
}
