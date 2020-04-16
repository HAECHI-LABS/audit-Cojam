pragma solidity ^0.6.0;

contract AddressSet {
  mapping(address => bool) flags;
  
  function insert(address value)
      public
      returns (bool)
  {
      if (flags[value])
          return false; // already there
      flags[value] = true;
      return true;
  }

  function remove(address value)
      public
      returns (bool)
  {
      if (!flags[value])
          return false; // not there
      flags[value] = false;
      return true;
  }

  function contains(address value)
      public
      view
      returns (bool)
  {
      return flags[value];
  }
}
