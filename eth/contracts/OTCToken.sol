pragma solidity ^0.4.18;

import './commons/SafeMath.sol';
import './ICOToken.sol';

/**
 * @title ERC20 OTC Token https://otcrit.org
 */
contract OTCToken is ICOToken {
  using SafeMath for uint;

  /**
   * @dev Constructor
   * @param totalSupplyTokens_ Total amount of tokens supplied
   * @param reservedTeamTokens_ Number of tokens reserved for team
   * @param reservedPartnersTokens_ Number of tokens reserved for partners
   * @param reservedBountyTokens_ Number of tokens reserved for bounty participants
   * @param reservedOtherTokens_ Number of privately distributed tokens reserved for others
   */
  function OTCToken(uint totalSupplyTokens_,
                    uint reservedTeamTokens_,
                    uint reservedPartnersTokens_,
                    uint reservedBountyTokens_,
                    uint reservedOtherTokens_)
    ICOToken(totalSupplyTokens_)
    public
  {
    require(reservedTeamTokens_
            .add(reservedBountyTokens_)
            .add(reservedPartnersTokens_)
            .add(reservedOtherTokens_) <= totalSupply);
    reserved[RESERVED_TEAM_SIDE] = reservedTeamTokens_;
    reserved[RESERVED_BOUNTY_SIDE] = reservedBountyTokens_;
    reserved[RESERVED_PARTNERS_SIDE] = reservedPartnersTokens_;
    reserved[RESERVED_OTHERS_SIDE] = reservedOtherTokens_;
  }

  //---------------------------- OTC specific

  /// @dev Tokens for team members
  uint8 public RESERVED_TEAM_SIDE = 0x1;

  /// @dev Tokens for bounty participants
  uint8 public RESERVED_BOUNTY_SIDE = 0x2;

  /// @dev Tokens for OTCRIT partners
  uint8 public RESERVED_PARTNERS_SIDE = 0x4;

  /// @dev Other privately distributed tokens
  uint8 public RESERVED_OTHERS_SIDE = 0x8;

  /// @dev Token reservation mapping: key(RESERVED_X) => value(number of tokens)
  mapping(uint8 => uint) public reserved;

  /**
   * @dev Assign `amount_` of privately distributed tokens
   *      to someone identified with `to_` address.
   * @param to_   Tokens owner
   * @param side_ Group identifier of privately distributed tokens
   * @param amount_ Number of tokens distributed
   */
  function reserve(address to_, uint8 side_, uint amount_)
    onlyOwner
    public
  {
    require(to_ != address(0) && (side_ & 0xf) != 0);
    availableSupply.sub(amount_);
    // SafeMath will check reserved[side_] >= amount
    reserved[side_] = reserved[side_].sub(amount_);
    balances[to_] = balances[to_].add(amount_);
    ReservedICOTokensDistributed(to_, side_, amount_);
  }

  /// @dev Fired some tokens distributed to someone from team,bounty,parthners,others
  event ReservedICOTokensDistributed(address indexed to, uint8 side, uint amount);

  //---------------------------- Detailed ERC20 Token

  string public name = 'Otcrit token';

  string public symbol = 'OTC';

  uint8 public decimals = 18;

  mapping (address => mapping (address => uint)) private allowed;

  event Approval(address indexed owner, address indexed spender, uint value);

  /**
   * @dev Transfer tokens from one address to another
   * @param from_ address The address which you want to send tokens from
   * @param to_ address The address which you want to transfer to
   * @param value_ uint the amount of tokens to be transferred
   */
  function transferFrom(address from_, address to_, uint value_)
    whenNotLocked
    public
    returns (bool)
  {
    require(to_ != address(0) && value_ <= balances[from_] && value_ <= allowed[from_][msg.sender]);
    balances[from_] = balances[from_].sub(value_);
    balances[to_] = balances[to_].add(value_);
    allowed[from_][msg.sender] = allowed[from_][msg.sender].sub(value_);
    Transfer(from_, to_, value_);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering.
   *
   * To change the approve amount you first have to reduce the addresses
   * allowance to zero by calling `approve(spender_, 0)` if it is not
   * already 0 to mitigate the race condition described in:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * @param spender_ The address which will spend the funds.
   * @param value_ The amount of tokens to be spent.
   */
  function approve(address spender_, uint value_)
    whenNotLocked
    public
    returns (bool)
  {
    if (value_ != 0 && allowed[msg.sender][spender_] != 0) {
      revert();
    }
    allowed[msg.sender][spender_] = value_;
    Approval(msg.sender, spender_, value_);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner_ address The address which owns the funds.
   * @param spender_ address The address which will spend the funds.
   * @return A uint specifying the amount of tokens still available for the spender.
   */
  function allowance(address owner_, address spender_)
    view
    public
    returns (uint)
  {
    return allowed[owner_][spender_];
  }

  //---------------------------- !Standard ERC20 Token
}
