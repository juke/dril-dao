// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @dev Implementation of ERC1155 with configurable metadata that's compatible with OpenSea
 * Metadata JSON Schema:
 * {
 *   "name": "Token Name",
 *   "description": "Token Description",
 *   "image": "ipfs://or-https://...",
 *   "external_url": "https://...",
 *   "attributes": [
 *     { "trait_type": "Property", "value": "Value" }
 *   ]
 * }
 */
contract Dril1155 is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;

    struct TokenURIConfig {
        string tokenURI; // Complete URI (overrides all other settings if set)
        string baseURI; // Base path to JSON files
        bool useTokenIdInPath; // Whether to append tokenId to path
        bool isConfigured; // Whether this token has been configured
    }

    // Mapping token ID to its URI configuration
    mapping(uint256 => TokenURIConfig) private _tokenURIConfigs;

    // Contract-level metadata URI (required by OpenSea)
    string private _contractURI;

    // Default base URI for unconfigured tokens
    string private _defaultBaseURI;

    // Max batch size to prevent out-of-gas errors
    uint256 public constant MAX_BATCH_SIZE = 500;

    constructor(
        string memory initialBaseURI,
        string memory contractURI_
    ) ERC1155(initialBaseURI) Ownable(msg.sender) {
        _defaultBaseURI = initialBaseURI;
        _contractURI = contractURI_;
    }

    /**
     * @dev Returns the URI for contract-level metadata.
     * Required by OpenSea for collection metadata.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string calldata newURI) external onlyOwner {
        _contractURI = newURI;
    }

    /**
     * @dev Sets the token-specific URI configuration
     * @param tokenId The token ID to configure
     * @param baseURI Base URI where JSON metadata files are hosted
     * @param useTokenIdInPath Whether to append tokenId to the path
     */
    function setTokenURIConfig(
        uint256 tokenId,
        string calldata baseURI,
        bool useTokenIdInPath
    ) external onlyOwner {
        require(bytes(baseURI).length > 0, "Base URI cannot be empty");

        TokenURIConfig storage config = _tokenURIConfigs[tokenId];
        config.baseURI = baseURI;
        config.useTokenIdInPath = useTokenIdInPath;
        config.isConfigured = true;

        emit TokenURIConfigUpdated(tokenId, baseURI, useTokenIdInPath);
    }

    /**
     * @dev Sets a complete URI for a token, bypassing the configuration
     * @param tokenId The token ID
     * @param newURI Complete URI pointing to the JSON metadata
     */
    function setTokenURI(
        uint256 tokenId,
        string calldata newURI
    ) external onlyOwner {
        require(bytes(newURI).length > 0, "URI cannot be empty");
        _tokenURIConfigs[tokenId].tokenURI = newURI;
        emit TokenURIUpdated(tokenId, newURI);
    }

    /**
     * @dev Removes the override URI for a token
     */
    function clearTokenURI(uint256 tokenId) external onlyOwner {
        delete _tokenURIConfigs[tokenId].tokenURI;
        emit TokenURIUpdated(tokenId, "");
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     * Returns the URI for token metadata. Must return JSON matching OpenSea schema.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        TokenURIConfig storage config = _tokenURIConfigs[tokenId];

        // Return specific URI if set
        if (bytes(config.tokenURI).length > 0) {
            return config.tokenURI;
        }

        // Use token config or default
        string memory baseURI = config.isConfigured
            ? config.baseURI
            : _defaultBaseURI;

        // Ensure baseURI ends with "/" if we're appending tokenId
        if (config.useTokenIdInPath && !_endsWithSlash(baseURI)) {
            baseURI = string.concat(baseURI, "/");
        }

        // Return either baseURI or baseURI/tokenId
        return
            config.useTokenIdInPath
                ? string.concat(baseURI, tokenId.toString())
                : baseURI;
    }

    // Helper to check if string ends with "/"
    function _endsWithSlash(string memory str) private pure returns (bool) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length == 0) return false;
        return strBytes[strBytes.length - 1] == 0x2f; // "/"
    }

    // Minting functions
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external onlyOwner {
        _mint(to, id, amount, data);
    }

    function mintManyTokens(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyOwner {
        require(ids.length <= MAX_BATCH_SIZE, "Batch too large");
        require(ids.length == amounts.length, "Length mismatch");
        _mintBatch(to, ids, amounts, data);
    }

    function mintToMany(
        address[] calldata toAddresses,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external onlyOwner nonReentrant {
        require(toAddresses.length <= MAX_BATCH_SIZE, "Batch too large");
        for (uint256 i = 0; i < toAddresses.length; i++) {
            _mint(toAddresses[i], id, amount, data);
        }
    }

    // Events
    event TokenURIConfigUpdated(
        uint256 indexed tokenId,
        string baseURI,
        bool useTokenIdInPath
    );
    event TokenURIUpdated(uint256 indexed tokenId, string newURI);
}
