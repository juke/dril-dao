// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Script, console} from "forge-std/Script.sol";

abstract contract BaseScript is Script {
    string constant DEPLOYMENTS_PATH = "deployments.json";
    address internal deployer;
    uint256 internal deployerPrivateKey;

    constructor() {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);
    }

    modifier broadcaster() {
        console.log("address: ");
        console.log(deployer);
        vm.startBroadcast(deployerPrivateKey);
        _;
        vm.stopBroadcast();
    }

    function saveDeployment(string memory name, address deployed) internal {
        string memory json = vm.readFile(DEPLOYMENTS_PATH);
        // If file is empty, initialize with empty JSON object
        if (bytes(json).length == 0) {
            json = "{}";
        }

        // Parse existing JSON to keep other deployments
        bytes memory parsed = vm.parseJson(json);

        // Create temporary file path for writing
        string memory finalJson;
        if (parsed.length == 0) {
            // If parsing failed or empty, create new JSON
            finalJson = string.concat(
                "{",
                '"',
                name,
                '": "',
                vm.toString(deployed),
                '"',
                "}"
            );
        } else {
            // Update existing JSON while preserving other entries
            string memory temp = string.concat(
                '"',
                name,
                '": "',
                vm.toString(deployed),
                '"'
            );
            finalJson = _updateJson(json, temp);
        }

        // Write back to file
        vm.writeFile(DEPLOYMENTS_PATH, finalJson);
        console.log("Saved deployment %s: %s", name, deployed);
    }

    function getDeployment(string memory name) internal view returns (address) {
        string memory json = vm.readFile(DEPLOYMENTS_PATH);
        if (bytes(json).length == 0) return address(0);

        bytes memory parsed = vm.parseJson(json, string.concat(".", name));
        if (parsed.length == 0) return address(0);

        return abi.decode(parsed, (address));
    }

    // Helper to properly update JSON while preserving other fields
    function _updateJson(
        string memory existing,
        string memory newPair
    ) internal pure returns (string memory) {
        // Find last closing brace
        bytes memory existingBytes = bytes(existing);
        require(existingBytes.length > 0, "Invalid JSON");

        // Remove last }
        uint256 lastChar = existingBytes.length - 1;
        while (lastChar > 0 && existingBytes[lastChar] != "}") {
            lastChar--;
        }

        // Get everything except the last }
        string memory prefix = "";
        for (uint i = 0; i < lastChar; i++) {
            prefix = string.concat(
                prefix,
                string(abi.encodePacked(existingBytes[i]))
            );
        }

        // If the JSON had other items, add a comma
        if (bytes(prefix).length > 1) {
            // More than just a '{'
            return string.concat(prefix, ",", newPair, "}");
        }

        // Otherwise just add the new pair
        return string.concat("{", newPair, "}");
    }
}
