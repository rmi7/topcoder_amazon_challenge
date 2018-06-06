pragma solidity ^0.4.13;

contract AmazonOriginal {

  /* set owner */
  address owner;

  /* Add a variable called skuCount to track the most recent sku # */
  uint private skuCount;

  /* Add a line that creates a public mapping that maps the SKU (a number) to an Item.
     Call this mappings items
  */
  // @audit - should be items
  mapping (uint => Item) private itms;

  /* Add a line that creates an enum called State. This should have 4 states
    ForSale
    Sold
    Shipped
    Received
  */
  // @audit - should be Shipped, Received
  enum State { ForSale, Sold, Ship, Receive }

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
  }

  /* Create 4 events with the same name as each possible State (see above)
    Each event should accept one argument, the sku*/
    event ForSale (uint sku);
    event Sold (uint sku);
    event Shipped (uint sku);
    event Received (uint sku);

  modifier isOwner (address _owner) { require(msg.sender == _owner); _;}
  // @audit - should be <= since paying exactly item.price should be allowed
  modifier paidEnough(uint _value) { require(_value > msg.value); _;}
  modifier checkValue(uint _amount) {
    //refund them after pay for item (why it is before, _ checks for logic fo func)
    _;
    // @audit - should be msg.value > _amount
    if (msg.value < _amount) {
        // @audit - uint amountToRefund = msg.value - _amount
        //          no need for SafeMath, can NOT underflow
        uint amountToRefund = msg.value + _amount;
        // @audit - there is no skuCount here, just use msg.sender.transfer(amountToRefund)
        items[skuCount].buyer.transfer(amountToRefund);
    }
  }

  /* For each of the following modifiers, use what you learned about modifiers
   to give them functionality. For example, the forSale modifier should require
   that the item with the given sku has the state ForSale. */
  modifier forSale (uint _sku) { require(State.ForSale == items[_sku].state); _ ;}
  modifier sold (uint _sku) { require(State.Sold == items[_sku].state); _ ;}
  modifier shipped (uint _sku) { require(State.Shipped == items[_sku].state); _ ;}
  modifier received (uint _sku) { require(State.Received == items[_sku].state); _ ;}


  function Amazon() {
    /* Here, set the owner as the person who instantiated the contract
       and set your skuCount to 0. */
       owner = msg.sender;
  }

  function addItem(string _name, uint _price) {
    // @audit - wouldn't we want to make sure _price > 0
    // @audit - prepend 'emit '
    // @audit - emit at end of function
    ForSale(skuCount);
    // @audit - init buyer to address(0)
    // @audit - this is not javascript, should be: Item(_name, skuCount, _price, State.ForSale, msg.sender, msg.sender);
    items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: msg.sender});
    // @audit - OVERFLOW POSSIBLE, use SafeMath to defende against overflow
    skuCount = skuCount + 1;
  }

  /* Add a keyword so the function can be paid. This function should transfer money
    to the seller, set the buyer as the person who called this transaction, and set the state
    to Sold. Be careful, this function should use 3 modifiers to check if the item is for sale,
    if the buyer paid enough, and check the value after the function is called to make sure the buyer is
    refunded any excess ether sent. Remember to call the event associated with this function!*/
  // @audit - missing check if sku exists, need to add 'bool exists' prop to Item to be able to do
  //          require(items[sku].exists == true)
  // @audit - prefer pull of payment by seller instead of pushing
  // @audit - missing modifier forSale(sku)
  // @audit - missing checkValue(items[sku].price)
  // @audit - missing paidEnough(items[sku].price)
  function buyItem(uint sku) payable {
    // @audit - check-effects-interactions --> transfer should happen after state updates
    // @audit - since we refund excess ETH sent to this function, we should transfer(items[sku].price)
    items[sku].seller.transfer(msg.value);
    items[sku].buyer = msg.sender;
    items[sku].state = State.Sold;
    // @audit - prepend 'emit '
    Sold(sku);
  }

  /* Add 2 modifiers to check if the item is sold already, and that the person calling this function
  is the seller. Change the state of the item to shipped. Remember to call the event associated with this function!*/
  function shipItem(uint sku)
  isOwner(items[sku].seller)
  sold(sku) {
    items[sku].state = State.Shipped;
    // @audit - prepend 'emit '
    Shipped(sku);
  }

  /* Add 2 modifiers to check if the item is shipped already, and that the person calling this function
  is the buyer. Change the state of the item to received. Remember to call the event associated with this function!*/
  // @audit - missing require(msg.sender == items[sku].buyer)
  // @audit - missing shipped(sku)
  function receiveItem(uint sku) {
    // @audit - prepend 'emit '
    // @audit - emit at end of function
    Received(sku);
    items[sku].state = State.Received;
  }

  /* We have this function completed so we can run tests, just ignore it :) */
  // @audit - add 'view' function visiblity
  function fetchLast() returns (string name, uint sku, uint price, uint state, address seller, address buyer) {
    // @audit - last item will be at index skuCount-1
    name = items[skuCount].name;
    sku = items[skuCount].sku;
    price = items[skuCount].price;
    state = uint(items[skuCount].state);
    seller = items[skuCount].seller;
    buyer = items[skuCount].buyer;
    return (name, sku, price, state, seller, buyer);
  }

}
