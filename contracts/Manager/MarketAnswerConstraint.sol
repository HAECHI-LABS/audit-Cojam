pragma solidity ^0.6.0;

contract MarketAnswerConstraint {
    
    struct AnswerConstraint {
        mapping(uint256 => uint256) keyIndexMap;
        uint256[] keyList;
    }
    
    mapping(uint256 => AnswerConstraint) private _marketToAnswerConstraint; // marketKey -> answerKey ( 1 : N )
    
    function putAnswerKey(uint256 marketKey, uint256 answerKey) internal{
        require(0 < answerKey, "e13");
        
        AnswerConstraint storage c = _marketToAnswerConstraint[marketKey];
        
        uint256 index = c.keyIndexMap[answerKey];
        
        require(0 == index, "e19");
        
         // new entry
        c.keyList.push(answerKey);
        uint256 keyListIndex = c.keyList.length - 1;
        c.keyIndexMap[answerKey] = keyListIndex + 1;
    }
    
    function containsAnswerKey(uint256 marketKey, uint256 answerKey) internal view returns (bool) {
        AnswerConstraint storage c = _marketToAnswerConstraint[marketKey];
        
        return c.keyIndexMap[answerKey] > 0;
    }

    function getAvailableAnswerKeys(uint256 marketKey) internal view returns (uint256[] memory) {
        AnswerConstraint storage c = _marketToAnswerConstraint[marketKey];
        
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