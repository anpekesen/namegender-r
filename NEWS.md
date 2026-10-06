# namegender 0.5.0

* `ng_name()`, `ng_email()`, `ng_username()` and `ng_bulk()` take `locale` and
  `ip` as country hints when `country` is not given (priority `country` >
  `locale` > `ip`). Responses carry `country_source`; for `ng_bulk()` it is on
  the envelope, not on each row.
