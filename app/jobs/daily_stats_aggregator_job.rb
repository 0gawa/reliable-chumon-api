# 日次メニュー販売統計の集計ジョブ
#
# DailyStatsAggregatorサービスをラップし、
# 指定された日付の注文データから統計を作成します。
#
# @example 手動実行
#   DailyStatsAggregatorJob.perform_async('2024-01-15')
#
# @example 前日の統計を集計
#   DailyStatsAggregatorJob.perform_async(Date.yesterday.to_s)
#
class DailyStatsAggregatorJob < ApplicationJob
  queue_as :default

  sidekiq_options retry: 3, backtrace: true

  # @param target_date [String] 集計対象日（YYYY-MM-DD形式）
  def perform(target_date)
    date = Date.parse(target_date)

    Rails.logger.info "Starting daily stats aggregation for #{date}"

    aggregator = DailyStatsAggregator.new(date)
    aggregator.aggregate

    Rails.logger.info "Completed daily stats aggregation for #{date}"
  rescue StandardError => e
    Rails.logger.error "Failed to aggregate stats for #{date}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise # Sidekiqにエラーを伝えて再試行させる
  end
end
