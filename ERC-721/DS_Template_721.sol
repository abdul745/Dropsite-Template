
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";


contract VRFv2Consumer is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Rinkeby coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

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
    uint32 numWords = 1;

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


contract DS721 is ERC721, Ownable, ERC721URIStorage {
using SafeMath for uint256;
using Address for address;
    //NFT category
    // NFT Description & URL
    string TokenURI = "";
    uint16 _totalNFTsMinted; //Total NFTs Minted
    uint8 public constant numOfCopies = 1; //A user can mint only 1 NFT in one go
    uint256 _mintFees; //Mint fee for single random minting

    uint16 _maxNFTs;
    uint8 _noOfCategories;
    uint8 _maxNFTsPerWallet;

    //Max mints in one go
    uint8 _maxMints = 0;
    event isMinted(address indexed addr, string[] ids);

    //Mint Start and end Time - UNIX Timestamp
    uint32 _mintStartTime;
    uint32 _mintEndTime;

    //Sum of weights for all NFTs for all categories: Must be 100;
    uint256 sumOfWeights=0;
    uint256[] rarityArray;
    //Struct Category for category details
    struct Category {
        string categoryName;
        uint256 categoryNftCount;
        //string categoryIpfsHash;
        uint16 categoryMintedCount;
    }

    //owner-NFT-ID Mapping
    //Won NFTs w.r.t Addresses
    struct nft_Owner {
        uint24[] owned_Dropsite_NFTs;
    }

    mapping(address => nft_Owner) dropsite_NFT_Owner;

    //ID-Category mapping
    mapping(uint16 => Category) CategoryDetails;

    //payments Mapping
    mapping(address => uint256) deposits;

    //categoryWise no of mints
    // mapping(uint256 => uint256) categoryMints;

    //Whitelisted Addresses mapping
    mapping(address => bool) whitelistedAddresses;

    //Total no of NFTs per wallet mapping
    mapping(address => uint8) NFTsPerWallet;

    //Pausing and activating the contract
    modifier contractIsNotPaused() {
        require(isPaused == false, "Dropsite is not Opened Yet.");
        _;
    }
    modifier mintingFeeIsSet() {
        require(_mintFees != 0, "Owner Should set mint Fee First");
        _;
    }

    modifier maxMintingIsSet() {
        require(_maxMints != 0, "Owner Should set Max Mints First");
        _;
    }

    modifier categoriesAreSet() {
        require(
            _noOfCategories != 0 && _maxNFTs != 0,
            "Please set Categories and Max NFTs first"
        );
        _;
    }
    bool public isPaused = true;

    mapping(uint256 => string) private _tokenURIs;
    event URI(string value, bytes indexed id);
    event CategoriesSet(Category, uint);

constructor (string memory name, string memory symbol) ERC721(name, symbol){
    _totalNFTsMinted = 0; //Total NFTs Minted
        //numOfCopies = 1; //A user can mint only 1 NFT in one call

        //Initially 0 Categories & max 0 NFTs can be minted in one go have been minted
        _noOfCategories = 0;
        _maxNFTs = 0;
}

     function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }   

    function tokenURI(uint256 tokenId) public view override virtual returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    //Check NFTs issued to an address
    function returnNftsOwner(address addr)
        external
        view
        returns (uint24[] memory)
    {
        return dropsite_NFT_Owner[addr].owned_Dropsite_NFTs;
    }

    function setMaxMints(uint8 maxMints)
        external
        onlyOwner
        contractIsNotPaused
    {
        require(maxMints <= 5, "Max Mint Set limit is 5");
        _maxMints = maxMints;
    }

    //maxNFTs is the total NFTs that can be minted in Dropsite
    //noOfCategories is the number of categories for which the total NFTs will be distributed
    function setCategoriesAndMaxNFTs(
        uint8 noOfCategories,
        uint16 maxNFTs,
        string[] memory categoryNames,
        uint256[] memory nftCounts
    ) external onlyOwner contractIsNotPaused {
        require((_noOfCategories == 0) && (_maxNFTs == 0), "Already Set");
        _noOfCategories = noOfCategories;
        _maxNFTs = maxNFTs;
        //Category memory category;
        //categoriesArray= new Category[] (_noOfCategories);
        rarityArray = new uint256[](_noOfCategories);
        for (uint8 i = 0; i < _noOfCategories; i++) {
            CategoryDetails[i].categoryName = categoryNames[i];
            CategoryDetails[i].categoryNftCount = nftCounts[i];
            CategoryDetails[i].categoryMintedCount = 0;
            rarityArray[i] = (nftCounts[i]*100*(10**18)/maxNFTs);
            sumOfWeights += rarityArray[i];

            emit CategoriesSet(CategoryDetails[i],sumOfWeights);
            //categoriesArray.push(category);
        }
    }

    //Function for testing
    function checkSumOfWeights() public view returns (uint){
        return sumOfWeights/(10**18);
    }
    function setMintFee(uint256 mintFee) external onlyOwner contractIsNotPaused {
        _mintFees = mintFee;
    }

    function setMintStatus(bool mintStatus) external onlyOwner {
        if (isPaused != mintStatus) isPaused = mintStatus;
    }

    function setMintTimer(uint32 startTime, uint32 endTime)
        external
        onlyOwner
        contractIsNotPaused
    {
        // start time should be near to Block.timestamp
        require(startTime != endTime, "Error! Start-End Time Error");
        require(block.timestamp <= endTime, "Error! Timestamp error");
        _mintStartTime = startTime;
        _mintEndTime = endTime;
    }

    function setMaxNFTsPerWallet(uint8 maxNFTsCount)
        external
        onlyOwner
        contractIsNotPaused
    {
        require(maxNFTsCount<=_maxMints, "Max NFTs per wallet should be less than or equal to max Mint Limit");
        _maxNFTsPerWallet = maxNFTsCount;
    }

    //returns start and end time
    function checkMintTimer() external view returns (uint256, uint256) {
        return (_mintStartTime, _mintEndTime);
    }

    //Function to check if the timer has been passed or not
    //true if time has been passed
    //4-5 Seconds gap has been noticed... SC updates the time first
    // Should make it internal after DEMO
    //Unused FUnction
    // function isAfterMintTime() public view returns (bool){
    //     if(block.timestamp >= _mintEndTime) return true;
    //     else return false;
    // }

    //function to set whitelisted addresses
    function addToWhitelist(address[] memory whitelistArr) external onlyOwner {
        for (uint256 i = 0; i < whitelistArr.length; i++) {
            require(
                whitelistedAddresses[whitelistArr[i]] == false,
                "Address has already been added to Whitelist"
            );
            whitelistedAddresses[whitelistArr[i]] = true;
        }
    }

    //function to remove from whitelist
    function removeFromWhitelist(address[] memory whitelistArr)
        external 
        onlyOwner
    {
        for (uint256 i = 0; i < whitelistArr.length; i++) {
            require(
                whitelistedAddresses[whitelistArr[i]] == true,
                "Please add Address to Whitelist First"
            );
            whitelistedAddresses[whitelistArr[i]] = false;
        }
    }

    //function to check weather an address is whitelisted or not
    function checkWhitelist(address addr) public view returns (bool) {
        return whitelistedAddresses[addr];
    }

    function getStatusMintFeeAndMaxMints()
        external
        view
        onlyOwner
        returns (
            bool,
            uint256,
            uint256
        )
    {
        return (isPaused, _mintFees, _maxMints);
    }

    //To Check total Minted NFTs
    function checkTotalMinted() external view returns (uint256) {
        return _totalNFTsMinted;
    }

    //To WithDraw input Ammount from Contract to Owners Address or any other Address
    function withDraw(address payable to, uint256 amount) external onlyOwner {
        uint256 Balance = address(this).balance;
        require(amount <= Balance, "Error! Not Enough Balance");
        to.transfer(amount);
    }

    //To Check Contract Balance in Wei
    function contractBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    //To Check No of issued NFTs Category Wise
    //Double check this function for gas fees
    //Pending Changes
    function checkMintedCategoryWise()
        external
        view
        onlyOwner
        returns ( uint256[] memory)
    {
        //string[] memory categoryNamesArr = new string[](_noOfCategories);
        uint256[] memory categoryCountsArr = new uint256[](_noOfCategories);
        string[] memory categoryNamesArr = new string[](_noOfCategories);
        for (uint16 i = 0; i < _noOfCategories; i++) {
            categoryCountsArr[i] = CategoryDetails[i].categoryMintedCount;
            categoryNamesArr[i] = CategoryDetails[i].categoryName;
        }
        return categoryCountsArr;
    }

    //Random Number to Select an item from nums Array(Probabilities)
    //Will return an index b/w 0-10
    function random() internal view returns (uint256) {
        //VRF-FUnctions
        // requestRandomWords();
        // return s_randomWords[0];

        // Returns 0-10
        //To Achieve maximum level of randomization!
        //using SafeMath add function

        uint256 randomnumber = uint256(
            keccak256(
                abi.encodePacked(
                    (
                        (block.timestamp)
                            .add(_totalNFTsMinted)
                            .add(CategoryDetails[2].categoryMintedCount)
                            .add(CategoryDetails[1].categoryMintedCount)
                            .add(CategoryDetails[0].categoryMintedCount)
                    ),
                    _msgSender()
                )
            )
        );
        return randomnumber;
    }

    //To check and update conditions wrt nftId
    function updateConditions(uint256 index) internal returns (uint24) {
        uint24 nftId;
        uint rnd = (index).mod(sumOfWeights);
        bool flag = false;
        for(uint16 i=0; i<_noOfCategories; i++) {
            if(flag) break;
             if(rnd < rarityArray[i]){
                flag = slotAvailable(i);
                    if(flag){
                        nftId = ((i+1)*100000)+CategoryDetails[i].categoryMintedCount;
                        TokenURI = string(abi.encodePacked(Strings.toString(i),"/",CategoryDetails[i].categoryName,Strings.toString(nftId)));
                        CategoryDetails[i].categoryMintedCount++;
                        break;
                    }
                    else{
                        //before 2nd last full slot
                    while(!flag && i < (_noOfCategories-1)){
                        i = i+1;
                        flag = slotAvailable(i);
                        if(flag){
                                nftId = ((i+1)*100000)+CategoryDetails[i].categoryMintedCount;
                                TokenURI = string(abi.encodePacked(Strings.toString(i),"/",CategoryDetails[i].categoryName,Strings.toString(nftId)));
                                CategoryDetails[i].categoryMintedCount++;
                                break;
                            }
                    }
                        //last full slot
                    while(!flag && i <= (_noOfCategories-1) && i>=0){
                        flag = slotAvailable(i);
                        if(flag){
                                nftId = ((i+1)*100000)+CategoryDetails[i].categoryMintedCount;
                                TokenURI = string(abi.encodePacked(Strings.toString(i),"/",CategoryDetails[i].categoryName,Strings.toString(nftId)));
                                CategoryDetails[i].categoryMintedCount++;
                                break;
                            }
                            i = i-1;
                    }

                }
             }
             else
                rnd -= rarityArray[i];
            }
            
            return nftId;
    }
    function slotAvailable(uint16 nftId) internal view returns (bool){
        if(CategoryDetails[nftId].categoryMintedCount<CategoryDetails[nftId].categoryNftCount)
            return true;
        else
            return false;
    }

    function randomMinting(address user_addr) internal returns (uint256, string memory) {
        // nftId = random(); // we're assuming that random() returns only 0,1,2
        // nftId here is rarity ID
        uint256 index = random();
        uint24 nftId = updateConditions(index);
        _safeMint(user_addr, nftId);
        _setTokenURI(nftId, TokenURI);
        _totalNFTsMinted++;
        dropsite_NFT_Owner[user_addr].owned_Dropsite_NFTs.push(nftId);
        return (nftId, TokenURI);
    }

    //MATIC Amount will be deposited
    function depositAmount(address payee, uint256 amountToDeposit) internal {
        deposits[payee] += amountToDeposit;
    }

    //Random minting after Crypto Payments
    function cryptoRandomMint(address user_addr, uint8 noOfMints)
        external
        payable
        contractIsNotPaused
        categoriesAreSet
        mintingFeeIsSet
        maxMintingIsSet
        returns (string[] memory)
    {
        require(_msgSender() == tx.origin && !_msgSender().isContract(), "Contracts cannot mint");
        require(user_addr != address(0), "Cannot mint to the zero address");
        require(
            noOfMints+NFTsPerWallet[user_addr] <= _maxMints && noOfMints > 0,
            "You cannot mint more than max mint limit"
        );
        require(
            (_totalNFTsMinted + noOfMints) <= _maxNFTs,
            "Max Minting Limit reached"
        );
        require(msg.value == _mintFees.mul(noOfMints), "Not Enough Balance");
        require(
            NFTsPerWallet[user_addr] < _maxNFTsPerWallet,
            "This wallet has reached Maximum Mint Limit"
        );

        if (_mintEndTime > block.timestamp)
            require(
                checkWhitelist(user_addr),
                "Not in the Whitelist or Timer Error"
            );
        //else if time has ended or user_addr is in the whitelist
        uint256 returnedNftID;
        string memory returnedNftTokenURI;
        string[] memory randomMintedNfts = new string[](noOfMints);
        for (uint256 i = 0; i <= noOfMints - 1; i++) {
            (returnedNftID,returnedNftTokenURI) = randomMinting(user_addr);
            //randomMintedNfts[i] = returnedNftID;
            randomMintedNfts[i]= returnedNftTokenURI;
        }
        depositAmount(_msgSender(), msg.value);
        NFTsPerWallet[user_addr]+=noOfMints;
        emit isMinted(user_addr, randomMintedNfts);
        return randomMintedNfts;
    }
    
}