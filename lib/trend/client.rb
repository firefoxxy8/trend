require "trend/version"

module Trend
  class Client
    HEADERS = {
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "User-Agent" => "trend-ruby/#{Trend::VERSION}"
    }

    def initialize(url: nil)
      url ||= Trend.url
      @uri = URI.parse(url)
      @http = Net::HTTP.new(@uri.host, @uri.port)
      @http.use_ssl = true if @uri.scheme == "https"
      @http.open_timeout = 3
      @http.read_timeout = 5
    end

    def anomalies(series, params = {})
      resp = make_request("anomalies", series, params)
      resp["anomalies"].map { |v| parse_time(v) }
    end

    def forecast(series, params = {})
      resp = make_request("forecast", series, params)
      Hash[resp["forecast"].map { |k, v| [parse_time(k), v] }]
    end

    private

    def make_request(path, series, params)
      post_data = {
        series: series
      }.merge(params)

      begin
        response = @http.post("/#{path}", post_data.to_json, HEADERS)
      rescue Errno::ECONNREFUSED, Timeout::Error => e
        raise Trend::Error, e.message
      end

      parsed_body = JSON.parse(response.body) rescue {}

      if !response.is_a?(Net::HTTPSuccess)
        raise Trend::Error, parsed_body["error"] || "Server returned #{response.code} response"
      end

      parsed_body
    end

    def parse_time(v)
      v.size == 10 ? Date.parse(v) : Time.parse(v)
    end
  end
end
