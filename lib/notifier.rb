#!/usr/bin/env ruby
require 'coinbase/exchange'
require 'faraday'
require 'json'
require 'syslog'

class Notifier
  def self.poll(options = {})
    new(options).poll

  rescue Exception => e
    $stderr.puts e.message
    exit 1
  end

  def initialize(options = {})
    Syslog.open 'gdax-notifier'

    @rest_api = Coinbase::Exchange::Client.new(
      ENV.fetch('GDAX_API_KEY'),
      ENV.fetch('GDAX_API_SECRET'),
      ENV.fetch('GDAX_API_PASS')
    )

    @maker_event = ENV.fetch('MAKER_EVENT')
    @maker_key   = ENV.fetch('MAKER_KEY')

    @frequency   = ENV.fetch('FREQ', 15).to_i # Seconds
    @fill_cache  = {}

    prime_fill_cache

    Syslog.info "gdax-notifier started, frequency: #{@frequency}s"
  end

  def poll
    loop do
      fills.each do |fill|
        unless cached?(fill)
          cache(fill)
          send_notification(fill)
        end
      end

      clean_cache
      sleep(@frequency)
    end
  end

  def send_notification(fill)
    product_id = fill['product_id']
    side = fill['side'].capitalize
    size = fill['size'].to_f.round(2)
    price = fill['price'].to_f.round(4)
    usd = fill['usd_volume'].to_f.round(2)
    info = "#{size} @ #{price} (#{usd}$)"

    value1, value2, value3 = product_id, side, info

    Syslog.info "Notifying #@maker_event: #{value1}, #{value2}, #{value3}"

    conn = Faraday.new('https://maker.ifttt.com/')
    conn.post do |req|
      req.url "/trigger/#{@maker_event}/with/key/#{@maker_key}"
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        value1: value1,
        value2: value2,
        value3: value3
      }.to_json
    end
  end

  protected

    def fills(start_date = cache_window)
      @rest_api.fills(start_date: start_date)
    end

    def prime_fill_cache
      fills.each {|fill| cache(fill) }
    end

    def cache(fill)
      @fill_cache[fill['order_id']] = Time.parse(fill['created_at'])
    end

    def cached?(fill)
      @fill_cache.key?(fill['order_id'])
    end

    def cache_window
      Time.now.utc - @frequency * 3
    end

    def clean_cache
      cache_window = self.cache_window

      @fill_cache.each do |order_id, date|
        if date < cache_window
          @fill_cache.delete(order_id)
        end
      end
    end

end
