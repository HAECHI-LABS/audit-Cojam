pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "..//Model/Market.sol";
import "./MarketAnswerConstraint.sol";
import "./AnswerBettingConstraint.sol";
import "../ERC20/SafeMath.sol";
import "../Model/SuccessMarketDataStructure.sol";
import "../Model/AdjournMarketDataStructure.sol";

contract MarketManager is MarketAnswerConstraint, AnswerBettingConstraint{
    
    using SafeMath for uint256;
    
    address constant public NULL = address(0);
    
    mapping(uint256 => Market) private _markets;  // All _markets
    mapping(uint256 => Answer) private _answers;  // All _answers
    mapping(uint256 => Betting) private _bettings;  // All __bettings;
    
    function _getBetting(uint256 bettingKey) internal view returns(Betting memory) {
        require(true == _bettings[bettingKey].exist, "betting is null");
        return _bettings[bettingKey];
    }
    
    function _bet(uint256 marketKey, uint256 answerKey, uint256 bettingKey, address voter, uint256 tokens) internal{
        require(true == _markets[marketKey].exist, "market must be not null");   // Market must be not null
        require(true == _isMarketStatus(marketKey, 'approve'), "market status must be approve when user betting"); // Market status must be approve when user betting.
        require(true == containsAnswerKey(marketKey, answerKey), "answer must included in market");   // answer must included in market
        require(true == _answers[answerKey].exist, "answer must be not null");   // Answer must be not null
        require(false == _bettings[bettingKey].exist, "already betting exist"); // Betting found by key must be null
        require(voter != NULL, "voter must be not null"); // voter must be not null
        require(0 < tokens, "tokens must be greater than zero");    // tokens must be greater than zero.

        _bettings[bettingKey] = Betting(voter, tokens, now, true);  // Create Betting
        
        putBettingKey(answerKey, bettingKey);
    }
    
    function _approveMarket(uint256 marketKey, address creator, string memory title, string memory status, uint256 creatorFee, uint256 cojamFeePercentage, uint256 charityFeePercentage, uint256[] memory answerKeys) internal{
        require(false == _markets[marketKey].exist, "already market exist");   // Market must be not null
        
        _markets[marketKey] = Market(creator, title, status, creatorFee, cojamFeePercentage, charityFeePercentage, now, true);    // Create Market
        for(uint256 ii=0; ii<answerKeys.length; ii++){                 // Create Answer
            require(false == _answers[answerKeys[ii]].exist, "already answer exist");
            _answers[answerKeys[ii]] = Answer(true);
        }
        
        for(uint256 ii=0; ii<answerKeys.length; ii++){
           putAnswerKey(marketKey, answerKeys[ii]);
        }
    }
    
    function _getMarket(uint256 marketKey) internal view returns(Market memory){
        require(true == _markets[marketKey].exist, "market is null");
        
        return _markets[marketKey];
    }
    
    function _getAnswerKeys(uint256 marketKey) internal view returns(uint256[] memory) {
         return getAvailableAnswerKeys(marketKey);
    }
    
    function _getAnswer(uint256 answerKey) internal view returns(Answer memory) {
        require(true == _answers[answerKey].exist, "answer is null");
        
        return _answers[answerKey];
    }
    
    function _getBettingKeys(uint256 answerKey) internal view returns(uint256[] memory) {
        return getAvailableBettingKeys(answerKey);
    }
    
    function _changeMarketStatus(uint256 marketKey, string memory status) internal returns(bool) {
        require(true == _markets[marketKey].exist, "market is null");   // Market must be not null
        
        Market storage market = _markets[marketKey];
        market.status = status;
        return true;
    }
    
    function _isMarketStatus(uint256 marketKey, string memory status) internal view returns(bool) {
        Market memory market = _getMarket(marketKey);
        
        return (keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked(market.status)));
    }
    
    function _getMarketTokenToBet(uint256 marketKey) internal view returns(uint256) {
        uint256[] memory answerKeys = getAvailableAnswerKeys(marketKey);
        
        uint256 marketTotalTokens = 0;
        
        for(uint256 ii=0; ii<answerKeys.length; ii++){
            marketTotalTokens = SafeMath.add(marketTotalTokens, _getAnswerTokenToBet(answerKeys[ii]));
        }
        
        return marketTotalTokens;
    }
    
    function _getAnswerTokenToBet(uint256 answerKey) internal view returns(uint256) {
        uint256[] memory bettingKeys = getAvailableBettingKeys(answerKey);
        
        uint256 answerTotalTokens = 0;
        
        for(uint256 ii=0; ii<bettingKeys.length; ii++){
            Betting memory betting = _bettings[bettingKeys[ii]];
            
            answerTotalTokens = SafeMath.add(answerTotalTokens, betting.tokens);
        }
        
        return answerTotalTokens;
    }
    
    function _getExpectedSuccessMarketResult(uint256 marketKey, uint256 answerKey) internal view returns(
            SuccessMarketDataStructure memory
        ) {
        require(true == _isMarketStatus(marketKey, "approve"), "market status is not approve"); //  이전 상태는 approve 이어야 합니다.
        require(true == containsAnswerKey(marketKey, answerKey), "answer must included in market");
        
        Market memory market = _getMarket(marketKey);
        
        uint256 marketTotalTokens = _getMarketTokenToBet(marketKey);
        uint256 answerTotalTokens = _getAnswerTokenToBet(answerKey);
        
        uint256 creatorFee = market.creatorFee;
        uint256 cojamFee = SafeMath.mulPercentage(marketTotalTokens, market.cojamFeePercentage);
        uint256 charityFee = SafeMath.mulPercentage(marketTotalTokens, market.charityFeePercentage);
        
        uint256 realTotalToken = marketTotalTokens;
        
        
        require(creatorFee <= realTotalToken, "creatorFee is more than real total token");
        realTotalToken = SafeMath.sub(realTotalToken, creatorFee);
        
        require(cojamFee <= realTotalToken, "cojamFee is more than real total token");
        realTotalToken = SafeMath.sub(realTotalToken, cojamFee);
        
        require(charityFee <= realTotalToken, "charityFee is more than real total token");
        realTotalToken = SafeMath.sub(realTotalToken, charityFee);
        
        uint256 tokenBalance = realTotalToken;
        
        _getAnswer(answerKey);
        
        uint256[] memory bettingKeys = getAvailableBettingKeys(answerKey);
        address[] memory destinations = new address[](bettingKeys.length);     
        uint256[] memory tokens = new uint256[](bettingKeys.length);        
        
        if(0 < bettingKeys.length && 0 < answerTotalTokens) {
            uint256 dividendRate = SafeMath.divPercentageResult(realTotalToken, answerTotalTokens);
            
            for(uint256 ii=0 ;ii<bettingKeys.length; ii++){
                Betting memory betting = _getBetting(bettingKeys[ii]);
                destinations[ii] = betting.voter;
                tokens[ii] = SafeMath.mulPercentage(betting.tokens, dividendRate);
                tokenBalance = SafeMath.sub(tokenBalance, tokens[ii]);
            }
        }
        
        return SuccessMarketDataStructure(marketTotalTokens, destinations, tokens, creatorFee, cojamFee, charityFee, tokenBalance);
    }
    
    function _getExpectedAdjournMarketResult(uint256 marketKey) internal view returns(AdjournMarketDataStructure memory) {
        require(true == _isMarketStatus(marketKey, "approve"), "market status is not approve"); //  이전 상태는 approve 이어야 합니다.
        
        uint256 marketTotalTokens = _getMarketTokenToBet(marketKey);
        
        uint256[] memory answerKeys = getAvailableAnswerKeys(marketKey);
        uint256 bettingTotalLength = 0;
        for(uint256 ii=0; ii<answerKeys.length; ii++){
            uint256[] memory bettingKeys = getAvailableBettingKeys(answerKeys[ii]);
            bettingTotalLength = SafeMath.add(bettingTotalLength, bettingKeys.length);
        }
        
        address[] memory destinations = new address[](bettingTotalLength);
        uint256[] memory tokens = new uint256[](bettingTotalLength);
        
        uint256 idx = 0;
        for(uint256 ii=0; ii<answerKeys.length; ii++){
            uint256[] memory bettingKeys = getAvailableBettingKeys(answerKeys[ii]);
            
            for(uint256 jj=0; jj<bettingKeys.length; jj++){
                Betting memory betting = _getBetting(bettingKeys[jj]);
                destinations[idx] = betting.voter;
                tokens[idx] = betting.tokens;
                idx = SafeMath.add(idx, 1);
            }
        }
        
        return AdjournMarketDataStructure(marketTotalTokens, destinations, tokens);
    }
}
