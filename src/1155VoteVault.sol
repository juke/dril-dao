// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {GovToken} from "./GovToken.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract VoteVault1155 is ERC1155Holder, ReentrancyGuard {
    IERC1155 public immutable nftContract;
    GovToken public immutable governanceToken;
    uint8 public immutable tokenDecimals;

    constructor(address _nftContract, address _governanceToken) {
        nftContract = IERC1155(_nftContract);
        governanceToken = GovToken(_governanceToken);
        tokenDecimals = governanceToken.decimals();
    }

    function deposit(uint256 tokenId, uint256 amount) external nonReentrant {
        nftContract.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            amount,
            ""
        );
        governanceToken.mint(msg.sender, amount * (10 ** tokenDecimals));
    }

    function withdraw(uint256 tokenId, uint256 amount) external nonReentrant {
        governanceToken.burnFrom(msg.sender, amount * (10 ** tokenDecimals));
        nftContract.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            ""
        );
    }
}
