pragma solidity ^0.4.11;



import "./StandardToken.sol";
import "./Pausable.sol";

/**
 * @title Weibei ICO.
 *
 */
contract WeibeiSale is StandardToken, Pausable {

  using SafeMath for uint;

  struct Backer {
    uint weiReceived;
    uint coinSent;
  }
  mapping(address => Backer) public backers;

  /* Minimum ETH allowed to invest */
  uint public constant MIN_INVEST_ETHER = 50 finney;

  string public constant name = "Weibei";
  string public constant symbol = "WBC";
  uint public constant decimals = 0;


  /* Max WBC tokens to be sold during Pre-ICO and regular ICO */
  uint public maxCap;
  /* Price to be used during Pre-ICO and regular ICO (ie. number of WBC tokens per 1 ETH) */
  uint public price;

  /* Where ETH will be stored */
  address public etherBank;
  /* Where initial supply WBC tokens will be stored */
  address public tokenBank;

  /* Number of Ether received (in Wei unit) */
  uint public totalEtherWeiReceived;
  /* Number of Ether received (in Ether unit) */
  uint public totalEtherReceived;
  /* Number of Weibei sent to Ether contributors */
  uint public totalWeibeiSent;

  bool public isSaleOn;

  /*
   * Event
  */
  event LogWeibeiSale(address addr, uint receivedEth, uint weibeiSent);

  // Constructor
  function WeibeiSale(address _etherBank, address _tokenBank, uint _totalSupply, uint _maxCap, uint _price) {
      etherBank = _etherBank;
      tokenBank = _tokenBank;
      totalSupply = _totalSupply; // 2 billion.
      maxCap = _maxCap; // Pre-ICO: 60 million. ICO: 600 million.
      price = _price; // To be set at the time of ICO.
      balances[tokenBank] = totalSupply;
  }

  /*
   * To start ICO / Pre-ICO
   */
  function startSale() onlyOwner {
    isSaleOn = true;
  }

  /*
   * To end ICO / Pre-ICO
   */
  function endSale() onlyOwner {
    isSaleOn = false;
  }

  /**
   * Receives ether and sends the appropriate number of WBC tokens to the
   * msg.sender.
   */
  function () stopInEmergency payable {
    if (!isSaleOn) {
      throw;
    }
    if (totalWeibeiSent > maxCap) {
      throw;
    }
    if (msg.value < MIN_INVEST_ETHER) {
      throw;
    }
    sale(msg.sender);
  }

  /**
   * Receives ETH and sends WBC to the specified address.
   * @param recipient The address which will recieve the new tokens.
   */
  function sale(address recipient) internal {

    uint tokens = msg.value.mul(price).div(1 ether);

    balances[recipient] = balances[recipient].add(tokens);
    balances[tokenBank] = balances[tokenBank].sub(tokens);

    if (!etherBank.send(msg.value)) {
      throw;
    }

    Backer backer = backers[recipient];
    backer.coinSent = backer.coinSent.add(tokens);
    backer.weiReceived = backer.weiReceived.add(msg.value);

    totalEtherWeiReceived = totalEtherWeiReceived.add(msg.value);
    totalEtherReceived = totalEtherWeiReceived.div(1 ether);
    totalWeibeiSent = totalWeibeiSent.add(tokens);

    // Logs event.
    LogWeibeiSale(recipient, msg.value, tokens);
  }

  /**
   * Allow to change the ether bank address in the case of emergency.
   */
  function setEtherBank(address _addr) onlyOwner public {
    if (_addr == address(0)) {
      throw;
    }
    etherBank = _addr;
  }

  /**
   * Allow to change the token bank address in the case of emergency.
   */
  function setTokenBank(address _addr) onlyOwner public {
    if (_addr == address(0)) {
      throw;
    }
    tokenBank = _addr;
  }

  /**
   * Allow to adjust maxCap after Pre-ICO, for regular ICO.
   */
  function setMaxCap(uint _newmax) onlyOwner public {
    maxCap = _newmax;
  }

  /*
   * Allow to adjust price after Pre-ICO, for regular ICO.
  */
  function setPrice(uint _price) onlyOwner public {
    price = _price;
  }

}
