const Amazon = artifacts.require('Amazon');

const convertItemToObject = arr => ({
  name: arr[0],
  sku: arr[1].toString(),
  price: arr[2].toString(),
  state: arr[3].toString(),
  seller: arr[4],
  buyer: arr[5],
})

contract('Amazon', (accounts) => {
  let instance;
  const [owner, user1, user2, user3] = accounts;
  beforeEach(async () => {
    instance = await Amazon.new();
  });
  describe('addItem(string _name, uint _price)', () => {
    describe('ether sent', () => {
      it('can not send ETH', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        try {
          await instance.addItem(itemName, itemPrice, { from: user1, value: itemPrice });
        } catch (err) {
          return;
        }
        assert(false, 'should have thrown');
      });
    });
    describe('States', () => {
      it('successfully added item has state ForSale', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const lastItem = await instance.fetchLast();
        expect(lastItem).to.be.an('array').with.lengthOf(6);
        const item = convertItemToObject(lastItem);
        expect(item.name).to.equal(itemName);
        expect(item.sku).to.equal('0');
        expect(item.price).to.equal(itemPrice.toString());
        expect(item.state).to.equal('0');
        expect(item.seller).to.equal(user1);
        expect(item.buyer).to.equal(user1);
      });
    });
  });
  describe('buyItem(uint sku)', () => {
    describe('ether sent', () => {
      it('can not buy when sending less ETH than item.price', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        try {
          await instance.buyItem(item.sku, { from: user2, value: itemPrice.sub(1) });
        } catch (err) {
          return;
        }
        assert(false, 'should have thrown');
      });
      it('can buy when sending exact item.price amount of ETH', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        const updatedItem = convertItemToObject(await instance.fetchLast());
        expect(updatedItem.state).to.equal('1');
      });
      it('get refunded ETH if I sent more than item.price', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        const balanceBefore = await web3.eth.getBalance(user2);
        await instance.buyItem(item.sku, { from: user2, value: web3.toWei(2) });
        const updatedItem = convertItemToObject(await instance.fetchLast());
        expect(updatedItem.state).to.equal('1');
        const balanceAfter = await web3.eth.getBalance(user2);

        // item price = 1 ETH
        // we send = 2 ETH
        // gas cost = X ETH
        // our balance afterwards should have decreased by LESS THAN 2 ETH,
        // for the refund to have happened successfully
        expect(balanceBefore.sub(balanceAfter).lt(web3.toWei(2))).to.equal(true);
      });
    });
    describe('States', () => {
      it('can buy item in state ForSale', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        const updatedItem = convertItemToObject(await instance.fetchLast());
        expect(updatedItem.state).to.equal('1');
      });
      it('can not buy item in state Sold', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        try {
          await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        } catch (err) {
          return;
        }
        assert(false, 'should have thrown');
      });
      it('can not buy item in state Ship', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        await instance.shipItem(item.sku, { from: user1 });
        try {
          await instance.buyItem(item.sku, { from: user2, value: itemPrice});
        } catch (err) {
          return;
        }
        assert(false, 'should have thrown');
      });
      it('can not buy item in state Receive', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        await instance.shipItem(item.sku, { from: user1 });
        await instance.receiveItem(item.sku, { from: user2 });
        try {
          await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        } catch (err) {
          return;
        }
        assert(false, 'should have thrown');
      });
    });
  });
  describe('shipItem(uint sku)', () => {
    describe('ether sent', () => {
      it('can not send ETH', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        try {
          await instance.shipItem(item.sku, { from: user1, value: itemPrice });
        } catch (err) {
          return;
        }
        assert(false, 'should have thrown');
      });
    });
    describe('States', () => {
      it('can not ship item in state ForSale', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        try {
          await instance.shipItem(item.sku, { from: user1 });
        } catch (err) {
          return;
        }
        assert(false, 'should have thrown');
      });
      it('can ship item in state Sold', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        await instance.shipItem(item.sku, { from: user1 });
        const updatedItem = convertItemToObject(await instance.fetchLast());
        expect(updatedItem.state).to.equal('2');
      });
      it('can not ship item in state Ship', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        await instance.shipItem(item.sku, { from: user1 });
        try {
          await instance.shipItem(item.sku, { from: user1 });
        } catch (err) {
          return;
        }
        assert(false, 'should have thrown');
      });
      it('can not ship item in state Receive', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        await instance.shipItem(item.sku, { from: user1 });
        await instance.receiveItem(item.sku, { from: user2 });
        try {
          await instance.shipItem(item.sku, { from: user1 });
        } catch (err) {
          return;
        }
        assert(false, 'should have thrown');
      });
    });
  });
  describe('receiveItem(uint sku)', () => {
    describe('ether sent', () => {
      it('can not send ETH', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        await instance.shipItem(item.sku, { from: user1 });
        try {
          await instance.receiveItem(item.sku, { from: user2, value: itemPrice });
        } catch (err) {
          return;
        }
        assert(false, 'should have thrown');
      });
    });
    describe('States', () => {
      it('can not receive item in state ForSale', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        try {
          await instance.receiveItem(item.sku, { from: user2 });
        } catch (err) {
          return;
        }
        assert(false, 'should have thrown');
      });
      it('can not receive item in state Sold', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        try {
          await instance.receiveItem(item.sku, { from: user2 });
        } catch (err) {
          return;
        }
        assert(false, 'should have thrown');
      });
      it('can receive item in state Ship', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        await instance.shipItem(item.sku, { from: user1 });
        await instance.receiveItem(item.sku, { from: user2 });
        const updatedItem = convertItemToObject(await instance.fetchLast());
        expect(updatedItem.state).to.equal('3');
      });
      it('can not receive item in state Receive', async () => {
        const itemName = 'my first item';
        const itemPrice = web3.toWei(1);
        await instance.addItem(itemName, itemPrice, { from: user1 });
        const item = convertItemToObject(await instance.fetchLast());
        await instance.buyItem(item.sku, { from: user2, value: itemPrice });
        await instance.shipItem(item.sku, { from: user1 });
        await instance.receiveItem(item.sku, { from: user2 });
        try {
          await instance.receiveItem(item.sku, { from: user2 });
        } catch (err) {
          return;
        }
        assert(false, 'should have thrown');
      });
    });
  });
});
