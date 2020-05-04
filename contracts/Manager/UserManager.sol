pragma solidity ^0.6.0;

contract UserManager {
    struct AddressSet {
        mapping(address => bool) flags;
    }
    
    AddressSet internal lockedUsers = AddressSet();
   
    function _insertLockUser(address value)
          internal
          returns (bool)
      {
          if (lockedUsers.flags[value])
              return false; // already there
          lockedUsers.flags[value] = true;
          return true;
      }
    
      function _removeLockUser(address value)
          internal
          returns (bool)
      {
          if (!lockedUsers.flags[value])
              return false; // not there
          lockedUsers.flags[value] = false;
          return true;
      }
    
      function _containsLockUser(address value)
          internal
          view
          returns (bool)
      {
          return lockedUsers.flags[value];
      }
      
    modifier isAllowedUser(address user) {
        require(_containsLockUser(user) == false, "sender is locked user");    // 차단된 사용자가 아니어야 한다!
        _;
    }
}