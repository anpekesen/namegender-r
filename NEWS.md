# namegender 0.7.1

* First release on CRAN. Package metadata only: a named maintainer, the
  'NameGender' web service quoted and linked in the description, and
  NameGender listed as copyright holder. No change to the functions.

# namegender 0.7.0

* New `ng_name_check()` and `ng_name_check_bulk()` say whether a name typed
  into a form looks like a real person's name: `assessment` (`"plausible"`,
  `"suspicious"`, `"implausible"`), `score` (0-100), `signals` and `evidence`.
  It never calls a name fake; use it to flag records, not to reject people
  automatically. Surnames are judged by their shape only. One credit per name.

# namegender 0.6.0

* New `ng_salutation()` and `ng_salutation_bulk()` return a ready-made
  salutation (`formal`, `informal`, `neutral`) for a name, in 16 languages and
  regional variants. One credit per name. When the gender is not certain the
  neutral form is used; `form` and `reason` say why. `best_guess` and
  `ai_fallback` do not apply and are not accepted.

# namegender 0.5.0

* `ng_name()`, `ng_email()`, `ng_username()` and `ng_bulk()` take `locale` and
  `ip` as country hints when `country` is not given (priority `country` >
  `locale` > `ip`). Responses carry `country_source`; for `ng_bulk()` it is on
  the envelope, not on each row.
