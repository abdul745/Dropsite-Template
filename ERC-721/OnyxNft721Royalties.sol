// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC2981PerTokenRoyalties.sol";
contract Onyx721Royalties{
    // uint public OnyxFees;
    event RoyaltiesTransfer (uint OnyxFee, uint minterFee, uint nftSellerAmount) ;
    struct RoyaltyInfo {
        address payable recipient;
        uint24 amount;
    }
    mapping(uint256 => RoyaltyInfo) internal _royalties;

    // mapping (address=>bool) OnyxWhiteList;

    mapping (address=>uint) _deposits;

    function _getBidBalance(address payable payee, uint bidAmount) internal{
        require(msg.value >= bidAmount, "Insufficient balance");
        _deposits[payee] += bidAmount;  
    }
    function checkBalance(address Address) public view returns(uint ){
        return _deposits[Address];
    }
    function _withdrawBalance( uint amount ) internal {
        //  Check Owner
        //  Check is on Bidding
        //  require(msg.sender == _deposits);
        require (amount != 0 && amount <= _deposits[msg.sender], "Error! Amount is zero or Low Balance");
        _deposits[msg.sender]-= amount; 
        payable(msg.sender).transfer(amount);
    }
    function _deductBiddingAmount(uint _bidAmount, address highestBidderAddress) internal {
        require(_deposits[highestBidderAddress] >= _bidAmount, "Error! Insifficent Balance");
        _deposits[highestBidderAddress]-= _bidAmount;
    }

    function _setTokenRoyalty(uint256 tokenId,address payable recipient,uint256 value) internal {
        require(value <= 10000, "ERC2981Royalties: Too high");
        _royalties[tokenId] = RoyaltyInfo(recipient, uint24(value));
    }
    
    
    /* this Function will be Called only in transfer function so its internal
    ** While Transfering a token Royalties will be deducted
    ** 1) Get Balance in Contract   2)Deduct Onyx percentage 3) Deduct Amount for 1st Minter   
    */
    function _royaltyAndOnyxFee (uint _NftPrice, uint percentage, address payable minterAddress, address payable NftSeller) internal {
        uint _TotalNftPrice = _NftPrice;
        uint _OnyxFee = _deductOnyxFee(_NftPrice);
        uint _minterFee = _SendMinterFee(_NftPrice , percentage,  minterAddress);
        //Remaining Price After Deduction  
        _TotalNftPrice = _TotalNftPrice - _OnyxFee - _minterFee;
        // Send Amount to NFT Seller after Tax deduction
        _transferAmountToSeller( _TotalNftPrice, NftSeller);
        emit RoyaltiesTransfer (_OnyxFee, _minterFee, _TotalNftPrice);
    }
    
    function _deductOnyxFee(uint Price) internal pure returns(uint) {
        require((Price/10000)*10000 == Price, "Error! Too small");
        return Price*25/1000;
    }

    function _transferAmountToSeller(uint amount, address payable seller) internal {
        seller.transfer(amount);
    }
    
       // Deduct Minter Fee
    function _SendMinterFee(uint _NftPrice, uint Percentage, address payable recepient)  internal returns(uint) {
        //Calculate Minter percentage and Send to his Address from Struct
        uint AmountToSend = _NftPrice*Percentage/100;
        // Send this Amount To Transfer Address from Contract balacne 
        recepient.transfer(AmountToSend);
        return AmountToSend;
    }   

}