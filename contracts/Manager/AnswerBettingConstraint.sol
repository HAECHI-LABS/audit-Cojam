pragma solidity ^0.6.0;

contract AnswerBettingConstraint {
    
    struct BettingConstraint {
        mapping(uint256 => uint256) keyIndexMap;
        uint256[] keyList;
    }
    
    mapping(uint256 => BettingConstraint) private _answerToBettingConstraint; // bettingKey -> bettingKey ( 1 : N )
    
    function putBettingKey(uint256 answerKey, uint256 bettingKey) internal {
        require(0 < bettingKey, "betting key must be greater than zero");
        
        BettingConstraint storage c = _answerToBettingConstraint[answerKey];
        
        uint256 index = c.keyIndexMap[bettingKey];
        
        require(0 == index, "entry must be null");
        
         // new entry
        c.keyList.push(bettingKey);
        uint256 keyListIndex = c.keyList.length - 1;
        c.keyIndexMap[bettingKey] = keyListIndex + 1;
    }

    function removeBettingKey(uint256 answerKey, uint256 bettingKey) internal {
        require(0 < bettingKey, "betting key must be greater than zero");
        
        BettingConstraint storage c = _answerToBettingConstraint[answerKey];
        
        uint256 index = c.keyIndexMap[bettingKey];
        require(index != 0, "can not found betting key"); // entry not exist
        require(index <= c.keyList.length, "invalid index value"); // invalid index value
        
        // Move an last element of array into the vacated key slot.
        uint256 keyListIndex = index - 1;
        uint256 keyListLastIndex = c.keyList.length - 1;
        c.keyIndexMap[c.keyList[keyListLastIndex]] = keyListIndex + 1;
        c.keyList[keyListIndex] = c.keyList[keyListLastIndex];
        delete c.keyList[c.keyList.length - 1];
        delete c.keyIndexMap[bettingKey];
    }
    
    function bettingKeyListSize(uint256 answerKey) internal view returns (uint) {
        BettingConstraint storage c = _answerToBettingConstraint[answerKey];
        
        return uint(c.keyList.length);
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