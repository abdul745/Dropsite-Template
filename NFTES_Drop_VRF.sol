// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";


contract VRFv2Consumer is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed

;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 100000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 1;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  1;

  uint256[] public s_randomWords;
  uint256 public s_requestId;

  constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_subscriptionId = subscriptionId;
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() internal {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }
  
}


contract NFTES_Drop is ERC1155, Ownable, VRFv2Consumer(395) {
    using SafeMath for uint;
     //NFT category
    // NFT Description & URL
    bytes data = "";
    uint256 totalNFTsMinted; //Total NFTs
    uint256 numOfCopies; //A user can mint only 1 NFT
    uint256 mintFees;

    //Initial Minting
    uint256 Diamond;
    uint256 Gold;
    uint256 Silver;

    uint maxMintLimit = 333;
    //Max mint Slots
    uint256 maxDiamondCount=33;
    uint256 maxGoldCount=100;
    uint256 maxSilverCount=200;

    uint256 maxMints=0;
    event isMinted(address indexed addr, string[]  ids);
    //owner-NFT-ID Mapping
    //Won NFTs w.r.t Addresses
    struct nft_Owner {
        uint256[] owned_Dropsite_NFTs;
    }

    mapping(address => nft_Owner) dropsite_NFT_Owner;
    
    
    //payments Mapping  
    mapping(address => uint256) deposits;
   

    //Pausing and activating the contract
    modifier contractIsNotPaused() {
        require(isPaused == false, "Dropsite is not Opened Yet.");
        _;
    }
    modifier mintingFeeIsSet() {
        require(mintFees != 0, "Owner Should set mint Fee First");
        _;
    }

    modifier maxMintingIsSet() {
        require(maxMints != 0, "Owner Should set Max Mints First");
        _;
    }

    bool public isPaused = true;

    mapping (uint=>string) tokenURI;
    event URI(string value, bytes indexed id);

    constructor()  ERC1155(""){

        totalNFTsMinted = 0; //Total NFTs Minted
        numOfCopies = 1; //A user can mint only 1 NFT in one call
        
        //Initially 0 NFTs have been minted
        Diamond = 0;
        Gold = 0;
        Silver = 0;
    }

    function name() public pure returns(string memory){
    return "NFT-ES Drop";
   }

    function symbol() public pure returns(string memory){
        return "NED";
    }
  
   
    function setURI(uint _id, string memory _uri) private  {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id)  override public view returns (string memory) {
    return tokenURI[_id];
  }

   

    //Check NFTs issued to an address
    function returnNftsOwner(address addr)
        public
        view
        returns (uint256[] memory)
    {
        return dropsite_NFT_Owner[addr].owned_Dropsite_NFTs;
    }

    //To Check No of issued NFTs Category Wise
    function checkMintedCategoryWise()
        public
        view
        onlyOwner
        returns (
            uint,
            uint,
            uint
        )
    {
        return (Diamond, Gold, Silver);
    }


    function setStatusMintFeeAndMaxMints(bool mintStatus, uint _mintFee, uint _maxMints) public onlyOwner {
        mintFees = _mintFee;
        require(_maxMints<=5,"Max Mint Set limit is 5");
        maxMints = _maxMints;
        if(isPaused!=mintStatus)
        isPaused = mintStatus;
    }

    function getStatusMintFeeAndMaxMints() public view onlyOwner  returns (bool,uint,uint){
        return (isPaused,mintFees,maxMints);
    }

    //To Check total Minted NFTs
    function checkTotalMinted() public view returns (uint256) {
        return totalNFTsMinted;
    }


    //To WithDraw input Ammount from Contract to Owners Address or any other Address
    function withDraw(address payable to, uint amount) public  onlyOwner {
        uint256 Balance = address(this).balance;
        require(amount <= Balance, "Error! Not Enough Balance");
        to.transfer(amount);
    }

    //To Check Contract Balance in Wei
    function contractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }


    //Random Number to Select an item from nums Array(Probabilities)
    //Will return an index b/w 0-10
    function random() internal returns (uint256) {
        
        requestRandomWords();

        return s_randomWords[0];
    }

  

   
    //To check and update conditions wrt nftId
    function updateConditions(uint256 index)
        internal
        contractIsNotPaused
        returns (uint256)
    {
        uint nftId;
        if((index).mod(10) == 1 && Diamond < maxDiamondCount){
            Diamond++;
            data = bytes(string(
                abi.encodePacked("Diamond_", Strings.toString(Diamond))
            ));
            return nftId=0;
            // if nftID is 0 and Diamond is more than 33, it will go there in Gold Category
        } else if ((index).mod(10) <= 4 && Gold < maxGoldCount) {
            Gold++;
            data = bytes(string(abi.encodePacked("Gold_", Strings.toString(Gold))));
            return nftId=1;
            // if any of the above conditions are filled it will mint silver if enough silver available
        } else if ((index).mod(10) > 4 && Silver < maxSilverCount) {
            Silver++;
            data = bytes(string(
                abi.encodePacked("Silver_", Strings.toString(Silver))
            ));
            return nftId=2;
        } else {

            //if nft ID is either 1 or 2, but Slots in Gold or Diamond are remaining,
            //First Gold category will be filled then Diamond
            if (Silver < maxSilverCount) {
                nftId = 1;
                Silver++;
                data = bytes(string(
                    abi.encodePacked("Silver_", Strings.toString(Gold))
                ));
                return nftId;
            }

            else if (Gold < maxGoldCount) {
                nftId = 1;
                Gold++;
                data = bytes(string(
                    abi.encodePacked("Gold_", Strings.toString(Gold))
                ));
                return nftId;
            }  else if (Diamond < maxDiamondCount){
                nftId = 0;
                Diamond++;
                data = bytes(string(
                    abi.encodePacked("Diamond_", Strings.toString(Diamond))
                ));
                return nftId;
            }
            else return 99;
        }
        
    }

    function randomMinting(address user_addr)
        internal
        contractIsNotPaused
        returns (uint256, bytes memory)
    {
        // nftId = random(); // we're assuming that random() returns only 0,1,2
        uint256 index = random();
        uint256 nftId = updateConditions(index);
        _mint(user_addr, nftId, numOfCopies, data);
        totalNFTsMinted++;
        dropsite_NFT_Owner[user_addr].owned_Dropsite_NFTs.push(nftId);
        if(bytes(tokenURI[nftId]).length==0)
        {
        if(nftId==0)
            setURI(nftId, "ipfs://QmNce9BpYehVxaYUnSmpXNf2p2vS1ehmV7J7DsACwWfcM3/DiamondMetadata.json");
        else if(nftId==1)
            setURI(nftId, "ipfs://QmNce9BpYehVxaYUnSmpXNf2p2vS1ehmV7J7DsACwWfcM3/GoldMetadata.json");
        else if(nftId==2)
            setURI(nftId, "ipfs://QmNce9BpYehVxaYUnSmpXNf2p2vS1ehmV7J7DsACwWfcM3/SilverMetadata.json");
        }
        return (nftId, data);
    }

    //Random minting after Fiat Payments
    function fiatRandomMint(address user_addr, uint256 noOfMints)
        public
        onlyOwner
        contractIsNotPaused
        mintingFeeIsSet
        maxMintingIsSet
        returns (string[] memory)
    {
        require(noOfMints <= maxMints && noOfMints>0, "You cannot mint more than max mint limit");
        require((totalNFTsMinted+noOfMints) <= maxMintLimit, "Max Minting Limit reached");
        uint returnedNftID;
        bytes memory returnedNftData;
        string[] memory randomMintedNfts = new string[](noOfMints);
        for (uint256 i = 0; i <= noOfMints-1; i++) {
            (returnedNftID, returnedNftData) = randomMinting(user_addr);
              randomMintedNfts[i]= 
                    string(abi.encodePacked(Strings.toString(returnedNftID),"_", returnedNftData));
        }
        
        emit isMinted(user_addr, randomMintedNfts);
        return randomMintedNfts;
    }

    //MATIC Amount will be deposited
    function depositAmount(address payee, uint256 amountToDeposit) internal {
        deposits[payee] += amountToDeposit;
    }

    //Random minting after Crypto Payments
    function cryptoRandomMint(address user_addr, uint256 noOfMints)
        public
        payable
        contractIsNotPaused
        mintingFeeIsSet
        maxMintingIsSet
        returns (string[] memory)
    {
        require(noOfMints <= maxMints && noOfMints>0, "You cannot mint more than max mint limit");
        require((totalNFTsMinted+noOfMints) <= maxMintLimit, "Max Minting Limit reached");
        require(msg.value == mintFees.mul(noOfMints), "Not Enough Balance");
        uint returnedNftID;
        bytes memory returnedNftData;
        string[] memory randomMintedNfts = new string[](noOfMints);
        for (uint256 i = 0; i <= noOfMints-1; i++) {
          (returnedNftID, returnedNftData) = randomMinting(user_addr);
              randomMintedNfts[i]= 
                    string(abi.encodePacked(Strings.toString(returnedNftID),"_", returnedNftData));
        }
        depositAmount(_msgSender(), msg.value);
        emit isMinted(user_addr, randomMintedNfts);
        return randomMintedNfts;
    }

}
