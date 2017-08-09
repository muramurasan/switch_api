# Rails起動時に一度シングルトンメソッドを生成しておく
Scrape.instance

class Api::SwitchesController < ApplicationController
  def scrape
    puts "start"
    Scrape.instance.perform
  end
end
