# frozen_string_literal: true

if ActiveRecord.version >= Gem::Version.new("8.2.0")
  warn "======================================================="
  warn "Hey there. Please check if we still need the patch in  "
  warn __FILE__
  warn "If we do, please consider upstreaming it to query_diet."
  warn "======================================================="
  exit 1
elsif ActiveRecord.version > Gem::Version.new("8.2.a")
  QueryDiet::Logger.singleton_class.prepend(Module.new do
    def log(intent_or_sql)
      query = if intent_or_sql.is_a?(ActiveRecord::ConnectionAdapters::QueryIntent)
        intent_or_sql.processed_sql
      else
        intent_or_sql
      end
      super(query)
    end
  end)
end
