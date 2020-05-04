pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Answer.sol";

struct Market {
    address creator;
    string title;
    string status;
    uint256 creatorFee;
    uint256 cojamFeePercentage;
    uint256 charityFeePercentage;
    uint createTime;
    bool exist;
}