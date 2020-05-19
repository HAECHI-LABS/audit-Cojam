# Cojam Contract Repository

### Requirement

- node.js
- node-gyp


### Dev Environment Setting

##### clone code

```bash
$ git clone git@github.com:haechi-labs/audit-cojam
```

##### install packages

```bash
$ cd audit-cojam
$ npm install
```


### Deployment

#### Method 1. Using mnemonic

fill in mnemonic to `truffle-config.js:3`

```js
...
const mnemonic = 'YOURMNEMONIC';
...
```

write infura key for connecting to ethereum nodes in `truffle-config.js:5`

```js
...
const privateKey = 'YOURINFURAKEY';
...
```

DEPLOY!!

```bash
$ npx truffle migrate --network mainnet
```

you'll see deployed contract address in the console



#### Method 2. Using privateKey

install privatekey provider package from npm

```bash
$ npm install truffle-privatekey-provider
```

change HDWalletProvider to privatekey provider in `truffle-config.js:1`

```js
const HDWalletProvider = require('truffle-privatekey-provider');
```

change HDWalletProvider to get privateKey instead of mnemonic in line 11,18,26 of `truffle-config.js`

```diff
- return new HDWalletProvider(mnemonic, `https://mainnet.infura.io/v3/${infurakey}`);
+ return new HDWalletProvider(privateKey, `https://mainnet.infura.io/v3/${infurakey}`);
```

fill in privateKey to `truffle-config.js:4`

```js
...
const privateKey = 'YOURPRIVATEKEY';
...
```

write infura key for connecting to ethereum nodes in `truffle-config.js:5`

```js
...
const privateKey = 'YOURINFURAKEY';
...
```

DEPLOY!!

```bash
$ npx truffle migrate --network mainnet
```

you'll see deployed contract address in the console


