[![Build Status](https://travis-ci.org/eac/predictive_load.png)](https://travis-ci.org/eac/predictive_load)

predictive_load
===============

Observes Active Record collections and notifies when a member loads an association. This allows for:
* automatically preloading the association in a single query for all members of that collection.
* N+1 detection logging 

### Automatic preloading


```ruby
require 'predictive_load'
require 'predictive_load/active_record_collection_observation'
ActiveRecord::Base.send(:include, PredictiveLoad::ActiveRecordCollectionObservation)

require 'predictive_load/loader'

ActiveRecord::Relation.collection_observer = PredictiveLoad::Loader

Ticket.all.each do |ticket| 
  ticket.requester.identities.each { |identity| identity.account }
end
```

Produces:
```sql
  SELECT `tickets`.* FROM `tickets`
  SELECT `requesters`.* FROM `requesters` WHERE `requesters`.`id` IN (2, 7, 12, 32, 37)
  SELECT `identities`.* FROM `identities` WHERE `identities`.`requester_id` IN (2, 7, 12, 32, 37)
  SELECT `accounts`.* FROM `accounts` WHERE `accounts`.`id` IN (1, 2, 3)
```

### Disabling preload

Some things cannot be preloaded, use `no_preload`

```
has_many :foos, no_preload: true
```

### N+1 detection logging

There is also a log-only version:
```ruby
require 'predictive_load'
require 'predictive_load/active_record_collection_observation'
ActiveRecord::Base.send(:include, PredictiveLoad::ActiveRecordCollectionObservation)

require 'predictive_load/watcher'

ActiveRecord::Relation.collection_observer = PredictiveLoad::Watcher

Comment.all.each do |comment|
  comment.account
end

```

Produces:

```
detected n1 call on Comment#account
expect to prevent 10 queries
would preload with: SELECT `accounts`.* FROM `accounts`  WHERE `accounts`.`id` IN (...)
+----+-------------+----------+-------+---------------+---------+---------+-------+------+-------+
| id | select_type | table    | type  | possible_keys | key     | key_len | ref   | rows | Extra |
+----+-------------+----------+-------+---------------+---------+---------+-------+------+-------+
|  1 | SIMPLE      | accounts | const | PRIMARY       | PRIMARY | 4       | const |    10 |      |
+----+-------------+----------+-------+---------------+---------+---------+-------+------+-------+
1 row in set (0.00 sec)
would have prevented all 10 queries

```

#### Known limitations:

* Calling association#size will trigger an N+1 on SELECT COUNT(*). Work around by calling #length, loading all records.
* Calling first / last will trigger an N+1.
