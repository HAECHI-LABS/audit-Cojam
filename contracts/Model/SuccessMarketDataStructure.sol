pragma solidity ^0.6.0;

struct SuccessMarketDataStructure {
    uint256 marketTotalToken;
    address[] destinations; 
    uint256[] tokens;
    uint256 creatorFee;
    uint256 cojamFee;
    uint256 charityFee;
    uint256 balanceTokens;
}