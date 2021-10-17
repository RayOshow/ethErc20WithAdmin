
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract AdminRole {
    
    mapping (address => uint8) private _admin;
    
    uint8 internal _adminRoleSuper = 0x01;  // burn, lock , add account
    uint8 internal _adminRolePauser = 0x02; // pause    
    uint8 internal _adminRoleMinter = 0x04;   // mint   
    uint8 internal _adminRoleLocker = 0x08;   // pause
    uint8 internal _totalAuthoriesVal = _adminRoleSuper+_adminRolePauser+_adminRoleMinter+_adminRoleLocker;
    
    // using Roles for Roles.Role;
    // Roles.Role private _admin;
    constructor ()  {
        // constructor get total authorities

        _admin[msg.sender] += _totalAuthoriesVal;
    }
    
    modifier onlySuper() {
        require((_admin[msg.sender] & _adminRoleSuper) > 0 );
        _;
    }
    
    modifier onlyPauser() {
        require((_admin[msg.sender] & _adminRolePauser) > 0);
        _;
    }
    
    modifier onlyMinter() {
        require((_admin[msg.sender] & _adminRoleMinter) > 0);        
        _;
    }
    
    modifier onlyLocker() {
        require((_admin[msg.sender] & _adminRoleLocker) > 0);        
        _;
    }
 
  
    function addAdmin(address account, uint8 authorities) public onlySuper {
        require(account != address(0));
        require((authorities & _totalAuthoriesVal) > 0 && (authorities <= _totalAuthoriesVal));
        _admin[account] += authorities;
    }
    
    function removeAdmin() public onlySuper {
         require(msg.sender != address(0));
        _admin[msg.sender] = 0;
    }

}
