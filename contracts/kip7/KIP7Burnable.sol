pragma solidity 0.7.1;

import "./KIP7.sol";
import "../library/Pausable.sol";

abstract contract KIP7Burnable is KIP7, Pausable {
    using SafeMath for uint256;

    event Burn(address indexed burned, uint256 amount);

    function burn(uint256 amount)
        external
        whenNotPaused
        returns (bool success)
    {
        success = _burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
        success = true;
    }

    function burnFrom(address burned, uint256 amount)
        external
        whenNotPaused
        returns (bool success)
    {
        _burn(burned, amount);
        emit Burn(burned, amount);
        success = _approve(
            burned,
            msg.sender,
            _allowances[burned][msg.sender].sub(
                amount,
                "KIP7Burnable/burnFrom : Cannot burn more than allowance"
            )
        );
    }
}
