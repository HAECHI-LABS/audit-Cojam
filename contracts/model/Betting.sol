pragma solidity ^0.6.0;

struct Betting {
    uint256 marketKey;
    uint256 answerKey;
    address voter;
    uint256 tokens;
    uint createTime;
    bool exist;
}

