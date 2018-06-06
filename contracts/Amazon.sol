pragma solidity ^0.4.13;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Amazon {

  /* set owner */
  address owner;

  /* Add a variable called skuCount to track the most recent sku # */
  uint private skuCount;

  /* Add a line that creates a public mapping that maps the SKU (a number) to an Item.
     Call this mappings items
  */
  mapping (uint => Item) private items;

  /* Add a line that creates an enum called State. This should have 4 states
    ForSale
    Sold
    Shipped
    Received
  */
  enum State { ForSale, Sold, Shipped , Received }

  /* Create a struct named Item.
    Here, add a name, sku, price, state, seller, and buyer
    We've left you to figure out what the appropriate types are,
    if you need help you can ask around :)
  */
  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address seller;
    address buyer;
    // @note - so we can check if this item exists
    bool exists;
  }

  /* Create 4 events with the same name as each possible State (see above)
    Each event should accept one argument, the sku*/
    event ForSale (uint sku);
    event Sold (uint sku);
    event Shipped (uint sku);
    event Received (uint sku);

  modifier isOwner (address _owner) { require(msg.sender == _owner); _;}
  modifier paidEnough(uint _value) { require(msg.value >= _value); _;}
  modifier checkValue(uint _amount) {
    //refund them after pay for item (why it is before, _ checks for logic fo func)
    _;
    if (msg.value > _amount) {
        // @note - no need for SafeMath, cannot underflow
        uint amountToRefund = msg.value - _amount;
        msg.sender.transfer(amountToRefund);
    }
  }

  modifier itemExists(uint _sku) { require(items[_sku].exists == true); _; }
  /* For each of the following modifiers, use what you learned about modifiers
   to give them functionality. For example, the forSale modifier should require
   that the item with the given sku has the state ForSale. */
  modifier forSale (uint _sku) { require(State.ForSale == items[_sku].state); _ ;}
  modifier sold (uint _sku) { require(State.Sold == items[_sku].state); _ ;}
  modifier shipped (uint _sku) { require(State.Shipped == items[_sku].state); _ ;}
  modifier received (uint _sku) { require(State.Received == items[_sku].state); _ ;}

  modifier isBuyer(uint _sku) { require(items[_sku].buyer == msg.sender); _; }

  function Amazon() {
    /* Here, set the owner as the person who instantiated the contract
       and set your skuCount to 0. */
       owner = msg.sender;
  }

  function addItem(string _name, uint _price) {
    uint index = skuCount;
    items[index] = Item(_name, skuCount, _price, State.ForSale, msg.sender, msg.sender, true);
    skuCount = SafeMath.add(index, 1);
    emit ForSale(index);
  }

  /* Add a keyword so the function can be paid. This function should transfer money
    to the seller, set the buyer as the person who called this transaction, and set the state
    to Sold. Be careful, this function should use 3 modifiers to check if the item is for sale,
    if the buyer paid enough, and check the value after the function is called to make sure the buyer is
    refunded any excess ether sent. Remember to call the event associated with this function!*/
  function buyItem(uint sku)
    itemExists(sku)
    forSale(sku)
    paidEnough(items[sku].price)
    checkValue(items[sku].price)
    payable
  {
    items[sku].buyer = msg.sender;
    items[sku].state = State.Sold;
    items[sku].seller.transfer(items[sku].price);
    emit Sold(sku);
  }

  /* Add 2 modifiers to check if the item is sold already, and that the person calling this function
  is the seller. Change the state of the item to shipped. Remember to call the event associated with this function!*/
  function shipItem(uint sku)
    isOwner(items[sku].seller)
    sold(sku)
  {
    items[sku].state = State.Shipped;
    emit Shipped(sku);
  }

  /* Add 2 modifiers to check if the item is shipped already, and that the person calling this function
  is the buyer. Change the state of the item to received. Remember to call the event associated with this function!*/
  function receiveItem(uint sku)
    shipped(sku)
    isBuyer(sku)
  {
    items[sku].state = State.Received;
    emit Received(sku);
  }

  /* We have this function completed so we can run tests, just ignore it :) */
  function fetchLast() view returns (string name, uint sku, uint price, uint state, address seller, address buyer) {
    uint idx = skuCount;
    if (idx > 0) {
      idx = skuCount - 1;
    }
    name = items[idx].name;
    sku = items[idx].sku;
    price = items[idx].price;
    state = uint(items[idx].state);
    seller = items[idx].seller;
    buyer = items[idx].buyer;
    return (name, sku, price, state, seller, buyer);
  }

}
