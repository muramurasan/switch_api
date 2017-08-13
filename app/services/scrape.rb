class Scrape
  require 'capybara'
  require 'capybara/dsl'
  require 'capybara/poltergeist'

  # シングルトンにすることで生成コストを抑制
  include Singleton
  #DSLのスコープを別けないと警告がでます
  include Capybara::DSL

  INTERVAL_SEC = 60
  TEMP_RESPONSE_SEC = 5
  MINIMUM_SLEEP_SEC = 5
  NOTIFY_COOL_DOWN_SEC = 300
  ERROR_REPORT_COOL_DOWN_SEC = 180
  SURVIVAL_REPORT_COOL_DOWN_SEC = 3600
  VISIT_SITE_URL = "https://store.nintendo.co.jp/category/NINTENDOSWITCH/"

  def initialize
    Capybara.register_driver :poltergeist_debug do |app|
      Capybara::Poltergeist::Driver.new(app, { inspector: true, js_errors: false })
    end

    Capybara.default_driver = :poltergeist
    Capybara.javascript_driver = :poltergeist

    load_attributes
  end

  def perform
    survival_report! if survival_report_time?

    start_time = Time.current
    last_response_sec = TEMP_RESPONSE_SEC
    response_hash = {}
    request_times = 0

    while(end?(start_time, last_response_sec)) do
      last_response_sec = do_scrape
      request_times += 1
      response_hash.store("request#{request_times}_duration", last_response_sec)
      cool_down(last_response_sec.to_i + 1)
    end

    duration = Time.current - start_time

    response_hash.store("total_duration", duration)
    response_hash
  end

  private

    def do_scrape
      start_time = Time.current
      visit(VISIT_SITE_URL)
      notify!
    rescue
      error_notify!
    ensure
      duration = Time.current - start_time
      return duration
    end

    def load_attributes
      @next_survival_report_at = Time.current
      @survival_report_times = 0
      @slack_client = Slack::Web::Client.new
      perform = Perform.find_by(service_name: self.class.name)
      if perform
        @next_notify_at = perform.next_notify_at
        @next_error_report_at = perform.next_error_report_at
      else
        @next_notify_at = Time.current + NOTIFY_COOL_DOWN_SEC
        @next_error_report_at = Time.current + ERROR_REPORT_COOL_DOWN_SEC
        Perform.create(service_name: self.class.name,
                       next_notify_at: @next_notify_at,
                       next_error_report_at: @next_error_report_at,
                       next_survival_report_at: @next_survival_report_at)
      end
    end

    def survival_report!
      @survival_report_times += 1
      @next_survival_report_at = SURVIVAL_REPORT_COOL_DOWN_SEC.seconds.since
      slack_notify(":thinking_face: スクレイピングスクリプト起動してから #{@survival_report_times} 回目の生存報告 :thinking_face:")
    end

    def survival_report_time?
      @next_survival_report_at < Time.current
    end

    def detect?(css_class)
      html = Nokogiri::HTML.parse(page.html)
      html.css(".#{css_class}").count > 0
    end

    def can_notify?
      !detect?("soldout") && @next_notify_at < Time.current
    end

    def can_error_notify?
      @next_error_report_at < Time.current
    end

    def notify!
      return unless can_notify?
      @next_notify_at = NOTIFY_COOL_DOWN_SEC.seconds.since
      Perform.find_or_create_by(service_name: self.class.name) do |perform|
        perform.next_notify_at = @next_notify_at
      end
      slack_notify "@channel :tada: Now on sale!! :tada:"
    end

    def error_notify!
      return unless can_error_notify?
      @next_error_report_at = ERROR_REPORT_COOL_DOWN_SEC.seconds.since
      slack_notify(":scream: 正常にサイトに接続できませんでした...... :scream:")
    end

    def cool_down(margin_sec)
      sleep(margin_sec + MINIMUM_SLEEP_SEC)
    end

    def end?(time, margin_sec)
      # 混み合っている時のために、前回スクレイピングにかかった時間(margin_sec)を待たせる
      (Time.current - time) < (INTERVAL_SEC - margin_sec - (MINIMUM_SLEEP_SEC * 2))
    end

    def slack_notify(text)
      @slack_client.chat_postMessage(channel: '#bot_test', text: text)
    end
end
