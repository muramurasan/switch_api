class Scrape
  require 'capybara'
  require 'capybara/dsl'
  require 'capybara/poltergeist'

  # シングルトンにすることで生成コストを抑制
  include Singleton
  #DSLのスコープを別けないと警告がでます
  include Capybara::DSL

  INTERVAL_SEC = 60

  def initialize
    Capybara.register_driver :poltergeist_debug do |app|
      Capybara::Poltergeist::Driver.new(app, { inspector: true, js_errors: false })
    end

    Capybara.default_driver = :poltergeist
    Capybara.javascript_driver = :poltergeist

    @responce_sec = 5
    @minimum_sleep_sec = 5
  end

  def visit_site
    start_time = Time.now
    visit('https://store.nintendo.co.jp/category/NINTENDOSWITCH/')

    html = Nokogiri::HTML.parse(page.html)
    puts "Now on sale!" unless html.css('.soldout').count > 0

    @responce_sec = (Time.now - start_time).to_i + 1
    puts @responce_sec
  end

  def perform
    start_time = Time.now

    while(end?(start_time)) do
      visit_site
      cooldown
    end

    puts (Time.now - start_time)
  end

  private

    def cooldown
      sleep(@responce_sec + @minimum_sleep_sec)
    end

    def end?(time)
      (Time.now - time) < (INTERVAL_SEC - @responce_sec - (@minimum_sleep_sec * 2))
    end
end
