# frozen_string_literal: true

class SitemapRefreshJob < ApplicationJob
  queue_as :default

  def perform
    SitemapGenerator::Interpreter.run(verbose: false)
  end
end
