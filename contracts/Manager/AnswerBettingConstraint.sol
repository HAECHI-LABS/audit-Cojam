pragma solidity ^0.6.0;

contract AnswerBettingConstraint {
    
    struct BettingConstraint {
        mapping(uint256 => uint256) keyIndexMap;
        uint256[] keyList;
    }
    
    mapping(uint256 => BettingConstraint) private _answerToBettingConstraint; // answerKey -> bettingKey ( 1 : N )
    
    function putBettingKey(uint256 answerKey, uint256 bettingKey) internal {
        require(0 < bettingKey, "e13");
        
        BettingConstraint storage c = _answerToBettingConstraint[answerKey];
        
        uint256 index = c.keyIndexMap[bettingKey];
        
        require(0 == index, "e19");
        
         // new entry
        c.keyList.push(bettingKey);
        uint256 keyListIndex = c.keyList.length - 1;
        c.keyIndexMap[bettingKey] = keyListIndex + 1;
    }
    
    function containsBettingKey(uint256 answerKey, uint256 bettingKey) internal view returns (bool) {
        BettingConstraint storage c = _answerToBettingConstraint[answerKey];
        
        return c.keyIndexMap[bettingKey] > 0;
    }

    function getAvailableBettingKeys(uint256 answerKey) internal view returns (uint256[] memory) {
        BettingConstraint storage c = _answerToBettingConstraint[answerKey];
        
        uint256 availableCount = 0;
        for(uint256 ii=0; ii<c.keyList.length; ii++){
            if(0 < c.keyList[ii]) {
                availableCount++;
            }
        }
        
        uint256[] memory list = new uint[](availableCount);
        uint256 index=0;
        for(uint256 ii=0; ii<c.keyList.length; ii++){
            if(0 < c.keyList[ii]){
                list[index++] = c.keyList[ii];
            }
        }
        
        return list;
    }
}