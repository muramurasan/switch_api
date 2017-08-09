# Rails起動時に一度シングルトンメソッドを生成しておく
Scrape.instance

class Api::SwitchesController < ApplicationController
  def scrape
    Scrape.instance.perform
  end
end
