// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "hardhat/console.sol";

//* USDT mockup contract
contract Usdt is ERC20("Usdt", "USDT"), Ownable, ERC20Burnable {
    uint private cap = 1000000000000000000000000;

    constructor() {
        _mint(msg.sender, cap);
        transferOwnership(msg.sender);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(
            ERC20.totalSupply() + amount <= cap,
            "ERC20Capped: cap exceeded"
        );
        _mint(to, amount);
    }
}
