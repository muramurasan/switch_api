class Scrape
  require 'capybara'
  require 'capybara/dsl'
  require 'capybara/poltergeist'

  # シングルトンにすることで生成コストを抑制
  include Singleton
  #DSLのスコープを別けないと警告がでます
  include Capybara::DSL

  INTERVAL_SEC = 60
  VISIT_SITE_URL = "https://store.nintendo.co.jp/category/NINTENDOSWITCH/"

  def initialize
    Capybara.register_driver :poltergeist_debug do |app|
      Capybara::Poltergeist::Driver.new(app, { inspector: true, js_errors: false })
    end

    Capybara.default_driver = :poltergeist
    Capybara.javascript_driver = :poltergeist

    @responce_sec = 5
    @minimum_sleep_sec = 5
  end

  def perform
    start_time = Time.now

    while(end?(start_time)) do
      do_scrape
      cooldown
    end

    puts "The duration of this batch: #{Time.now - start_time} sec"
  end

  def do_scrape
    start_time = Time.now

    visit(VISIT_SITE_URL)
    notify unless detect_soldout?

    duration = Time.now - start_time
    puts "Response time: #{duration} sec"
    @responce_sec = duration.to_i + 1
  end

  private

    def detect_soldout?
      html = Nokogiri::HTML.parse(page.html)
      html.css('.soldout').count > 0
    end

    def notify
      puts "Now on sale!"
    end

    def cooldown
      sleep(@responce_sec + @minimum_sleep_sec)
    end

    def end?(time)
      (Time.now - time) < (INTERVAL_SEC - @responce_sec - (@minimum_sleep_sec * 2))
    end
end
