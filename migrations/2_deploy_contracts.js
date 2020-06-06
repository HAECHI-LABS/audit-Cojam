const Token = artifacts.require('CojamToken');
module.exports = function(deployer, network, account) {
    deployer.then( async ()=>{
      token = await deployer.deploy(Token);
    });
}
