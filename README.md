XRates Currency
===============

This gem extends Money::Bank::VariableExchange with Money::Bank::XratesCurrency
and gives you access to the current X-Rates.com Currency exchange rates.

Usage
-----

```ruby

require 'money'
require 'money/bank/xrates_currency'

# (optional)
# set the seconds after than the current rates are automatically expired
# by default, they never expire
Money::Bank::XratesCurrency.ttl_in_seconds = 86400

# set default bank to instance of XratesCurrency
Money.default_bank = Money::Bank::XratesCurrency.new

# create a new money object, and use the standard #exchange_to method
money = Money.new(1_00, "USD") # amount is in cents
money.exchange_to(:EUR)

# or install and use the 'monetize' gem
require 'monetize'
money = 1.to_money(:USD)
money.exchange_to(:EUR)

```

A `XratesCurrencyFetchError` will be thrown if there is an unknown issue with getting the info from X-Rates.com

Caveats
-------

This gem uses [X-Rates.com](https://x-rates.com) under the hood.

Exchange rates are,

1. Based on 1 unit of the original currency.
1. Have a precision of 4 decimal places.

What this means is that if the JPY to USD exchange rate is 0.0083660,
X-Rates will report the JPY to USD exchange rate as 0.0084.
As a result, a larger JPY to USD conversion such as 10000 JPY to USD would yield 84 USD instead of 83.66 USD.

Consequently, this means that small exchange rates will be imprecise.
For example, if the IDR to USD exchange rate were 0.00007761, X-Rates will report it as 0.0001.
This means 100000 IDR would exchange to 10 USD instead of 7.76 USD.

To accommodate for this, the reverse rate will be obtained if the rate is small
(below 0.1) and the reciprocal of this reverse rate is used.

Copyright
---------

Copyright (c) 2018 Phil Smy. See [LICENSE](LICENSE) for details.
