Nordic Energy - Energy Use Case Smart Contracts
=================================

<p align="left">
    <a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-nd/4.0/88x31.png" /></a><br /><br />
    <a href="https://twitter.com/intent/follow?screen_name=Nordic Energy_Block"><img src="https://img.shields.io/twitter/follow/Nordic Energy_Block.svg?style=social&label=Follow%20@Nordic Energy_Block" alt="Follow on Twitter"></a>
</p>

## Introduction
[Nordic Energy](https://www.nordicenergy.io) is developing the only scalable public-private blockchain with deletable data features, made for commercial products. Designed with Nordic Energy´s PowerChain P2P trading use case, and co-innovated with SAP.

This repository shows the solidity smart contracts for the energy use case, which is the world's first peer to peer energy trading plattform commercially available to a mass market. You can test it at https://demo.nordicenergy.io (under construction) with the credentials demo / demo1234.

Development Environment
-----------------------

`git clone git@github.com:synechron-finlabs/quorum-maker.git`

`./setup.sh dev -p TestNetwork -n 3 -e`

`cd TestNetwork`

`docker-compose up -d`

go to dir with this repo

`npm i`

copy address to be unlocked `curl -s http://127.0.0.1:20104/getAccounts | jq '.[0].accountAddress'` (contract owner)

`npm run truffle console`

`web3.personal.unlockAccount(accountAddress)`

`migrate`

Documentation of the Contract `EnergyStore`
-------------------------------------------

The smart contract `EnergyStore` is designed to record offers from
power plants (producers) and choices from users (consumers). Each
producer has its own Ethereum address; users interact with the
contract using the owner's (Nordic Energy's) address by delegating their
interaction to Nordic Energy.

The ethereum address that creates the contract is its owner. It is
envisioned that this address is securely held by Nordic Energy.

Power plants (or conglomerates of power plants) are termed
producers. It is envisioned that each producer securely holds one own
address and shares this address (a hash of the public key) with
Nordic Energy.  Nordic Energy then calls a function of this contract to register the
producer, allowing it to call another function to record offers of
energy.

### Current Implementation

#### Setters

See `contracts/EnergyStore.sol`. The functions mentioned above are:

* `function registerProducer(address aproducer) onlyOwner`

  `curl -H "Content-Type: application/json" -X PUT -d '["0x..."]'
  http://blockchain.nordicenergy.io:8889/EnergyStore/registerProducer`

* `function registerConsumer(address aconsumer, uint32 auserID) onlyOwner`

  `curl -H "Content-Type: application/json" -X PUT -d '["0x...", "1"]'
  http://blockchain.nordicenergy.io:8889/EnergyStore/registerConsumer`


* `function offer_energy(uint32 aday, uint32 aprice, uint64 aenergy,
   uint64 atimestamp) onlyRegisteredProducers`

   `curl -H "Content-Type: application/json" -H "X-Account: 0x..." -X
   PUT -d '["1","1500","1000000","1234"]'
   http://blockchain.nordicenergy.io:8889/EnergyStore/offer_energy`

* `function buy_energy(address aproducer, uint32 aday, uint32 aprice,
   uint64 aenergy, uint32 auserID, uint64 atimestamp) onlyOwner`

  `curl -H "Content-Type: application/json" -X PUT -d '["0x...",
   "1","1500","1000000","12","1234"]'
   "http://blockchain.nordicenergy.io:8889/EnergyStore/buy_energy(address,uint32,uint32,uint64,uint32,uint64)"`

* (not to be called by Nordic Energy, but by a user, not via this server):
  `function buy_energy(address aproducer, uint32 aday, uint32 aprice,
   uint64 aenergy) onlyOwner`

  `curl -H "Content-Type: application/json" -H "X-Account: 0x..." -X
   PUT -d '["0x...", "1","1500","1000000"]'
   "http://blockchain.nordicenergy.io:8889/EnergyStore/buy_energy(address,uint32,uint32,uint64)"`

The parameters are:

* `aproducer` is the Ethereum address associated with a power plant
  (producer).

* `account` is the Ethereum address associated with the entity
  executing the function. This should be the contract owner (Nordic Energy)
  for `registerProducer` and `recordConsumerChoice`, or the producer
  for `recordEnergyOffer`.

* `aday` is the (unsigned 32-bit integer) number of days that the
  desired contract date is away from a day zero (to be defined by
  Nordic Energy).

* `aprice` is the price as an unsigned 32-bit integer in units of
  milli(Euro)Cent per kWh.

* `aenergy` is the amount of energy to be traded as an unsigned 64-bit
  integer (Warning: must be passed in quotes as a string to avoid
  rounding issues) in units of mWh (milliWatt*hours).

* `timestamp` is the (unsigned 64-bit integer) number of nanoseconds
  that have elapsed since Jan 1, 1970 (UNIX time in nanoseconds), at
  the instant the function call (or frontend action) is/was made.

* `auserID` is an unsigned 32-bit integer identifying a certain user
  (user id as used in the Nordic Energy backend).

The return behavior is:

* Upon success, a HTTP status code of 200 is returned. This means the
  transaction is being forwarded to the network. It does _not_ mean
  the transaction will necessarily succeed. Also a hexadecimal value
  (transaction hash) is written. That could, in a possible future
  extension, be used to poll the status of the transaction.

* Upon (early) failure, a HTTP status code of 4xx or 5xx is
  returned. Also, a text describing the error is written. Possible
  early failure modes include a syntax error (incorrect contract name,
  incorrect function name, incorrect number of arguments), a revert
  due to invalid parameters or due to an out-of-gas condition.

The logic is such that the timestamp parameter `atimestamp` is used to
discard delayed obsolete calls. It is recommended to pass the current
UNIX time in nanoseconds since the beginning of 1970.

In the current implementation, this discarding works as one would
expected for the function `recordEnergyOffer`. For
`recordConsumerChoice`, it only discards if the parameter `aday` (for
which day the consumer's choice starts to be valid) is identical
across the calls to be considered for discarding.

There are additional functions for reading out the recorded offers and
consumer choices, see source code.

#### Getters

There are automatic and convenience functions for retrieving data from
the smart contract. These include (as `curl` invocations):

* `curl -H "Content-Type: application/json" -X POST -d '[]'
  http://blockchain.Nordic Energy.io:8889/EnergyStore/getBidsCount` returns a
  double-quoted string with the decimal representation of the number
  of energy offers (bids).

* `curl -H "Content-Type: application/json" -X POST -d '[]'
  http://blockchain.Nordic Energy.io:8889/EnergyStore/getAsksCount` returns a
  double-quoted string with the decimal representation of the number
  of consumer choices (asks).

* `curl -H "Content-Type: application/json" -X POST -d '[0]'
  http://blockchain.Nordic Energy.io:8889/EnergyStore/bids` returns a JSON
  object with keys `producer`, `day`, `price`, `energy`, and
  `timestamp`.

* `curl -H "Content-Type: application/json" -X POST -d '[0]'
  http://blockchain.Nordic Energy.io:8889/EnergyStore/asks` returns a JSON
  object with keys `producer`, `day`, `price`, `energy`, `userID`, and
  `timestamp`.

* `curl -H "Content-Type: application/json" -X POST -d '[0]'
  http://blockchain.Nordic Energy.io:8889/EnergyStore/getAskByUserID` returns
  a JSON object with keys `producer`, `day`, `price`, and `energy`.

* `curl -H "Content-Type: application/json" -X POST -d '["0x...", 1]'
  http://blockchain.Nordic Energy.io:8889/EnergyStore/getBidByProducerAndDay`
  returns a JSON object with keys `price`, and `energy`.

The parameters are:

* None (`"[]"`), or

* An index or userID (`"[0]"`) which is an integer starting at 0 which
  must be less than the integer returned for the number of items that
  can be accessed with the getter (that number can always be queried
  with another getter and it never decreases).

* An address and an integer (`["0x...", 1]`).

The return behavior is:

Upon success, a HTTP status code of 200 is returned and a JSON-like
representation of the result is written (which normally are integers,
returned as quoted strings with the decimal representation).

Upon failure, a HTTP status code of 4xx or 5xx is returned.

#### Events

* `event BidMade(address indexed producer, uint32 indexed day, uint32
  indexed price, uint64 energy)` indicates that a new energy offer
  (bid) has been recorded.

* `event BidRevoked(address indexed producer, uint32 indexed day,
  uint32 indexed price, uint64 energy)` indicates that a previously
  recorded energy offer (bid) is no longer valid.


These events use (essentially) the same parameters (`producer` instead
of `aproducer`, `price` instead of `aprice`) as the setter functions.

`EnergyOffered` is emitted whenever a producer records a new energy
offer. `EnergyOfferRevoked` is emitted beforehand if (and only if)
such an offer is cancelling a previous offer.

### Unfinished Features

The various functions should emit events to simplify monitoring.

The registration function should allow setting a producer's capacity
and the contract should not accept offers exceeding a producer's
capacity.

The current time resolution for offers and choices is days; 1/4 hour
may be needed in the future.

Disclaimer
-----------

This repository is ethereum based smart contract POC for Nordic Energy energy infrastructure.

Implementation is not always optimal as the main aim of this code is proof of decisions,
problem highlighting. It will be replaced with highly efficient and enterprise ready 
blockchain solution developed by Nordic Energy (see https://www.nordicenergy.co for more details).  

License:
-----------
Copyright 2020 by Nordic Energy. Corporation., LTD, www.nordicenergy.co.
