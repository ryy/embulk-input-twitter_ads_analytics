require "oauth"
require "active_support"
require "active_support/core_ext/date"
require "active_support/core_ext/time"
require "active_support/core_ext/numeric"

module Embulk
  module Input
    class TwitterAdsAnalytics < InputPlugin
      Plugin.register_input("twitter_ads_analytics", self)

      def self.transaction(config, &control)
        # configuration code:
        task = {
          "consumer_key" => config.param("consumer_key", :string),
          "consumer_secret" => config.param("consumer_secret", :string),
          "oauth_token" => config.param("oauth_token", :string),
          "oauth_token_secret" => config.param("oauth_token_secret", :string),
          "account_id" => config.param("account_id", :string),
          "entity" => config.param("entity", :string).upcase,
          "metric_groups" => config.param("metric_groups", :array).map(&:upcase),
          "granularity" => config.param("granularity", :string).upcase,
          "placement" => config.param("placement", :string).upcase,
          "start_date" => config.param("start_date", :string),
          "end_date" => config.param("end_date", :string),
          "timezone" => config.param("timezone", :string),
          "async" => config.param("timezone", :bool),
          "columns" => config.param("columns", :array),
        }

        columns = []
        task["columns"].each_with_index do |column, i|
          columns << Column.new(i, column["name"], column["type"].to_sym, column["format"])
        end

        resume(task, columns, 1, &control)
      end

      def self.resume(task, columns, count, &control)
        task_reports = yield(task, columns, count)

        next_config_diff = {}
        return next_config_diff
      end

      def self.guess(config)
        entity = config.param("entity", :string).upcase
        metric_groups = config.param("metric_groups", :array).map(&:upcase)
        columns = [
          {name: "date", type: "timestamp", format: "%Y-%m-%d"},
        ]
        columns += [
          {name: "account_id", type: "string"},
          {name: "account_name", type: "string"},
        ] if entity == "ACCOUNT"
        columns += [
          {name: "campaign_id", type: "string"},
          {name: "campaign_name", type: "string"},
        ] if entity == "CAMPAIGN"
        columns += [
          {name: "line_item_id", type: "string"},
          {name: "line_item_name", type: "string"},
        ] if entity == "LINE_ITEM"
        columns += [
          {name: "funding_instrument_id", type: "string"},
          {name: "description", type: "string"},
        ] if entity == "FUNDING_INSTRUMENT"
        columns += [
          {name: "engagements", type: "long"},
          {name: "impressions", type: "long"},
          {name: "retweets", type: "long"},
          {name: "replies", type: "long"},
          {name: "likes", type: "long"},
          {name: "follows", type: "long"},
          {name: "card_engagements", type: "long"},
          {name: "clicks", type: "long"},
          {name: "app_clicks", type: "long"},
          {name: "url_clicks", type: "long"},
          {name: "qualified_impressions", type: "long"},
        ] if metric_groups.include?("ENGAGEMENT") && (entity != "ACCOUNT" && entity != "FUNDING_INSTRUMENT")
        columns += [
          {name: "engagements", type: "long"},
          {name: "impressions", type: "long"},
          {name: "retweets", type: "long"},
          {name: "replies", type: "long"},
          {name: "likes", type: "long"},
          {name: "follows", type: "long"},
        ] if metric_groups.include?("ENGAGEMENT") && (entity == "ACCOUNT" || entity == "FUNDING_INSTRUMENT")
        columns += [
          {name: "billed_engagements", type: "long"},
          {name: "billed_charge_local_micro", type: "long"},
        ] if metric_groups.include?("BILLING")
        columns += [
          {name: "video_total_views", type: "long"},
          {name: "video_views_25", type: "long"},
          {name: "video_views_50", type: "long"},
          {name: "video_views_75", type: "long"},
          {name: "video_views_100", type: "long"},
          {name: "video_cta_clicks", type: "long"},
          {name: "video_content_starts", type: "long"},
          {name: "video_3s100pct_views", type: "long"},
          {name: "video_6s_views", type: "long"},
          {name: "video_15s_views", type: "long"},
        ] if metric_groups.include?("VIDEO")
        columns += [
          {name: "media_views", type: "long"},
          {name: "media_engagements", type: "long"},
        ] if metric_groups.include?("MEDIA")
        columns += [
          {name: "conversion_purchases", type: "json"},
          {name: "conversion_sign_ups", type: "json"},
          {name: "conversion_site_visits", type: "json"},
          {name: "conversion_downloads", type: "json"},
          {name: "conversion_custom", type: "json"},
        ] if metric_groups.include?("WEB_CONVERSION")
        columns += [
          {name: "mobile_conversion_spent_credits", type: "json"},
          {name: "mobile_conversion_installs", type: "json"},
          {name: "mobile_conversion_content_views", type: "json"},
          {name: "mobile_conversion_add_to_wishlists", type: "json"},
          {name: "mobile_conversion_checkouts_initiated", type: "json"},
          {name: "mobile_conversion_reservations", type: "json"},
          {name: "mobile_conversion_tutorials_completed", type: "json"},
          {name: "mobile_conversion_achievements_unlocked", type: "json"},
          {name: "mobile_conversion_searches", type: "json"},
          {name: "mobile_conversion_add_to_carts", type: "json"},
          {name: "mobile_conversion_payment_info_additions", type: "json"},
          {name: "mobile_conversion_re_engages", type: "json"},
          {name: "mobile_conversion_shares", type: "json"},
          {name: "mobile_conversion_rates", type: "json"},
          {name: "mobile_conversion_logins", type: "json"},
          {name: "mobile_conversion_updates", type: "json"},
          {name: "mobile_conversion_levels_achieved", type: "json"},
          {name: "mobile_conversion_invites", type: "json"},
          {name: "mobile_conversion_key_page_views", type: "json"},
        ] if metric_groups.include?("MOBILE_CONVERSION")
        columns += [
          {name: "mobile_conversion_lifetime_value_purchases", type: "json"},
          {name: "mobile_conversion_lifetime_value_sign_ups", type: "json"},
          {name: "mobile_conversion_lifetime_value_updates", type: "json"},
          {name: "mobile_conversion_lifetime_value_tutorials_completed", type: "json"},
          {name: "mobile_conversion_lifetime_value_reservations", type: "json"},
          {name: "mobile_conversion_lifetime_value_add_to_carts", type: "json"},
          {name: "mobile_conversion_lifetime_value_add_to_wishlists", type: "json"},
          {name: "mobile_conversion_lifetime_value_checkouts_initiated", type: "json"},
          {name: "mobile_conversion_lifetime_value_levels_achieved", type: "json"},
          {name: "mobile_conversion_lifetime_value_achievements_unlocked", type: "json"},
          {name: "mobile_conversion_lifetime_value_shares", type: "json"},
          {name: "mobile_conversion_lifetime_value_invites", type: "json"},
          {name: "mobile_conversion_lifetime_value_payment_info_additions", type: "json"},
          {name: "mobile_conversion_lifetime_value_spent_credits", type: "json"},
          {name: "mobile_conversion_lifetime_value_rates", type: "json"},
        ] if metric_groups.include?("LIFE_TIME_VALUE_MOBILE_CONVERSION")
        return {"columns" => columns}
      end

      def init
        # initialization code:
        @consumer_key = task["consumer_key"]
        @consumer_secret = task["consumer_secret"]
        @oauth_token = task["oauth_token"]
        @oauth_token_secret = task["oauth_token_secret"]
        @account_id = task["account_id"]
        @entity = task["entity"]
        @metric_groups = task["metric_groups"]
        @granularity = task["granularity"]
        @placement = task["placement"]
        @start_date = task["start_date"]
        @end_date = task["end_date"]
        @timezone = task["timezone"]
        @async = task["async"]
        @columns = task["columns"]

        Time.zone = @timezone
      end

      def run
        access_token = get_access_token
        entities = request_entities(access_token)
        stats = []
        entities.each_slice(10) do |chunked_entities|
          chunked_times.each do |chunked_time|
            response = request_stats(access_token, chunked_entities.map { |entity| entity["id"] }, chunked_time)
            response.each do |row|
              row["start_date"] = chunked_time[:start_date]
              row["end_date"] = chunked_time[:end_date]
            end
            stats += response
          end
        end
        stats.each do |item|
          metrics = item["id_data"][0]["metrics"]
          (Date.parse(item["start_date"])..Date.parse(item["end_date"])).each_with_index do |date, i|
            page = []
            @columns.each do |column|
              if ["account_id", "campaign_id", "line_item_id", "funding_instrument_id"].include?(column["name"])
                page << item["id"]
              elsif column["name"] == "date"
                page << Time.zone.parse(date.to_s)
              elsif ["account_name", "campaign_name", "line_item_name"].include?(column["name"])
                page << entities.find { |entity| entity["id"] == item["id"] }["name"]
              elsif column["name"] == "description"
                page << entities.find { |entity| entity["id"] == item["id"] }["description"]
              else
                if !metrics[column["name"]]
                  page << nil
                elsif column["type"] == "json"
                  page << metrics[column["name"]]
                else
                  page << metrics[column["name"]][i]
                end
              end
            end
            page_builder.add(page)
          end
        end
        page_builder.finish

        task_report = {}
        return task_report
      end

      def get_access_token
        consumer = OAuth::Consumer.new(@consumer_key, @consumer_secret, site: "https://ads-api.twitter.com", scheme: :header)
        OAuth::AccessToken.from_hash(consumer, oauth_token: @oauth_token, oauth_token_secret: @oauth_token_secret)
      end

      def request_entities(access_token)
        url = "https://ads-api.twitter.com/9/accounts/#{@account_id}/#{entity_plural(@entity).downcase}"
        url = "https://ads-api.twitter.com/9/accounts/#{@account_id}" if @entity == "ACCOUNT"
        response = access_token.request(:get, url)
        if response.code != "200"
          Embulk.logger.error "#{response.body}"
          raise
        end
        return [JSON.parse(response.body)["data"]] if @entity == "ACCOUNT"
        JSON.parse(response.body)["data"]
      end

      def request_stats(access_token, entity_ids, chunked_time)
        params = {
          entity: @entity,
          entity_ids: entity_ids.join(","),
          metric_groups: @metric_groups.join(","),
          start_time: chunked_time[:start_time],
          end_time: chunked_time[:end_time],
          placement: @placement,
          granularity: @granularity,
        }
        response = access_token.request(:get, "https://ads-api.twitter.com/9/stats/accounts/#{@account_id}?#{URI.encode_www_form(params)}")
        if response.code != "200"
          Embulk.logger.error "#{response.body}"
          raise
        end
        JSON.parse(response.body)["data"]
      end

      def chunked_times
        (Date.parse(@start_date)..Date.parse(@end_date)).each_slice(7).map do |chunked|
          {
            start_date: chunked.first.to_s,
            end_date: chunked.last.to_s,
            start_time: Time.zone.parse(chunked.first.to_s).strftime("%FT%T%z"),
            end_time: Time.zone.parse(chunked.last.to_s).tomorrow.strftime("%FT%T%z"),
          }
        end
      end

      def entity_plural(entity)
        case entity
        when "CAMPAIGN"
          "CAMPAIGNS"
        when "LINE_ITEM"
          "LINE_ITEMS"
        when "PROMOTED_TWEET"
          "PROMOTED_TWEETS"
        when "ACCOUNT"
          "ACCOUNTS"
        when "FUNDING_INSTRUMENT"
          "FUNDING_INSTRUMENTS"
        end
      end
    end
  end
end
