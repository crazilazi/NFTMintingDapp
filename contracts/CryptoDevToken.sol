// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ICryptoDevs.sol";

contract CryptoDevToken is ERC20, Ownable {
    // Each NFT would give the user 10 tokens
    // It needs to be represented as 10 * (10 ** 18) as ERC20 tokens are represented by the smallest denomination possible for the token
    // By default, ERC20 tokens have the smallest denomination of 10^(-18). This means, having a balance of (1)
    // is actually equal to (10 ^ -18) tokens.
    // Owning 1 full token is equivalent to owning (10^18) tokens when you account for the decimal places.
    // More information on this can be found in the Freshman Track Cryptocurrency tutorial.
    uint256 public constant tokensPerNFT = 10 * 10 ** 18;

    // the max total supply is 10000 for Crypto Dev Tokens
    uint256 public constant maxTotalSupply = 10000 * 10 ** 18;

    // CryptoDevsNFT contract instance
    ICryptoDevs cryptoDevsNFTContract;

    // Price of one Crypto Dev token
    uint256 public constant tokenPrice = 0.001 ether;

    // Mapping to keep track of which tokenIds have been claimed
    mapping(uint256 => bool) public tokenIdsClaimed;

    constructor(
        address cryptoDevsNFTContract_,
        string memory tokenName_,
        string memory tokenSymol_
    ) ERC20(tokenName_, tokenSymol_) {
        cryptoDevsNFTContract = ICryptoDevs(cryptoDevsNFTContract_);
    }

    function claim() public {
        address sender = msg.sender;
        uint256 noOfNFTs = cryptoDevsNFTContract.balanceOf(sender);
        // If the balance is zero, revert the transaction
        require(noOfNFTs > 0, "You dont own any Crypto Dev NFT's");
        uint256 tottalNoOfTokenTobeMinted = 0;
        for (uint i = 0; i < noOfNFTs; i++) {
            if (!tokenIdsClaimed[i]) {
                tottalNoOfTokenTobeMinted++;
                tokenIdsClaimed[i] = true;
            }
        }
        // If all the token Ids have been claimed, revert the transaction;
        require(
            tottalNoOfTokenTobeMinted > 0,
            "You have already claimed all the tokens"
        );

        _mint(sender, tottalNoOfTokenTobeMinted * tokensPerNFT);
    }

    function mint(uint256 noOfToken_) public payable {
        require(noOfToken_ > 0, "You can not mint 0 token");
        uint256 requiredAmount_ = tokenPrice * noOfToken_;
        require(
            msg.value >= requiredAmount_,
            "The required amount of ether is not sent."
        );
        // total tokens + amount <= 10000, otherwise revert the transaction
        uint256 amountWithDecimals = noOfToken_ * 10 ** 18;
        require(
            (totalSupply() + amountWithDecimals) <= maxTotalSupply,
            "Exceeds the max total supply available."
        );
        // call the internal function from Openzeppelin's ERC20 contract
        _mint(msg.sender, amountWithDecimals);
    }

    function withdraw() public onlyOwner {
        address owner_ = owner();
        uint256 balanceOfContract = address(this).balance;
        (bool sent, ) = owner_.call{value: balanceOfContract}("");
        require(sent, "Failed to send Ether");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
