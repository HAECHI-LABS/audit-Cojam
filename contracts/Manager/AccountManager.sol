pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract AccountManager {
    address internal _owner;
    address internal _cojamFeeAccount;
    address internal _charityFeeAccount;
    
    function _getAccounts() internal view returns(address, address, address){
        return(_owner, _cojamFeeAccount, _charityFeeAccount);
    }
    
    function _setAccount(string memory key, address account) internal returns(bool) {
        if(keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked('cojamFeeAccount'))){
            _cojamFeeAccount = account;
        }
        else if(keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked('charityFeeAccount'))){
            _charityFeeAccount = account;
        }
        else {
            return false;
        }
        
        return true;
    }
    
    modifier isOwner(){
        require(_owner == msg.sender, "sender is not owner");
        _;
    }
}