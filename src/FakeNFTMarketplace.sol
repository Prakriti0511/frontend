// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract FakeNFTMarketplace{
    // mapping the tokenid to belong to the owners address
    mapping(uint256 => address) public tokens;
    //fixing all NFT Prices to 0.01 eth
    uint8 NFTPrice = 0.1 ether;

    constructor(){
        _tokenId = tokenId;
    }
    function purchase(uint256 _tokenId) external payable{
        require(msg.value == nftPrice, "Value doesn't match the token price");
        tokens[tokenid] = msg.sender;
    }
    function getPrice(uint256 _tokenId) external view returns(uint8){
        return NFTPrice;
    }
    function available(uint256 _tokenId) external view returns(bool){
        if(tokens[_tokenId] == address(0)){
            return true;
        }
        return false;
    }
    

}