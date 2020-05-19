pragma solidity ^0.6.0;

import "./GSN/Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract ERC20 is Context {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function __totalSupply() internal view returns (uint256) {
        return _totalSupply;
    }

    function __balanceOf(address account) internal view returns (uint256) {
        return _balances[account];
    }

    function __transfer(address recipient, uint256 amount) internal returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function __allowance(address owner, address spender) internal view returns (uint256) {
        return _allowances[owner][spender];
    }

    function __approve(address spender, uint256 amount) internal returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function __transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20:40"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20:44");
        require(recipient != address(0), "ERC20:46");
        _balances[sender] = _balances[sender].sub(amount, "ERC20:50");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20:56");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20:66");
        require(spender != address(0), "ERC20:67");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
