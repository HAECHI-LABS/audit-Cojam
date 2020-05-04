pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";

/**
 * Costum ERC20 
 */
contract COJAMERC20 is ERC20 {
    
    event Bet(uint256 marketKey, uint256 answerKey, uint256 bettingkey, uint256 tokens);
    event ApproveMarket(uint256 marketKey, address creator, string title, string status, uint256[] answerKeys);
    event AdjournMarket(uint256 marketKey);
    event SuccessMarket(uint256 marketKey);
    event LockUser(address target, bool flag);
    event DividendToken(address from, address to, uint256 token);
}