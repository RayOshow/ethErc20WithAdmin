// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

// ERC20 declare
abstract contract ERC20Interface {
     
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address who) virtual public view returns (uint256);
    function transfer(address to, uint256 value) virtual public returns (bool);
    
    function approve(address spender, uint256 value) virtual public returns (bool);
    function transferFrom(address from, address to, uint256 value) virtual public returns (bool);
    function allowance(address owner, address spender) virtual public view returns (uint256);
    
    function increaseAllowance(address spender, uint256 addedValue) virtual public returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) virtual public returns (bool);
    

    // log 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SafeMath for log.
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
    
        uint256 c = a * b;
        require(c / a == b,"overflow occur!");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0,"div zero occur!");
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "minus sub occur!");
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a,"overflow occur!");
        return c;
    }
}


/**
 * Admin role contract.
 * 
 */
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

abstract contract Admin is AdminRole{
    
   ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Pause contract  
    bool private _paused = false;

    // Get pause stat
    function pauseState() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    modifier whenPaused() {
        require(_paused);
        _;
    }

    function pause() public onlyPauser whenNotPaused {
        _paused = true;
    }

    function unpause() public onlyPauser whenPaused {
        _paused = false;
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////// 
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Lock account 
    
    // lock account info
    mapping(address => bool) internal locks;
    
    // Lock up address
    function lock(address _owner) public onlyLocker returns (bool) {
        require(locks[_owner] == false);
        locks[_owner] = true;
        return true;
    }

    // Unlock address
    function unlock(address _owner) public onlyLocker returns (bool) {
        require(locks[_owner] == true);
        locks[_owner] = false;
        return true;
    }

    // Show locking status.
    function showLockState(address _owner) public view returns (bool) {
        return locks[_owner];
    }
    
    modifier whenNotLocked() {
        require(locks[msg.sender] == false); 
        _;
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Mint tokens     
    function mint(uint256 value) virtual public;

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // burn tokens      
    function burn(uint256 value) virtual public ;
    
}


// ERC20 functions
contract ERC20 is ERC20Interface, Admin {
    // Library
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    
    uint256 private _max_supply;
    uint256 private _totalSupply;

    constructor (uint256 max_supply)  {
        _max_supply = max_supply;
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // basic operations
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender)  public whenNotPaused override view returns (uint256) {
        return _allowed[owner][spender];
    }
    
    function transfer(address to, uint256 value) public whenNotPaused whenNotLocked override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////
        

    ////////////////////////////////////////////////////////////////////////////////////////////////////    
    // allow other to transfer 
    function approve(address spender, uint256 value) public whenNotPaused whenNotLocked override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused override returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused override returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused override returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    // Admin
    //////////////////////////////////////////////////////////////////////////////////////////////////////    
    // Mint 
    function mint(uint256 value) public override onlyMinter  {
        require(msg.sender != address(0));
        require(_max_supply > _totalSupply);
        _totalSupply = _totalSupply.add(value);
        _balances[msg.sender] = _balances[msg.sender].add(value);
        emit Transfer(address(0), msg.sender, value);
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    // Burn
    function burn(uint256 value) public override onlySuper  {

        require(msg.sender != address(0));
        
        _totalSupply = _totalSupply.sub(value);
        _balances[msg.sender] = _balances[msg.sender].sub(value);
    }
    //////////////////////////////////////////////////////////////////////////////////////////////    
    
}


// Token main contract
contract token is ERC20 {
    string public constant name = "rayee";
    string public constant symbol = "RAY";
    uint8 public constant decimals = 4;
    uint256 public constant initial_supply = 10000 * (10 ** uint256(decimals));
    uint256 public constant max_supply = 20000 * (10 ** uint256(decimals));    

    constructor() ERC20(max_supply){
        mint(initial_supply);
    }
}
