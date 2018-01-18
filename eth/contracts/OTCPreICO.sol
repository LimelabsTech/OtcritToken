pragma solidity ^0.4.18;

import './commons/SafeMath.sol';
import './BaseICO.sol';

/**
 * @title OTCrit Pre-ICO smart contract.
 */
contract OTCPreICO is BaseICO {
  using SafeMath for uint;

  /// @dev 1e18 WEI == 1ETH == 5000 tokens
  uint public constant WEI_TOKEN_EXCHANGE_RATIO = 2e14;

  /// @dev 15% bonus at start of Pre-ICO
  uint public bonusPct = 15;

  function OTCPreICO(address icoToken_,
                     uint lowCapWei_,
                     uint hardCapWei_)
    public
  {
    require(icoToken_ != address(0));
    token = ICOToken(icoToken_);
    state = State.Inactive;
    lowCapWei = lowCapWei_;
    hardCapWei = hardCapWei_;
    // fire Crowdsale
  }

  /**
   * @dev Recalculate ICO state based on current block time.
   * Should be called periodically by ICO owner.
   */
  function touch() onlyOwner public {
    if (state != State.Active &&
        state != State.Suspended) {
      return;
    }
    if (bonusPct != 10 &&
       (block.timestamp - startAt >= 1 weeks)) {
      bonusPct = 10; // Decrease bonus to 10%
    }
    if (collectedWei >= hardCapWei) {
      state = State.Completed;
      endAt = block.timestamp;
      ICOCompleted(collectedWei);
    } else if (block.timestamp >= endAt) {
      if (collectedWei < lowCapWei) {
        state = State.NotCompleted;
        ICONotCompleted();
      } else {
        state = State.Completed;
        ICOCompleted(collectedWei);
      }
    }
  }

  /**
   * Perform investment in this ICO.
   * @param from_ Investor address.
   * @param wei_ Amount of invested weis
   * @return Amount of actually invested weis including bonuses.
   */
  function onInvestment(address from_, uint wei_) onlyOwner isActive public returns (uint) {
    require(wei_ != 0 &&
            from_ != address(0) &&
            token != address(0));
    // Apply bonuses
    uint nwei = bonusPct > 0 ? wei_.add((wei_ / 100).mul(bonusPct)) : wei_;
    require(nwei >= wei_);
    uint itokens = nwei / WEI_TOKEN_EXCHANGE_RATIO;
    // Transfer tokens to investor
    itokens = token.icoInvestment(from_, itokens);
    uint investedWei = itokens * WEI_TOKEN_EXCHANGE_RATIO;
    require(investedWei <= nwei);
    collectedWei = collectedWei.add(investedWei);
    ICOInvestment(investedWei);
    // Update ICO state
    touch();
    return investedWei;
  }

  // Disable direct payments
  function() external payable {
    revert();
  }
}