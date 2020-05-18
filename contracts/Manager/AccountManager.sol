pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract AccountManager {
    address internal _owner;
    address internal _cojamFeeAccount;
    address internal _charityFeeAccount;
    address internal _remainAccount;

    function _getAccounts() internal view returns(address, address, address, address){
        return(_owner, _cojamFeeAccount, _charityFeeAccount, _remainAccount);
    }

    function _setAccount(string memory key, address account) internal returns(bool) {
        if(keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked('cojamFeeAccount'))){
            _cojamFeeAccount = account;
        }
        else if(keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked('charityFeeAccount'))){
            _charityFeeAccount = account;
        }
        else if(keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked('remainAccount'))){
            _remainAccount = account;
        }
        else {
            return false;
        }

        return true;
    }

    event OwnershipTransferred(address deprecated, address updated);

    modifier onlyOwner(){
        require(_owner == msg.sender, "not owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner returns(bool) {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        return true;
    }
}
