pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ERC20/COJAMERC20.sol";
import "./ERC20/ERC20Detailed.sol";
import "./ERC20/IERC20.sol";

import "./Model/Owner.sol";
import "./MarketManager.sol";
import "./Utils/AddressSet.sol";

contract CojamToken is IERC20, COJAMERC20, ERC20Detailed, MarketManager {
    
    address private _owner;
    AddressSet private lockedUsers = new AddressSet();
    
    constructor() ERC20Detailed("Cojam", "CT", 18) public {
        uint256 initialSupply = 5000000000 * (10 ** 18);
        
        _owner = msg.sender;
        _mint(msg.sender, initialSupply);
    }
    
    /**
     * 사용자가 마켓에 베팅을 하는 함수
     * */
    function bet(uint256 marketKey, uint256 answerKey, uint256 bettingKey, uint256 tokens) public isAllowedUser(msg.sender) returns(bool){
        address sender = msg.sender;
        address to = _owner;  // 관리자 주소를 얻어온 뒤
    
        require(true == _bet(marketKey, answerKey, bettingKey, sender, tokens));    // 데이터 변경이 실패하면 거래 전으로 돌리기
        require(true == __transfer(to, tokens));
        
        emit Bet(marketKey, answerKey, bettingKey, tokens);
        return true;
    }
    
    function getBetting(uint256 bettingKey) public view returns(Betting memory){
        Betting memory betting = _getBetting(bettingKey);
        return betting;
    }
    
    /**
     * 관리자가 마켓을 추가하는 함수 
     * 승인이 된 마켓이므로 상태는 approve
     **/
    function approveMarket(uint256 marketKey, address creator, string memory title, uint256[] memory answerKeys) public isOwner() isAllowedUser(creator) returns(bool) {
        require(true == _approveMarket(marketKey, creator, title, "approve", answerKeys));
        
        emit ApproveMarket(marketKey, creator, title, "approve", answerKeys);
        return true;
    }
    
    function getMarket(uint256 marketKey) public view returns(uint256, string memory, address, string memory, uint256[] memory){
        Market memory market = _getMarket(marketKey);
        return (marketKey, market.title, market.creator, market.status, _getAnswerKeys(marketKey));
    }
    
    function getAnswer(uint256 answerKey) public view returns(uint256, uint256[] memory){
        return (answerKey, _getBettingKeys(answerKey));
    }
    
    /**
     * 관리자가 마켓의 상태를 adjourn으로 변경하고, 취소된 마켓에 참여했던 사용자들에게 토큰을 돌려주는 함수
     * */
    function adjournMarket(uint256 marketKey, address[] memory voters, uint256[] memory tokens) public isOwner() returns(bool) {
        require(voters.length == tokens.length); // 토큰을 돌려받는 인원수는 토큰 리스트 수와 같아야 합니다.
        require(true == _isMarketStatus(marketKey, "approve")); //  이전 상태는 approve 이어야 합니다.
        require(true == _changeMarketStatus(marketKey, "adjourn"));
        
        uint256 sumTokens;
        for(uint256 ii=0; ii<tokens.length; ii++){
            sumTokens += tokens[ii];
        }
        
        require(sumTokens <= __balanceOf(_owner)); // 관리자의 남은 토큰이 지급할 모든 토큰보다 같거나 많아야 합니다.
        
        for(uint256 ii=0; ii<voters.length; ii++){
            __transfer(voters[ii], tokens[ii]);
        }
        
        emit AdjournMarket(marketKey, voters, tokens);
        return true;
    }
    
    /**
     * 관리자가 마켓의 상태를 success으로 변경하고, 각 주소에 대한 보상을 지급하는 함수
     * */
    function successMarket(uint256 marketKey, address[] memory voters, uint256[] memory tokens) public isOwner() returns(bool) {
        require(voters.length == tokens.length); // 보상을 받는 인원수는 토큰 리스트 수와 같아야 합니다.
        require(true == _isMarketStatus(marketKey, "approve")); //  이전 상태는 approve 이어야 합니다.
        require(true == _changeMarketStatus(marketKey, "success"));
        
        uint256 sumTokens;
        for(uint256 ii=0; ii<tokens.length; ii++){
            sumTokens += tokens[ii];
        }
        
        require(sumTokens <= __balanceOf(_owner)); // 관리자의 남은 토큰이 지급할 모든 토큰보다 같거나 많아야 합니다.
        
        for(uint256 ii=0; ii<voters.length; ii++){
            __transfer(voters[ii], tokens[ii]);
        }
        
        emit SuccessMarket(marketKey, voters, tokens);
        return true;
    }
    
    /**
     * 관리자가 사용자를 차단하는 함수
     * */
    function lock(address[] memory targets) public isOwner() returns(bool[] memory) {
        bool[] memory results = new bool[](targets.length);
        
        for(uint256 ii=0; ii<targets.length; ii++){
            require(_owner != targets[ii]);     // 관리자 주소가 컨트롤 되어서는 안 된다!
            results[ii] = lockedUsers.insert(targets[ii]);
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
            require(_owner != targets[ii]);     // 관리자 주소가 컨트롤 되어서는 안 된다!
            results[ii] = lockedUsers.remove(targets[ii]);
            emit LockUser(targets[ii], false);
        }
        
        return results;
    }
    
    /**
     * 관리자가 사용자의 차단 여부를 확인하는 함수
     * */
    function isLock(address target) public view isOwner() returns(bool) {
        return lockedUsers.contains(target);
    }
    
    /**
     * 관리자가 사용자로부터 토큰을 강제 회수하는 함수
     */ 
    function refund(address target, uint256 tokens) public isOwner() returns(bool) {
        __refund(msg.sender, target, tokens);
        
        emit Refund(target, tokens);
        return true;
    }
    
    modifier isOwner(){
        require(_owner == msg.sender);
        _;
    }
    
    modifier isAllowedUser(address user) {
        require(lockedUsers.contains(user) == false);    // 차단된 사용자가 아니어야 한다!
        _;
    }
    
    function transfer(address recipient, uint256 amount) public virtual override isAllowedUser(msg.sender) returns (bool){
        return __transfer(recipient, amount);
    }
    
    function totalSupply() public virtual override view returns (uint256){
        return __totalSupply();
    }
    
    function balanceOf(address account) public virtual override view returns (uint256){
        return __balanceOf(account);
    }

    function allowance(address owner, address spender) public virtual view override returns (uint256){
        return __allowance(owner, spender);
    }
    
    function approve(address spender, uint256 amount) public virtual override isAllowedUser(msg.sender) returns (bool){
        return __approve(spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override isAllowedUser(msg.sender) returns (bool){
        return __transferFrom(sender, recipient, amount);
    }
}