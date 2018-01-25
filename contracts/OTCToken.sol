pragma solidity ^0.4.18;

import './commons/SafeMath.sol';
import './base/BaseICOToken.sol';

/**
 * @title ERC20 OTC Token https://otcrit.org
 */
contract OTCToken is BaseICOToken {
  using SafeMath for uint;

  string public constant name = 'Otcrit token';

  string public constant symbol = 'OTC';

  uint8 public constant decimals = 18;

  uint internal constant ONE_TOKEN = 1e18;


  /// @dev Fired some tokens distributed to someone from team,bounty,parthners,others
  event ReservedTokensDistributed(address indexed to, uint8 group, uint amount);

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
    BaseICOToken(totalSupplyTokens_ * ONE_TOKEN) public {
    require(availableSupply == totalSupply);
    availableSupply = availableSupply
                        .sub(reservedTeamTokens_ * ONE_TOKEN)
                        .sub(reservedBountyTokens_ * ONE_TOKEN)
                        .sub(reservedPartnersTokens_ * ONE_TOKEN)
                        .sub(reservedOtherTokens_ * ONE_TOKEN);
    reserved[RESERVED_TEAM_SIDE] = reservedTeamTokens_ * ONE_TOKEN;
    reserved[RESERVED_BOUNTY_SIDE] = reservedBountyTokens_ * ONE_TOKEN;
    reserved[RESERVED_PARTNERS_SIDE] = reservedPartnersTokens_ * ONE_TOKEN;
    reserved[RESERVED_OTHERS_SIDE] = reservedOtherTokens_ * ONE_TOKEN;
  }

  // Disable direct payments
  function() external payable {
    revert();
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
   * @dev Get recerved tokens for specific side
   */
  function getReservedTokens(uint8 group_) view public returns (uint) {
    return reserved[group_];
  }

  /**
   * @dev Assign `amount_` of privately distributed tokens
   *      to someone identified with `to_` address.
   * @param to_   Tokens owner
   * @param group_ Group identifier of privately distributed tokens
   * @param amount_ Number of tokens distributed with decimals part
   */
  function assignReserved(address to_, uint8 group_, uint amount_) onlyOwner public {
    require(to_ != address(0) && (group_ & 0xf) != 0);
    // SafeMath will check reserved[group_] >= amount
    reserved[group_] = reserved[group_].sub(amount_);
    balances[to_] = balances[to_].add(amount_);
    ReservedTokensDistributed(to_, group_, amount_);
  }
}
