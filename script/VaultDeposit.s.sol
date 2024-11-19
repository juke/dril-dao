// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseScript} from "./Base.s.sol";
import {SmolVault} from "../src/SmolVault.sol";
import {SmolGov} from "../src/SmolGov.sol";
import "forge-std/console.sol";

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract VaultDeposit is BaseScript {
    function run() external broadcaster {
        SmolVault vault = SmolVault(0x39356f78560b0DCFE6Bd816ac68a285C2a567bb5);
        SmolGov token = vault.governanceToken();

        console.log("Deployer address:", deployer);
        console.log("Vault address:", address(vault));
        console.log("Token address:", address(token));

        uint256 depositAmount = 5;
        console.log("Attempting to deposit:", depositAmount);

        uint256 initialVaultBalance = token.balanceOf(deployer);
        uint256 initialTokenBalance = token.balanceOf(deployer);
        console.log("Initial vault shares balance:", initialVaultBalance);
        console.log("Initial user token balance:", initialTokenBalance);

        IERC1155(0x1e38AFBb2628943ABbDCDAb7151Fa84990930F4C).setApprovalForAll(
            address(vault),
            true
        );

        try vault.deposit(1, depositAmount) {
            console.log("Deposit successful");
            uint256 newTokenBalance = token.balanceOf(deployer);
            console.log("New user token balance:", newTokenBalance);
            // Delegate votes to self
            token.delegate(deployer);
            console.log("Votes delegated to self");
        } catch Error(string memory reason) {
            console.log("Deposit failed. Reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Deposit failed. Low-level error:");
            console.logBytes(lowLevelData);
        }

        uint256 vaultTotalSupply = token.totalSupply();
        console.log("Vault total supply:", vaultTotalSupply);
        address tokenOwner = token.owner();
        console.log("Token owner:", tokenOwner);
        console.log("Is vault the token owner?", tokenOwner == address(vault));

        // Check voting power
        uint256 votingPower = token.getVotes(deployer);
        console.log("Deployer voting power:", votingPower);
    }
}
