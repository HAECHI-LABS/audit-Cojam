pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Model/Market.sol";
import "./Utils/IteratableSet.sol";

contract MarketManager {
    
    address constant public NULL = address(0);
    
    mapping(uint256 => Market) private _markets;  // All _markets
    mapping(uint256 => Answer) private _answers;  // All _answers
    mapping(uint256 => Betting) private _bettings;  // All __bettings;
    
    mapping(uint256 => IteratableSet) private _marketToAnswerConstraint; // marketKey -> answerKey ( 1 : N )
    mapping(uint256 => IteratableSet) private _answerToBettingConstraint;    // answerKey -> bettingKey ( 1 : N )
    
    function _getBetting(uint256 bettingKey) internal view returns(Betting memory) {
        require(true == _bettings[bettingKey].exist);
        return _bettings[bettingKey];
    }
    
    function _bet(uint256 marketKey, uint256 answerKey, uint256 bettingKey, address voter, uint256 tokens) internal returns(bool) {
        require(true == _markets[marketKey].exist);   // Market must be not null
        require(true == _isMarketStatus(marketKey, 'approve')); // Market status must be approve when user betting.
        require(true == _answers[answerKey].exist);   // Answer must be not null
        require(false == _bettings[bettingKey].exist); // Betting found by key must be null
        require(voter != NULL); // voter must be not null
        require(0 < tokens);    // tokens must be greater than zero.

        _bettings[bettingKey] = Betting(voter, tokens, now, true);  // Create Betting
        if(address(_answerToBettingConstraint[answerKey]) == NULL){      // Create Link
            _answerToBettingConstraint[answerKey] = new IteratableSet();
        }
        
        IteratableSet bettingKeySet = _answerToBettingConstraint[answerKey]; // Linking Answer to Betting
        bettingKeySet.put(bettingKey);
        
        return true;
    }
    
    function _approveMarket(uint256 marketKey, address creator, string memory title, string memory status, uint256[] memory answerKeys) internal returns(bool){
        require(false == _markets[marketKey].exist);   // Market must be not null
        
        _markets[marketKey] = Market(creator, title, status, now, true);    // Create Market
        for(uint256 ii=0; ii<answerKeys.length; ii++){                 // Create Answer
            require(false == _answers[answerKeys[ii]].exist);
            _answers[answerKeys[ii]] = Answer(true);
        }
        
        require(address(_marketToAnswerConstraint[marketKey]) == NULL);
        _marketToAnswerConstraint[marketKey] = new IteratableSet();     // Linking Market to Answer
        IteratableSet answerKeySet = _marketToAnswerConstraint[marketKey];
        for(uint256 ii=0; ii<answerKeys.length; ii++){
            answerKeySet.put(answerKeys[ii]);
        }
        
        return true;
    }
    
    function _getMarket(uint256 marketKey) internal view returns(Market memory){
        require(true == _markets[marketKey].exist);
        
        return _markets[marketKey];
    }
    
    function _getAnswerKeys(uint256 marketKey) internal view returns(uint256[] memory) {
         IteratableSet answerSet = _marketToAnswerConstraint[marketKey];
         return answerSet.getAvailableKeys();
    }
    
    function _getAnswer(uint256 answerKey) internal view returns(Answer memory) {
        require(true == _answers[answerKey].exist);
        
        return _answers[answerKey];
    }
    
    function _getBettingKeys(uint256 answerKey) internal view returns(uint256[] memory) {
        IteratableSet bettingSet = _answerToBettingConstraint[answerKey];
        return bettingSet.getAvailableKeys();
    }
    
    function _changeMarketStatus(uint256 marketKey, string memory status) internal returns(bool) {
        require(true == _markets[marketKey].exist);   // Market must be not null
        
        Market storage market = _markets[marketKey];
        market.status = status;
        return true;
    }
    
    function _isMarketStatus(uint256 marketKey, string memory status) internal view returns(bool) {
        require(true == _markets[marketKey].exist);   // Market must be not null
        
        Market memory market = _markets[marketKey];
        
        return (keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked(market.status)));
    }
}
