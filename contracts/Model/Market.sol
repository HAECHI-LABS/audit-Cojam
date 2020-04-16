pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Answer.sol";

struct Market {
    address creator;
    string title;
    string status;
    uint createTime;
    bool exist;
}