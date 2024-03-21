// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * This is the AGEN token contract. The token is ERC20Upgradeable with cap of 21MIL AGEN Tokens.
 */
interface IAGEN is IERC20Upgradeable, IERC165Upgradeable {
    /**
     * The function to get the cap of the token.
     * @return The cap of the token.
     */
    function cap() external view returns (uint256);

    /**
     * The function to mint tokens.
     * @param account_ The address of the account to mint tokens to.
     * @param amount_ The amount of tokens to mint.
     */
    function mint(address account_, uint256 amount_) external;
}
