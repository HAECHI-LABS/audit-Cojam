pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../Model/Market.sol";
import "./MarketAnswerConstraint.sol";
import "./AnswerBettingConstraint.sol";
import "../ERC20/SafeMath.sol";
import "../Model/SuccessMarketDataStructure.sol";
import "../Model/AdjournMarketDataStructure.sol";

contract MarketManager is MarketAnswerConstraint, AnswerBettingConstraint{

    using SafeMath for uint256;

    mapping(uint256 => Market) internal _markets;  // All _markets
    mapping(uint256 => Answer) internal _answers;  // All _answers
    mapping(uint256 => Betting) internal _bettings;  // All __bettings;

    uint256 internal constant successMarketValidityDate = 180;
    uint256 internal constant adjournMarketValidityDate = 180;
    string internal constant APPROVE_MARKET_KEY = "approve";
    string internal constant FINISHED_MARKET_KEY = "finished";
    string internal constant SUCCESS_MARKET_KEY = "success";
    string internal constant ADJOURN_MARKET_KEY = "adjourn";

    function _getBetting(uint256 bettingKey) internal view returns(Betting memory) {
        require(_bettings[bettingKey].exist, "Market/Betting: betting key does not exist");
        return _bettings[bettingKey];
    }

    modifier bettable(uint256 marketKey, uint256 answerKey, uint256 bettingKey, uint256 tokens) {
        require((_isMarketStatus(marketKey, APPROVE_MARKET_KEY)) && // Market status must be approve when user bets
        (containsAnswerKey(marketKey, answerKey)) &&                // Answer must be not null
        (_answers[answerKey].exist) &&                              // answer must included in market
        (!_bettings[bettingKey].exist),                             // Betting found by key must be null
        "Market/Betting: Betting is not available");
        _;
    }

    function _bet(uint256 mk, uint256 ak, uint256 bk, address voter, uint256 tokens) internal{

        _bettings[bk] = Betting(mk, ak, voter, tokens, now, true);  // Create Betting

        _markets[mk].marketTotalTokens = _markets[mk].marketTotalTokens.add(tokens);    // 추후 배당률을 계산하기 위함
        _answers[ak].answerTotalTokens = _answers[ak].answerTotalTokens.add(tokens);

        putBettingKey(ak, bk);
    }

    function _isRetrievable(uint256 marketKey) view internal returns(bool){
        Market memory market = _getMarket(marketKey);

        require(_isMarketStatus(marketKey, SUCCESS_MARKET_KEY) || _isMarketStatus(marketKey, ADJOURN_MARKET_KEY), "Market/Retrieve: Cannot Retrieve not finished market");

        if(_isMarketStatus(marketKey, SUCCESS_MARKET_KEY)) {
            uint256 diff = (now - market.successTime) / 60 / 60 / 24;
            return successMarketValidityDate <= diff;
        }
        else {
            uint256 diff = (now - market.adjournTime) / 60 / 60 / 24;
            return adjournMarketValidityDate <= diff;
        }
    }

    function _availableReceiveTokens(uint256 mk, uint256 bk) view internal returns(uint256) {
        Market memory m = _getMarket(mk);
        require(_isMarketStatus(mk, SUCCESS_MARKET_KEY) || _isMarketStatus(mk, ADJOURN_MARKET_KEY), "Market/Receive: Cannot receive token");

        uint256 percentage = 100;
        Betting memory b = _getBetting(bk);
        uint256 _mk = b.marketKey;
        uint256 _ak = b.answerKey;

        uint256 ak = _markets[mk].correctAnswerKey;
        if(_isMarketStatus(mk,SUCCESS_MARKET_KEY)){
            require(ak == _ak, "Market/Receive: Answer key is not succeeded answer key");
            Answer memory answer;
            answer = _getAnswer(ak);
            percentage = SafeMath.divPercentageResult(m.marketRemainTokens, answer.answerTotalTokens);
        }


        require((mk == _mk) &&
        (containsAnswerKey(_mk, _ak)) &&    // answer must included in market
        (containsBettingKey(_ak, bk)) &&   // betting must included in answer
        (b.voter == msg.sender) , "Market/Receive: Given information does not match");

        uint256 tokens = b.tokens.mul(percentage).div(100);

        return tokens;
    }

    function _approveMarket(uint256 marketKey, address creator, string memory title, string memory status, uint256 creatorFee, uint256 creatorFeePercentage, uint256 cojamFeePercentage, uint256 charityFeePercentage, uint256[] memory answerKeys) internal{
        require((!_markets[marketKey].exist), "Market/ApproveMarket: Market key already exist");
        require(creatorFeePercentage.add(cojamFeePercentage).add(charityFeePercentage) <= 100, "Market/ApproveMarket: Sum of fee percentage is larger than 100");   // Market must be not null

        _markets[marketKey] = Market(creator, title, status, creatorFee,creatorFeePercentage, cojamFeePercentage, charityFeePercentage, now, 0, 0, 0, 0, 0, 0, true);    // Create Market

        for(uint256 ii=0; ii<answerKeys.length; ii++){                 // Create Answer
            require(!_answers[answerKeys[ii]].exist, "Market/ApproveMarket: AnswerKey already exist");
            _answers[answerKeys[ii]] = Answer(marketKey, 0, true);
        }

        for(uint256 ii=0; ii<answerKeys.length; ii++){
           putAnswerKey(marketKey, answerKeys[ii]);
        }
    }

    function _getMarket(uint256 marketKey) internal view returns(Market memory){
        require(_markets[marketKey].exist, "Market/Market: MarketKey does not exist");

        return _markets[marketKey];
    }

    function _finishMarket(uint256 marketKey) internal returns(bool){
        require(_isMarketStatus(marketKey, APPROVE_MARKET_KEY), "Market/FinishMarket: Market is not approved status");             // market의 상태는 approve 상태여야 한다.
        _changeMarketStatus(marketKey, FINISHED_MARKET_KEY);

        _markets[marketKey].finishTime = now;
        _markets[marketKey].marketRemainTokens = _markets[marketKey].marketTotalTokens;

        return true;
    }

    function _setSuccessMarket(uint256 marketKey, uint256 answerKey) internal returns(bool) {
        require(_isMarketStatus(marketKey, FINISHED_MARKET_KEY), "Market/SuccessMarket: Market is not finished status");        // success 이전 상태는 finished여야 한다.
        require(containsAnswerKey(marketKey, answerKey), "Market/SuccessMarket: Market does not contain answerKey");
        _changeMarketStatus(marketKey, SUCCESS_MARKET_KEY);
        _markets[marketKey].correctAnswerKey = answerKey;
        _markets[marketKey].successTime = now;

        return true;
    }

    function _setAdjournMarket(uint256 marketKey) internal returns(bool) {
        require(_isMarketStatus(marketKey, FINISHED_MARKET_KEY), "Market/AdjournMarket: Market is not finished status");        // adjourn 이전 상태는 finished여야 한다.
        _changeMarketStatus(marketKey, ADJOURN_MARKET_KEY);
        _markets[marketKey].adjournTime = now;

        return true;
    }

    function _getAnswerKeys(uint256 marketKey) internal view returns(uint256[] memory) {
         return getAvailableAnswerKeys(marketKey);
    }

    function _getAnswer(uint256 answerKey) internal view returns(Answer memory) {
        require(_answers[answerKey].exist, "Market/Answer: AnswerKey does not exist");

        return _answers[answerKey];
    }

    function _getBettingKeys(uint256 answerKey) internal view returns(uint256[] memory) {
        return getAvailableBettingKeys(answerKey);
    }

    function _changeMarketStatus(uint256 marketKey, string memory status) internal returns(bool) {
        require(_markets[marketKey].exist, "Market/ChangeStatus: MarketKey does not exist");   // Market must be not null

        Market storage market = _markets[marketKey];
        market.status = status;
        return true;
    }

    function _isMarketStatus(uint256 marketKey, string memory status) internal view returns(bool) {
        Market memory m = _getMarket(marketKey);

        return (keccak256(abi.encodePacked(status)) == keccak256(abi.encodePacked(m.status)));
    }

}
