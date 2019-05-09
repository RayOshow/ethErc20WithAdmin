pragma solidity 0.5.7;

/**
 *  ETH ERC20 contract with managin admin authorities.
 Author : Ray OShow
 brief: 
    It referred from azi's code based on open zeppin (https://github.com/sikyaNQ/final-token/blob/master/Final)
    I mergerd all of authorities to  one contract to reduce storage and gas.
    And I have been trying to minimalize source code for easily reading.
 */
 
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
  event Burn(address indexed burner, uint256 value);
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
    
    uint8 public _adminRoleSuper = 0x01;  // burn, lock , add account
    uint8 public _adminRolePauser = 0x02; // pause    
    uint8 public _adminRoleMint = 0x04;   // mint   
    uint8 public _totalAuthoriesVal = _adminRoleSuper+_adminRolePauser+_adminRoleMint;
    
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
        require((_admin[msg.sender] & _adminRoleMint) > 0);        
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
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping(address => bool) internal locks;
    mapping (address => mapping (address => uint256)) private _allowed;
    
    uint256 public Max_supply = 10000000000 * (10 **18);
    uint256 private _totalSupply;

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
        require(locks[msg.sender] == false);
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
        require(Max_supply > _totalSupply);
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }
    
    function burn(address from, uint256 value) public {
        _burn(from, value);
    }
    
    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    
    function lock(address _owner) public onlySuper returns (bool) {
        require(locks[_owner] == false);
        locks[_owner] = true;
        return true;
    }

    function unlock(address _owner) public onlySuper returns (bool) {
        require(locks[_owner] == true);
        locks[_owner] = false;
        return true;
    }

    function showLockState(address _owner) public view returns (bool) {
        return locks[_owner];
    }
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
  
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
  }
    
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
  }
}


contract ERC20Pausable is ERC20 {
    
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
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
    
    event Paused(address account);
    event Unpaused(address account);

    // bool private _paused;
    bool public _paused;

    constructor () internal {
        _paused = false;
    }
    
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
        emit Paused(msg.sender);
    }

    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


contract ERC20Mintable is ERC20 {
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}


// Token main contract
contract token is ERC20, ERC20Pausable, ERC20Mintable {
    
    string public constant name = "rayOshow";
    string public constant symbol = "ray";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 100000 * (10 ** uint256(decimals));

    constructor () public {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}
