// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract test {
    bool flag = false;
    uint no_of_Categories;

    mapping(uint => uint) categoryMaxCount;

    //set categories and NFTs in each category
    function setCategories(uint Categories, uint[] memory categoryCount) public{
        for(uint i=0;i<Categories;i++){
            categoryMaxCount[i]=categoryCount[i];
        }
    }

    //Check NFT-ID Availability
    function inputNFTId(uint categoryID) public {
        uint count = 0;
        while(flag == false && (count<no_of_Categories)){
            if(!flag)
                flag = checkAvailability(count);
        }
    }

    function checkAvailability(uint categoryID) public returns (bool){

    }
}