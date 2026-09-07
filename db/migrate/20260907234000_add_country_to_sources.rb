# frozen_string_literal: true

class AddCountryToSources < ActiveRecord::Migration[7.0]
  def change
    add_column :sources, :country, :string
  end
end
