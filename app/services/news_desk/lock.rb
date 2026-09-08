# frozen_string_literal: true

module NewsDesk
  class Lock
    def self.with(key)
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("SELECT pg_advisory_xact_lock(#{key.to_i})")
        yield
      end
    end
  end
end
