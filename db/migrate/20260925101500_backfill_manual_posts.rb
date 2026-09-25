# frozen_string_literal: true

class BackfillManualPosts < ActiveRecord::Migration[7.0]
  def up
    Post.where(manual: false, event_id: nil).update_all(manual: true)
  end

  def down
    # no-op
  end
end
