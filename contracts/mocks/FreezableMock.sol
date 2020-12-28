pragma solidity 0.7.1;

import "../library/Freezable.sol";

contract FreezableMock is Freezable {

    constructor() Freezable() {}

    function whenNotFrozenMock(address target) whenNotFrozen(target) public {

    }
}
