class PerformJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
    Scrape.instance.perform
  end
end
