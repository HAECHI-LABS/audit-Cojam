pragma solidity ^0.6.0;

contract IteratableSet {
    mapping(uint256 => uint256) internal map;
    uint256[] internal keyList;

    function put(uint256 _key) public {
        require(0 < _key);
        
        uint256 index = map[_key];
        if(0 < index) {     // entry exists
            return;
        }
        else {  // new entry
            keyList.push(_key);
            uint256 keyListIndex = keyList.length - 1;
            map[_key] = keyListIndex + 1;
        }
    }

    function remove(uint256 _key) public {
        require(0 < _key);
        
        uint256 index = map[_key];
        require(index != 0); // entry not exist
        require(index <= keyList.length); // invalid index value
        
        // Move an last element of array into the vacated key slot.
        uint256 keyListIndex = index - 1;
        uint256 keyListLastIndex = keyList.length - 1;
        map[keyList[keyListLastIndex]] = keyListIndex + 1;
        keyList[keyListIndex] = keyList[keyListLastIndex];
        delete keyList[keyList.length - 1];
        delete map[_key];
    }
    
    function size() public view returns (uint) {
        return uint(keyList.length);
    }
    
    function contains(uint256 _key) public view returns (bool) {
        return map[_key] > 0;
    }

    function getAvailableKeys() public view returns (uint256[] memory) {
        
        uint256 availableCount = 0;
        for(uint256 ii=0; ii<keyList.length; ii++){
            if(0 < keyList[ii]) {
                availableCount++;
            }
        }
        
        uint256[] memory list = new uint[](availableCount);
        uint256 index=0;
        for(uint256 ii=0; ii<keyList.length; ii++){
            if(0 < keyList[ii]){
                list[index++] = keyList[ii];
            }
        }
        
        return list;
    }
}