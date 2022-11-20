// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable, Ownable {
    /**
     * @dev _baseTokenURI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    string _baseURLForNFT;

    // Whitelist contract instance
    IWhitelist _whiteList;

    // max number of CryptoDevs
    uint256 public maxTokenIds = 20;

    // total number of tokenIds minted
    uint256 public tokenIds;

    // boolean to keep track of whether presale started or not
    bool public presaleStarted;

    // timestamp for when presale would end
    uint256 public presaleEnded;

    //  _price is the price of one Crypto Dev NFT
    uint256 public price = 0.01 ether;

    // _paused is used to pause the contract in case of an emergency
    bool public paused;

    modifier OnlyWhenNotPause() {
        require(!paused, "Minting has been set to pause");
        _;
    }

    /**
     * @dev ERC721 constructor takes in a `name` and a `symbol` to the token collection.
     * Constructor for Crypto Devs takes in the baseURI to set _baseTokenURI for the collection.
     * It also initializes an instance of whitelist interface.
     */
    constructor(
        string memory _baseURIForNFT,
        address _whiteListContract,
        string memory _NFTTokenName,
        string memory _NFTTokeSymbol
    ) ERC721(_NFTTokenName, _NFTTokeSymbol) {
        _baseURLForNFT = _baseURIForNFT;
        _whiteList = IWhitelist(_whiteListContract);
    }

    /**
     * @dev startPresale starts a presale for the whitelisted addresses
     */
    function startPresale() public onlyOwner {
        presaleStarted = true;
        presaleEnded = block.timestamp + 5 minutes;
    }

    function setPause(bool _paused) public onlyOwner {
        paused = _paused;
    }

    /**
     * @dev presaleMint allows a user to mint one NFT per transaction during the presale.
     */
    function presaleMint() public payable OnlyWhenNotPause {
        require(presaleStarted, "Presale is not started yet.");
        require(presaleEnded >= block.timestamp, "Presale is over.");
        require(
            _whiteList.whitelistedAddresses(msg.sender),
            "You are not whiltelist address."
        );
        require(tokenIds < maxTokenIds, "All NFT is minted already.");
        require(
            msg.value >= price,
            "You don't have enough ether to mint this collection."
        );
        tokenIds++;
        //_safeMint is a safer version of the _mint function as it ensures that
        // if the address being minted to is a contract, then it knows how to deal with ERC721 tokens
        // If the address being minted to is not a contract, it works the same way as _mint
        _safeMint(msg.sender, tokenIds);
    }

    /**
     * @dev mint allows a user to mint 1 NFT per transaction after the presale has ended.
     */
    function mint() public payable OnlyWhenNotPause {
        require(
            presaleEnded <= block.timestamp,
            "Public mint is not started yet."
        );
        require(
            _whiteList.whitelistedAddresses(msg.sender),
            "You are not whiltelist address."
        );
        require(tokenIds < maxTokenIds, "All NFT is minted already.");
        require(
            msg.value >= price,
            "You don't have enough ether to mint this collection."
        );
        tokenIds++;
        _safeMint(msg.sender, tokenIds);
    }

    /**
     * @dev withdraw sends all the ether in the contract
     * to the owner of the contract
     */
    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev _baseURI overides the Openzeppelin's ERC721 implementation which by default
     * returned an empty string for the baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURLForNFT;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
