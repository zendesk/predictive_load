[![Build Status](https://github.com/zendesk/predictive_load/actions/workflows/actions.yml/badge.svg?branch=master)](https://github.com/zendesk/predictive_load/actions/workflows/actions.yml)


predictive_load
===============

Observes Active Record collections and notifies when a member loads an association. This allows for:
* automatically preloading the association in a single query for all members of that collection.
* N+1 detection logging 

### Automatic preloading


```ruby
require 'predictive_load'
require 'predictive_load/active_record_collection_observation'
ActiveRecord::Base.include(PredictiveLoad::ActiveRecordCollectionObservation)

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

Some things cannot be preloaded, use `predictive_load: false`

```
has_many :foos, predictive_load: false
```

### Instrumentation

The library can be instrumented by providing a callback, to be invoked every time automatic preloading happens. The callback must be a callable that receives two arguments:
* The record (instance) on which the queries that triggered automatic preloading are being performed, in the form of some association call.
* The association object, which can be inspected to check the type and name of the association.

For example, the callback could be used to emit some metrics:

```ruby
require "active_support/core_ext/string"

PredictiveLoad.callback = -> (record, association) do
  METRICS_CLIENT.increment_counter(
    "active_record.automatic_preloads",
    tags: [
      "model:#{record.class.name.underscore}",
      "association:#{association.reflection.name}"
    ]
  )
end
```

#### Known limitations:

* Calling association#size will trigger an N+1 on SELECT COUNT(*). Work around by calling #length, loading all records.
* Calling first / last will trigger an N+1.

### Releasing a new version

A new version is published to RubyGems.org every time a change to `version.rb` is pushed to the `main` branch.

In short, follow these steps:
1. Update `version.rb`,
2. update version in all `Gemfile.lock` files,
3. merge this change into `main`, and
4. look at [the action](https://github.com/zendesk/predictive_load/actions/workflows/publish.yml) for output.

To create a pre-release from a non-main branch:
1. change the version in `version.rb` to something like `1.2.0.pre.1` or `2.0.0.beta.2`,
2. push this change to your branch,
3. go to [Actions → “Publish to RubyGems.org” on GitHub](https://github.com/zendesk/predictive_load/actions/workflows/publish.yml),
4. click the “Run workflow” button,
5. pick your branch from a dropdown.

