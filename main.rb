require 'bundler/setup'
require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'
require 'webdrivers/chromedriver'

require 'date'
require 'csv'

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  options.add_argument('disable-notifications')
  options.add_argument('disable-translate')
  options.add_argument('disable-extensions')
  options.add_argument('disable-infobars')
  options.add_argument('window-size=1280,960')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.configure do |config|
  config.default_driver = :chrome
  config.javascript_driver = :chrome
  # config.run_server = true
  config.default_max_wait_time = 8
  # config.automatic_label_click = false
end

$LOAD_PATH.unshift File.dirname(__FILE__)

class DateConfig
  def initialize(date, start, finish)
    @date = Date.parse(date) # 出勤日
    @start = start || "10#{random_minute}" # 出勤時間
    @finish = finish || "19#{random_minute}" # 退勤時間
  end

  def to_s
    "#{@date} : #{@start} ~ #{@finish}"
  end

  def random_minute
    format("%02d", rand(59))
  end
end

class Dakoku
  include Capybara::DSL

  def initialize(date_configs)
    @date_configs = date_configs
  end

  def execute
    setup

    @date_configs.each do |date_config|
      do_dakoku_day(date_config)
    rescue => e
      puts "#{date_config} [error] #{e}"
      puts e
    end
  end

  def setup
    email = ENV['USER_EMAIL'] || raise('ENV USER_EMAIL missing')
    password = ENV['USER_PASSWORD'] || raise('ENV USER_PASSWORD missing')

    visit('https://id.jobcan.jp/users/sign_in')
    fill_in 'user[email]', with: email
    fill_in 'user[password]', with: password
    click_on 'ログイン'

    visit 'https://ssl.jobcan.jp/employee'
    visit 'https://ssl.jobcan.jp/jbcoauth/login'
  end

  def do_dakoku_day(date_config)
    puts "#{date_config} start"

    date = date_config.date
    visit jobcan_edit_path(year: date.year, month: date.month, day: date.day)

    if page.has_xpath?('.//td', text: '出勤', visible: true)
      # 打刻区分の表の中に出勤　という文字列があれば、すでに押したところであるので何もしない
      puts "#{date_config} : すでに出勤押してあるのでスキップ"
      return
    end

    sleep 5

    find("#ter_time").fill_in(with: date_config.start)
    find('textarea[name="notice"]').fill_in(with: 'fix')
    return
    click_on '打刻'

    sleep 3

    find("#ter_time").fill_in(with: date_config.finish)
    find('textarea[name="notice"]').fill_in(with: 'fix')
    click_on '打刻'

    sleep 5
    puts "#{date_config} finished"
  end

  def jobcan_edit_path(year:, month:, day:)
    "https://ssl.jobcan.jp/employee/adit/modify?year=#{year}&month=#{month}&day=#{day}"
  end
end

date_configs = []

if $stdin.tty?
  raise '標準入力にcsvファイル渡して'
end

CSV($stdin).each do |row|
  # 日付,出勤時間,退勤時間 のcsv
  # 2020-01-01,1000,1920
  date_configs << DateConfig.new(row[0], row[1], row[2])
end

puts "target"
puts date_configs.map(&:to_s).join("\n")
puts

puts "start"
dakoku = Dakoku.new(date_configs)

dakoku.execute

puts "finished"
