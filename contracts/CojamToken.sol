pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ERC20/COJAMERC20.sol";
import "./ERC20/ERC20Detailed.sol";
import "./ERC20/IERC20.sol";

import "./Manager/MarketManager.sol";
import "./Manager/UserManager.sol";
import "./Manager/AccountManager.sol";

contract CojamToken is IERC20, COJAMERC20, ERC20Detailed, MarketManager, UserManager, AccountManager {
    
    constructor() ERC20Detailed("Cojam", "CT", 18) public {
        uint256 initialSupply = 5000000000 * (10 ** 18);
        
        _owner = msg.sender;
        _mint(msg.sender, initialSupply);
    }
    
    /**
     * 마켓의 정보를 가져오는 함수
     * */
    function getMarket(uint256 marketKey) public view returns(uint256, string memory, address, string memory, uint256[] memory, uint){
        Market memory market = _getMarket(marketKey);
        return (marketKey, market.title, market.creator, market.status, _getAnswerKeys(marketKey), market.createTime);
    }
    
    /**
     * Answer의 정보를 가져오는 함수 
     * */
    function getAnswer(uint256 answerKey) public view returns(uint256, uint256[] memory){
        _getAnswer(answerKey);      // Answer가 존재하는지 확인하기 위한 코드 (결과값이 사용되진 않음)
        return (answerKey, _getBettingKeys(answerKey));
    }
    
    /**
     * Betting 정보를 가져오는 함수
     * */
    function getBetting(uint256 bettingKey) public view returns(uint256, address, uint256, uint){
        Betting memory betting = _getBetting(bettingKey);
        
        return (bettingKey, betting.voter, betting.tokens, betting.createTime);
    }
    
    /**
     * 수수료 계좌 등 정보를 가져오는 함수 
     * */
    function getAccounts() public view returns(address, address, address) {
        return(_owner, _cojamFeeAccount, _charityFeeAccount);
    }
    
    /**
     * SuccessMarket 수행 시의 예상 결과를 미리 계산해보기 위한 함수
     * */
    function getExpectedSuccessMarketResult(uint256 marketKey, uint256 answerKey) public view returns(uint256, address[] memory, uint256[] memory, uint256, uint256, uint256, uint256) {
         (SuccessMarketDataStructure memory structure) = _getExpectedSuccessMarketResult(marketKey, answerKey);
        
        return(
            structure.marketTotalToken,
            structure.destinations,
            structure.tokens,
            structure.creatorFee,
            structure.cojamFee,
            structure.charityFee,
            structure.balanceTokens
            );
    }
    
    /**
     * AdjournMarket 수행 시의 예상 결과를 미리 계산해보기 위한 함수
     * */
    function getExpectedAdjournMarketResult(uint256 marketKey) public view returns(uint256, address[] memory, uint256[] memory) {
        (AdjournMarketDataStructure memory structure) = _getExpectedAdjournMarketResult(marketKey);
        
        return(
            structure.marketTotalToken,
            structure.destinations,
            structure.tokens
            );
    }
    
    /**
     * 관리자가 사용자의 차단 여부를 확인하는 함수
     * */
    function isLock(address target) public view returns(bool) {
        return _containsLockUser(target);
    }
    
    /**
     * 관리자가 마켓의 상태를 success으로 변경하고, 각 주소에 대한 보상을 지급하는 함수
     * */
    function successMarket(uint256 marketKey, uint256 answerKey) public isOwner() returns(bool) {
        (SuccessMarketDataStructure memory structure) = _getExpectedSuccessMarketResult(marketKey, answerKey);
        
        require(structure.destinations.length == structure.tokens.length, "addresses length & tokens length is different");
        require(true == _changeMarketStatus(marketKey, "success"), "can not change market status approve to success");
        
        for(uint256 ii=0; ii<structure.destinations.length; ii++){
            address to = structure.destinations[ii];
            uint256 token = structure.tokens[ii];
            dividendToken(to, token);
        }
        
        Market memory market = _getMarket(marketKey);
        
        require(_cojamFeeAccount != address(0), "cojam fee account is null");
        require(_charityFeeAccount != address(0), "charity fee account is null");
        
        dividendToken(market.creator, structure.creatorFee);
        dividendToken(_cojamFeeAccount, structure.cojamFee);
        dividendToken(_charityFeeAccount, structure.charityFee);
        
        emit SuccessMarket(marketKey);
        
        return true;
    }
    
    /**
     * 관리자가 마켓의 상태를 adjourn으로 변경하고, 취소된 마켓에 참여했던 사용자들에게 토큰을 돌려주는 함수
     * */
    function adjournMarket(uint256 marketKey) public isOwner() returns(bool) {
        (AdjournMarketDataStructure memory structure) = _getExpectedAdjournMarketResult(marketKey);
        
        require(structure.destinations.length == structure.tokens.length, "addresses length & tokens length is different");
        require(true == _changeMarketStatus(marketKey, "adjourn"), "can not change market status approve to adjourn");
        
        for(uint256 ii=0; ii<structure.destinations.length; ii++){
            address to = structure.destinations[ii];
            uint256 token = structure.tokens[ii];
            dividendToken(to, token);
        }
        
        emit AdjournMarket(marketKey);
        return true;
    }
    
    /**
     * 마켓 종료 후 계산 된 배당 토큰들을 사용자들에게 지급하는 함수
     * */
    function dividendToken(address to, uint256 token) private {   
        _transfer(address(this), to, token);
        
        emit DividendToken(address(this), to, token);
    }
    
    /**
     * 수수료 계좌를 관리자 권한으로 변경할 수 있는 함수
     * */
    function setAccount(string memory key, address account) public isOwner() returns(bool) {
        return _setAccount(key, account);
    }
    
    /**
     * 사용자가 마켓에 베팅을 하는 함수
     * */
    function bet(uint256 marketKey, uint256 answerKey, uint256 bettingKey, uint256 tokens) public isAllowedUser(msg.sender) returns(bool){
        address sender = msg.sender;
        address to = address(this);  // 컨트랙트 주소를 얻어온 뒤
    
        _bet(marketKey, answerKey, bettingKey, sender, tokens);    // 데이터 변경이 실패하면 거래 전으로 돌리기
        __transfer(to, tokens);
        
        emit Bet(marketKey, answerKey, bettingKey, tokens);
        return true;
    }
    
    /**
     * 관리자가 마켓을 추가하는 함수 
     * 승인이 된 마켓이므로 상태는 approve
     **/
    function approveMarket(uint256 marketKey, address creator, string memory title, uint256 creatorFee, uint256 cojamFeePercentage, uint256 charityFeePercentage, uint256[] memory answerKeys) public isOwner() isAllowedUser(creator) returns(bool) {
        _approveMarket(marketKey, creator, title, "approve", creatorFee, cojamFeePercentage, charityFeePercentage, answerKeys);
        
        emit ApproveMarket(marketKey, creator, title, "approve", answerKeys);
        return true;
    }
    
    /**
     * 관리자가 사용자를 차단하는 함수
     * */
    function lock(address[] memory targets) public isOwner() returns(bool[] memory) {
        bool[] memory results = new bool[](targets.length);
        
        for(uint256 ii=0; ii<targets.length; ii++){
            require(_owner != targets[ii], "can not lock owner");     // 관리자 주소가 컨트롤 되어서는 안 된다!
            results[ii] = _insertLockUser(targets[ii]);
            emit LockUser(targets[ii], true);
        }
        
        return results;
    }
    
    /**
     * 관리자가 사용자를 차단하는 함수
     * */
    function unlock(address[] memory targets) public isOwner() returns(bool[] memory) {
        bool[] memory results = new bool[](targets.length);
        
        for(uint256 ii=0; ii<targets.length; ii++){
            require(_owner != targets[ii], "can not unlock owner");     // 관리자 주소가 컨트롤 되어서는 안 된다!
            results[ii] = _removeLockUser(targets[ii]);
            emit LockUser(targets[ii], false);
        }
        
        return results;
    }
    
    /**
     * ERC20 기본 함수
    **/
    function transfer(address recipient, uint256 amount) public override isAllowedUser(msg.sender) returns (bool){
        return __transfer(recipient, amount);
    }
    
    function totalSupply() public override view returns (uint256){
        return __totalSupply();
    }
    
    function balanceOf(address account) public override view returns (uint256){
        return __balanceOf(account);
    }

    function allowance(address owner, address spender) public view override returns (uint256){
        return __allowance(owner, spender);
    }
    
    function approve(address spender, uint256 amount) public override isAllowedUser(msg.sender) returns (bool){
        return __approve(spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override isAllowedUser(sender) returns (bool){
        return __transferFrom(sender, recipient, amount);
    }
}