var Remittance = artifacts.require('./Remittance.sol');

contract('Remittance', function (accounts) {

  it('deploys', function () {
    return Remittance.deployed()
      .then(remit => remit.address != null);
  });


});
