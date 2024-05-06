// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAGEN} from "./interfaces/IAGEN.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20CappedUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {ERC20VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract AGEN is
    Initializable,
    IAGEN,
    ERC20Upgradeable,
    ERC20VotesUpgradeable,
    ERC20PermitUpgradeable,
    ERC20CappedUpgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    // 1 is seen as false & 2 seen as true
    uint public enableTransfers = 2;
    event Log(string message, uint256 value);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function initialize(address initialOwner, address[] memory coSigners) public initializer {
        __ERC20_init("Test Based Tokens", "TBT");
        __ERC20Burnable_init();
        __Ownable_init(initialOwner);
        __ERC20Permit_init("TBT");
        __ERC20Votes_init();
        __UUPSUpgradeable_init();

        uint256 capAmount = 21000000 * 10 ** decimals();
        __ERC20Capped_init(capAmount);

        uint256 totalMintAmount = 1000000 * 10 ** decimals();
        uint256 numRecipients = coSigners.length + 1;

        require(totalMintAmount <= capAmount, "Total mint amount exceeds cap");
        require(numRecipients > 0, "No recipients provided");
        uint256 mintAmount = totalMintAmount / numRecipients;
        emit Log("Minted to all three wallets", mintAmount);
        //enableTransfers = 1;

        _mint(initialOwner, mintAmount);

        for (uint256 i = 0; i < coSigners.length; i++) {
            _mint(coSigners[i], mintAmount);
        }
    }

    function cap() public view override(ERC20CappedUpgradeable, IAGEN) returns (uint256) {
        return ERC20CappedUpgradeable.cap();
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IAGEN).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IVotes).interfaceId;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable, ERC20CappedUpgradeable) {
        if (enableTransfers == 1) {
            revert("Transfers are currently disabled");
        }
        super._update(from, to, value);
    }

    function setEnableTransfers(uint enabled) external onlyOwner {
        enableTransfers = enabled;
    }

    function nonces(address owner) public view override(ERC20PermitUpgradeable, NoncesUpgradeable) returns (uint256) {
        return super.nonces(owner);
    }
}
