# Rails起動時に一度シングルトンメソッドを生成しておく
Scrape.instance

class Api::SwitchesController < ApplicationController
  def scrape
    PerformJob.perform_later
    render json: { request: true }
  end
end
