// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

//* This contract is used to grant withdraw permission to a user

//* This pkg make sure all transactions revert if they are not supposed to succeed
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/access/AccessControlEnumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract Vault is Ownable, AccessControlEnumerable {
    //* The token that this vault will hold
    IERC20 private _token;
    //* The maximum amount that can be withdrawn at once
    uint256 public maxWithdrawalAmount;
    //* Whether withdrawals are enabled
    bool public withrawalEnabled;
    //* The role that is allowed to withdraw
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAWER_ROLE");

    constructor() {
        //* Set the owner as the default admin
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setWithdrawalEnabled(bool _enabled) public onlyOwner {
        withrawalEnabled = _enabled;
    }

    function setToken(IERC20 _newToken) public onlyOwner {
        _token = _newToken;
    }

    function setMaxWithdrawalAmount(
        uint256 _newMaxWithdrawalAmount
    ) public onlyOwner {
        maxWithdrawalAmount = _newMaxWithdrawalAmount;
    }

    function withdraw(
        uint256 _amount,
        address _recipient
    ) external onlyWithdrawer {
        require(withrawalEnabled, "Vault: Withdrawals are disabled");
        require(
            _amount <= maxWithdrawalAmount,
            "Vault: Amount exceeds max withdrawal amount"
        );
        SafeERC20.safeTransfer(_token, _recipient, _amount);
    }

    modifier onlyWithdrawer() {
        //* Only the owner or a user with the withdraw role can withdraw
        require(
            owner() == _msgSender() || hasRole(WITHDRAW_ROLE, _msgSender()),
            "Vault: Caller is not a withdrawer"
        );
        _;
    }

    function deposit(uint256 _amount) external {
        SafeERC20.safeTransferFrom(
            _token,
            _msgSender(),
            address(this),
            _amount
        );
    }
}
