// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// binance/polygon/ 
// On Deployment use Specific values for Enums as Like (0,1,2,3)
// Lock Bidder Value

contract OnyxNft721Auction {  //is OnyxERC20 
    event availableForBids(uint, string) ;
    event removeFormSale (uint, string );
    enum status {NotOnSale ,onAuction, onBidding, OnfixedPrice }
    mapping (address => uint) BidsAmount;
    mapping (address => uint ) BiddingInfo; 

    status public CurrentStatus;
    struct NftDetails{
        uint [] bidAmount;
        address[] bidderAddress;
        // bool IsonSale;
        uint startingPrice;
        uint startTime;
        uint endTime;
        // Using minimum Bid for Fixed Price of NFt and minimum bid in auction and Bididing 
        uint minimumPrice;
        uint index;
        status salestatus;
    }
    modifier notOnSale (uint nftId) {
        require(Nft[nftId].salestatus == status.NotOnSale, "Error! Nft is Already on Sale");
        _;
    }
    modifier onBidding(uint nftId){
        require(Nft[nftId].salestatus == status.onBidding, "Error! NFT is Not Available for Biding");
        _;
    }
    modifier onSale (uint nftId) {
        require(Nft[nftId].salestatus == status.onAuction ||  Nft[nftId].salestatus == status.onBidding || Nft[nftId].salestatus == status.OnfixedPrice, "Error! Nft is Not on Sale");
        // require(Nft[nftId].IsonSale == true, "NFT is Not on Sale");
        _;
    
    }
    modifier onAuction(uint nftId){
        require(Nft[nftId].salestatus == status.onAuction, "Nft is Not Available for Auction");
        _;
    }
    modifier onFixedPrice (uint nftId){
        require(Nft[nftId].salestatus == status.OnfixedPrice, "NFT is Not Available for Fixed Price");
        _;
    }
    mapping(uint=>NftDetails) Nft;
    //Biding for Local NFT will be local

    //Place NFT to Accept Bids
    function _placeNftForBids(uint NftId ) notOnSale(NftId) internal {
        CurrentStatus = status(2);
        // NftDetails storage NftDetailobj = Nft[NftId];   I think it will create Storage Obj automatically,  Nft[NftId].salestatus  
        Nft[NftId].salestatus = CurrentStatus;
        emit availableForBids (NftId, "Accepting Bids");
    }

    //  Done 
    function _addOpenBid(uint nftId, uint _bidAmount) onBidding(nftId) internal  {
        _pushBidingValues(msg.sender, nftId, _bidAmount);
        _updateBiddingMapping(msg.sender, _bidAmount);
        // if (Nft[nftId].bidAmount[Nft[nftId].index] <= _bidAmount ){
        //     Nft[nftId].index= Nft[nftId].bidAmount.length;  // Add Index of that Number
        //     // return Nft[nftId].index;
        // }
        // return Nft[nftId].index;
    }

    function _putNftForTimedAuction(uint nftId, uint startTime, uint endTime, uint minAmount) notOnSale(nftId) internal{
        // start time should be near to Block.timestamp
        require (startTime != endTime && block.timestamp < endTime , "Error! Time Error");
        CurrentStatus = status(1);
        Nft[nftId].salestatus = CurrentStatus;
        Nft[nftId].startTime = startTime;
        Nft[nftId].endTime = endTime;
        Nft[nftId].minimumPrice = minAmount;
        emit availableForBids (nftId, " Accepting Bids");
    }

    //it is Time Based Auction
    function _addAuctionBid(uint nftId, uint _bidAmount) onAuction(nftId) internal{
        // Check is time remaining to Bid
        require(block.timestamp <= Nft[nftId].endTime, "Time is Overed");
        _pushBidingValues(msg.sender, nftId, _bidAmount);
        _updateBiddingMapping(msg.sender, _bidAmount);
    }

    // function putOnSale(uint NftId) internal {
    //     require(Nft[NftId].IsonSale == false, "Not On Sale");
    //     Nft[NftId].IsonSale = true;
    // }
    function _pushBidingValues (address _address, uint nftId, uint _bidAmount) internal{
        Nft[nftId].bidAmount.push(_bidAmount);
        Nft[nftId].bidderAddress.push(_address);
    }
    function _putNftForFixedPrice(uint nftId, uint Fixedamount ) notOnSale(nftId) internal{
        CurrentStatus = status(3);
        Nft[nftId].salestatus = CurrentStatus;
        Nft[nftId].minimumPrice = Fixedamount;
    }
    // Pending Indexing
    function GetHighestIndexvalue(uint nftId) external view returns(uint , address ){
        return (Nft[nftId].bidAmount[Nft[nftId].index], Nft[nftId].bidderAddress[Nft[nftId].index]);
    }
    function _removeFromSale(uint nftId) onSale(nftId) internal { 
        CurrentStatus = status(0);
        Nft[nftId].salestatus = CurrentStatus;
        emit removeFormSale(nftId , "Error! NFT is removed from Sale ");
    }
    function CheckNftStatus(uint nftId) view external returns(status){
        return Nft[nftId].salestatus;
    }
    // For Testing
    function _getIndexOfHighestBid(uint nftId) internal {
        uint temp = 0;
        for (uint i=0; i<Nft[nftId].bidAmount.length; i++){
            if (temp<Nft[nftId].bidAmount[i])
            {
                temp = Nft[nftId].bidAmount[i];
                Nft[nftId].index = i;
            }
        }
    }
    // For testing 
    function GetHighestValueofArray(uint nftId) external returns(uint){
        _getIndexOfHighestBid(nftId);
        return Nft[nftId].bidAmount[Nft[nftId].index];
    }
    function _updateBiddingMapping(address _address , uint _biddingAmount) internal {
        BidsAmount[_address] += _biddingAmount;
    }
    function _extendAuctionTime (uint _nftId, uint _endTime) onAuction(_nftId) internal{
        require(_endTime > Nft[_nftId].endTime && Nft[_nftId].endTime < block.timestamp , "Time Reset Error!");
        Nft[_nftId].endTime = _endTime;
    }
    function _releaseBiddingValue(uint nftId) internal {
        for (uint i=0; i<Nft[nftId].bidderAddress.length; i++){
            BidsAmount[Nft[nftId].bidderAddress[i]] -= Nft[nftId].bidAmount[i];
        }
    }
}