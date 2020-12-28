pragma solidity 0.7.1;

import "./kip7/KIP7Lockable.sol";
import "./kip7/KIP7Burnable.sol";
import "./library/Pausable.sol";
import "./library/Freezable.sol";

contract CojamToken is
    KIP7Lockable,
    KIP7Burnable,
    Freezable
{
    using SafeMath for uint256;
    string constant private _name = "Cojam";
    string constant private _symbol = "CT";
    uint8 constant private _decimals = 18;
    uint256 constant private _initial_supply = 5_000_000_000;

    constructor() Ownable() {
        _mint(msg.sender, _initial_supply * (10**uint256(_decimals)));
    }

    function transfer(address to, uint256 amount)
        override
        external
        whenNotFrozen(msg.sender)
        whenNotPaused
        checkLock(msg.sender, amount)
        returns (bool success)
    {
        require(
            to != address(0),
            "CT/transfer : Should not send to zero address"
        );
        _transfer(msg.sender, to, amount);
        success = true;
    }

    function transferFrom(address from, address to, uint256 amount)
        override
        external
        whenNotFrozen(from)
        whenNotPaused
        checkLock(from, amount)
        returns (bool success)
    {
        require(
            to != address(0),
            "CT/transferFrom : Should not send to zero address"
        );
        _transfer(from, to, amount);
        _approve(
            from,
            msg.sender,
            _allowances[from][msg.sender].sub(
                amount,
                "CT/transferFrom : Cannot send more than allowance"
            )
        );
        success = true;
    }

    function approve(address spender, uint256 amount)
        override
        external
        returns (bool success)
    {
        require(
            spender != address(0),
            "CT/approve : Should not approve zero address"
        );
        _approve(msg.sender, spender, amount);
        success = true;
    }

    function name() override external pure returns (string memory tokenName) {
        tokenName = _name;
    }

    function symbol() override external pure returns (string memory tokenSymbol) {
        tokenSymbol = _symbol;
    }

    function decimals() override external pure returns (uint8 tokenDecimals) {
        tokenDecimals = _decimals;
    }
}
