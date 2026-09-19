# Keep a two-decimal ledger amount scale for the first multi-currency release

**Status**: accepted

Accounted For records an amount as an integer number of hundredths of a
currency unit for each of its five supported currencies. The first
multi-currency release retains this convention for USD, CNY, JPY, EUR and GBP,
including JPY, which normally uses no decimal places. This is the existing
meaning of amounts in events and recurring data; changing the interpretation
while adding currency filtering would change historical balances.

The ledger amount unit is an application convention, not a claim about each
currency's standard minor unit. Compatibility with data from before the new
model is out of scope. A future move to currency-specific scales is a separate
decision: it must preserve the value of events, recurring data and backups
created after the new model launches rather than reinterpret their integers
under a new scale. The later migration protocol remains to be designed.
