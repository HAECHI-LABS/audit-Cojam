pragma solidity ^0.6.0;

import "./Betting.sol";

struct Answer {
    uint256 marketKey;
    uint256 answerTotalTokens;
    bool exist;
}