pragma solidity 0.5.7;

// ERC20 declare
contract IERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SafeMath
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a); // overflow check
    return c;
  }
 
}

/**
 * Admin role contract.
 * 
 * Add bit calculation for administer's role.
 * Owner has all privilege automatically.
 * And only super admin can add and remove new admin accounts.
 * 
 */
contract AdminRole {
    
    mapping (address => uint8) private _admin;
    
    uint8 internal _adminRoleSuper = 0x01;  // burn, lock , add account
    uint8 internal _adminRolePauser = 0x02; // pause    
    uint8 internal _adminRoleMinter = 0x04;   // mint   
    uint8 internal _adminRoleLocker = 0x08;   // mint
    uint8 internal _totalAuthoriesVal = _adminRoleSuper+_adminRolePauser+_adminRoleMinter+_adminRoleLocker;
    
    // using Roles for Roles.Role;
    // Roles.Role private _admin;
    constructor () internal {
        // constructor get total authorities
        _addAdmin(msg.sender, _totalAuthoriesVal);
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
 
    function _addAdmin(address account, uint8 authorities) internal {
        require(account != address(0));
        _admin[account] += authorities;
    }
    
    function addAdmin(address account, uint8 authorities) public onlySuper {
         require((authorities & _totalAuthoriesVal) > 0 && (authorities <= _totalAuthoriesVal));
        _addAdmin(account,authorities);
    }
    
    function removeAdmin() public onlySuper {
        _removeAdmin(msg.sender);
    }
    
    function _removeAdmin(address account) internal {
        require(account != address(0));
        _admin[account] = 0;
    }
    
}


// ERC20 functions
contract ERC20 is IERC20, AdminRole {
    // Library
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    
    uint256 private _max_supply;
    uint256 private _totalSupply;

    constructor (uint256 max_supply) public {
        _max_supply = max_supply;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));
        require(_max_supply > _totalSupply);
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    // Burn
    function burn(address from, uint256 value) public {
        _burn(from, value);
    }
    
    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
    }
    //////////////////////////////////////////////////////////////////////////////////////////////    
}

/**
 * Extension 
 * 
 * pause / mint / lock 
 * 
 */
contract ERC20Extension is ERC20 {
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    // Override public funcs
    function transfer(address to, uint256 value) public whenNotPaused whenNotLocked returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    // Mint
    
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
    //////////////////////////////////////////////////////////////////////////////////////////////    
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    // Pause 
    
    bool private _paused = false;

    // Get pause stat
    function paused() public view returns (bool) {
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
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    // Lock 
    
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
    //////////////////////////////////////////////////////////////////////////////////////////////
}


// Token main contract
contract token is ERC20Extension {
    string public constant name = "rayOshow";
    string public constant symbol = "ray";
    uint8 public constant decimals = 4;
    uint256 public constant initial_supply = 10000 * (10 ** uint256(decimals));
    uint256 public constant max_supply = 20000 * (10 ** uint256(decimals));    

    constructor () public ERC20(max_supply){
        _mint(msg.sender, initial_supply);
    }
}
