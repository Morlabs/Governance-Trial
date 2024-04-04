// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20CappedUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {ERC20VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract StETHMock is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    OwnableUpgradeable,
    ERC20CappedUpgradeable,
    ERC20BurnableUpgradeable,
    UUPSUpgradeable
{
    uint256 public totalShares;
    uint256 public totalPooledEther;

    mapping(address => uint256) private shares;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // constructor() ERC20Upgradeable("Staked Ether Mock", "stETHMock") {
    //     _mintShares(address(this), 10 ** decimals());

    //     totalPooledEther = 10 ** decimals();
    // }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable, ERC20CappedUpgradeable) {
        super._update(from, to, value);
    }

    function mint(address _account, uint256 _amount) external {
        require(_amount <= 1000 * (10 ** decimals()), "StETHMock: amount is too big");

        uint256 sharesAmount = getSharesByPooledEth(_amount);

        _mintShares(_account, sharesAmount);

        totalPooledEther += _amount;
    }

    function setTotalPooledEther(uint256 _totalPooledEther) external onlyOwner {
        totalPooledEther = _totalPooledEther;
    }

    function nonces(address owner) public view override(ERC20PermitUpgradeable, NoncesUpgradeable) returns (uint256) {
        return super.nonces(owner);
    }

    function totalSupply() public view override returns (uint256) {
        return totalPooledEther;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return getPooledEthByShares(_sharesOf(_account));
    }

    function sharesOf(address _account) external view returns (uint256) {
        return _sharesOf(_account);
    }

    function getSharesByPooledEth(uint256 _ethAmount) public view returns (uint256) {
        return (_ethAmount * totalShares) / totalPooledEther;
    }

    function getPooledEthByShares(uint256 _sharesAmount) public view returns (uint256) {
        return (_sharesAmount * totalPooledEther) / totalShares;
    }

    function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256) {
        _transferShares(msg.sender, _recipient, _sharesAmount);
        uint256 tokensAmount = getPooledEthByShares(_sharesAmount);
        return tokensAmount;
    }

    function transferSharesFrom(address _sender, address _recipient, uint256 _sharesAmount) external returns (uint256) {
        uint256 tokensAmount = getPooledEthByShares(_sharesAmount);
        _spendAllowance(_sender, msg.sender, tokensAmount);
        _transferShares(_sender, _recipient, _sharesAmount);
        return tokensAmount;
    }

    // function _transfer(address _sender, address _recipient, uint256 _amount) internal override {
    //     uint256 _sharesToTransfer = getSharesByPooledEth(_amount);
    //     _transferShares(_sender, _recipient, _sharesToTransfer);
    // }

    function _sharesOf(address _account) internal view returns (uint256) {
        return shares[_account];
    }

    function _transferShares(address _sender, address _recipient, uint256 _sharesAmount) internal {
        require(_sender != address(0), "TRANSFER_FROM_ZERO_ADDR");
        require(_recipient != address(0), "TRANSFER_TO_ZERO_ADDR");
        require(_recipient != address(this), "TRANSFER_TO_STETH_CONTRACT");

        uint256 currentSenderShares = shares[_sender];
        require(_sharesAmount <= currentSenderShares, "BALANCE_EXCEEDED");

        shares[_sender] = currentSenderShares - _sharesAmount;
        shares[_recipient] += _sharesAmount;
    }

    function _mintShares(address _recipient, uint256 _sharesAmount) internal returns (uint256 newTotalShares) {
        require(_recipient != address(0), "MINT_TO_ZERO_ADDR");

        totalShares += _sharesAmount;

        shares[_recipient] += _sharesAmount;

        return totalShares;
    }

    function initialize(address initialOwner) public initializer {
        __ERC20_init("Staked Ether Mock", "MSETH");
        __Ownable_init(initialOwner);
        __ERC20Permit_init("MSETH");
        __ERC20Votes_init();
        __UUPSUpgradeable_init();
        __ERC20Capped_init(100000 * 10 ** decimals());
        _mintShares(address(this), 3000 * 10 ** decimals());
        totalPooledEther = 10 ** decimals();
    }
}
