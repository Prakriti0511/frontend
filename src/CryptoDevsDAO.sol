// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace{
    function getPrice() external view returns (uint256);

    function available(uint256 _tokenId) external view returns (bool);

    function purchase(uint256 _tokenId) external payable;
}
interface ICryptoDevsNFT{
    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

//Ownable - set the contract deployer as the owner of this contract 
contract CryptoDevsDAO is Ownable{
    struct Proposal{
    uint256 nftTokenId;
    uint256 deadline;
    uint256 yayVotes;
    uint256 nayVotes;
    bool executed;
    //mapping to check whether this NFT has been executed to cast vote yet or not.
    mapping(uint256 => bool) voters;
    }
    //mapping of numproposal to proposal
    mapping(uint256 => Proposal) public proposals;
    //number of proposal that have been created
    uint256 public numProposals;
    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;
    constructor(address _nftMarketplace, address _cryptoDevsNFT) Ownable(msg.sender) payable{
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }
    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }
    // @return Returns the proposal index for the newly created proposal
    function createProposal(uint256 _nftTokenId) external nftHolderOnly returns (uint256){
        require(nftMarketplace.available(_nftTokenId),"NFT_NOT_FOR_SALE");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;
        //current time + 5 mins
        numProposals++;
        return numProposals - 1;
    }
    modifier activeProposalOnly(uint256 proposalIndex){
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE EXCEEDED"
        );
        _;
    }
    enum Vote {
        YAY,
        NAY
    }

    function voteOnProposal(uint256 proposalIndex, Vote vote) external nftHolderOnly activeProposalOnly(proposalIndex){
        Proposal storage proposal = proposals[proposalIndex];
        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;
        // Calculate how many NFTs are owned by the voter
        // that haven't already been used for voting on this proposal
        for(uint256 i = 0; i < voterNFTBalance; i++){
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if(proposal.voters[tokenId] ==false){
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY VOTED");
        if(vote==Vote.YAY) {
            proposal.yayVotes += numVotes;
        }
        else{
            proposal.nayVotes += numVotes;
        }
    }
        function executeProposal(uint256 proposalIndex) external nftHolderOnly
    inactiveProposalOnly(proposalIndex)
    {
    Proposal storage proposal = proposals[proposalIndex];

    // If the proposal has more YAY votes than NAY votes
    // purchase the NFT from the FakeNFTMarketplace
    if (proposal.yayVotes > proposal.nayVotes) {
        uint256 nftPrice = nftMarketplace.getPrice();
        require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
        nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
    }
    proposal.executed = true;
    }
    function withdrawEther() external onlyOwner{
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw, contract balance empty");
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "FAILED_TO_WITHDRAW_ETHER");
    }
    receive() external payable{}
    fallback() external payable{}
}