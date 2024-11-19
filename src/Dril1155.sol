// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Dril1155 is ERC1155, Ownable {
    uint256 public constant GOV_TOKEN_ID = 1;
    uint256 public constant OTHER_TOKEN_ID = 2;

    constructor() ERC1155("") Ownable(msg.sender) {}

    function mint(address to, uint256 id, uint256 amount) external onlyOwner {
        _mint(to, id, amount, "");
    }
}
