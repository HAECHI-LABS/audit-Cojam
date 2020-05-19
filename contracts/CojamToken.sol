pragma solidity ^0.6.0;

import "./ERC20/ERC20Detailed.sol";
import "./ERC20/IERC20.sol";
import "./ERC20/ERC20.sol";
import "./library/Ownable.sol";
import "./library/UserManager.sol";
contract CojamToken is IERC20, ERC20, ERC20Detailed, Ownable, UserManager {

    event LockUser(address user);
    event UnlockUser(address user);

    constructor() ERC20Detailed("Cojam", "CT", 18) public {
        uint256 initialSupply = 5000000000 * (10 ** 18);

        _owner = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    /**
     * 관리자가 사용자의 차단 여부를 확인하는 함수
     * */
    function isLock(address target) external view returns(bool) {
        return _containsLockUser(target);
    }

    /**
     * 관리자가 사용자를 차단하는 함수
     * */
    function lock(address[] memory targets) public onlyOwner returns(bool[] memory) {
        bool[] memory results = new bool[](targets.length);

        for(uint256 ii=0; ii<targets.length; ii++){
            require(_owner != targets[ii], "can not lock owner");     // 관리자 주소가 컨트롤 되어서는 안 된다!
            results[ii] = _insertLockUser(targets[ii]);
            emit LockUser(targets[ii]);
        }

        return results;
    }

    /**
     * 관리자가 사용자를 차단해제 하는 함수
     * */
    function unlock(address[] memory targets) public onlyOwner returns(bool[] memory) {
        bool[] memory results = new bool[](targets.length);

        for(uint256 ii=0; ii<targets.length; ii++){
            require(_owner != targets[ii], "can not unlock owner");     // 관리자 주소가 컨트롤 되어서는 안 된다!
            results[ii] = _removeLockUser(targets[ii]);
            emit UnlockUser(targets[ii]);
        }

        return results;
    }
    /**
     * ERC20 기본 함수
    **/
    function transfer(address recipient, uint256 amount) external override isAllowedUser(msg.sender) returns (bool){
        return __transfer(recipient, amount);
    }

    function totalSupply() external override view returns (uint256){
        return __totalSupply();
    }

    function balanceOf(address account) external override view returns (uint256){
        return __balanceOf(account);
    }

    function allowance(address owner, address spender) external view override returns (uint256){
        return __allowance(owner, spender);
    }

    function approve(address spender, uint256 amount) external override isAllowedUser(msg.sender) returns (bool){
        return __approve(spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override isAllowedUser(sender) returns (bool){
        return __transferFrom(sender, recipient, amount);
    }
}
