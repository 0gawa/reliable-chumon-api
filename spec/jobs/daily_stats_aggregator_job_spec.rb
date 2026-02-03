require 'rails_helper'

RSpec.describe DailyStatsAggregatorJob, type: :job do
  include ActiveJob::TestHelper

  let(:target_date) { Date.new(2024, 1, 15) }
  let(:target_date_str) { target_date.to_s }

  describe '#perform' do
    context '正常系' do
      it 'ジョブがエンキューされること' do
        expect {
          DailyStatsAggregatorJob.perform_later(target_date_str)
        }.to have_enqueued_job(DailyStatsAggregatorJob).with(target_date_str)
      end

      it 'DailyStatsAggregatorが呼び出されること' do
        aggregator_double = double('DailyStatsAggregator')
        allow(DailyStatsAggregator).to receive(:new).with(target_date).and_return(aggregator_double)
        expect(aggregator_double).to receive(:aggregate)

        perform_enqueued_jobs do
          DailyStatsAggregatorJob.perform_later(target_date_str)
        end
      end

      it '指定された日付で集計が実行されること' do
        aggregator_double = double('DailyStatsAggregator')
        expect(DailyStatsAggregator).to receive(:new).with(target_date).and_return(aggregator_double)
        allow(aggregator_double).to receive(:aggregate)

        perform_enqueued_jobs do
          DailyStatsAggregatorJob.perform_later(target_date_str)
        end
      end
    end

    context 'エラーハンドリング' do
      it 'エラー発生時に再試行のために例外を再発生させること' do
        allow(DailyStatsAggregator).to receive(:new).and_raise(StandardError.new('Test error'))

        expect {
          perform_enqueued_jobs do
            DailyStatsAggregatorJob.perform_later(target_date_str)
          end
        }.to raise_error(an_instance_of(StandardError).or(an_instance_of(Minitest::UnexpectedError)))
      end

      it 'ログにエラー情報が記録されること' do
        allow(DailyStatsAggregator).to receive(:new).and_raise(StandardError.new('Test error'))
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:error).with(/Failed to aggregate stats/).at_least(:once)
        expect(Rails.logger).to receive(:error).with(anything).at_least(:once)

        expect {
          perform_enqueued_jobs do
            DailyStatsAggregatorJob.perform_later(target_date_str)
          end
        }.to raise_error # 任意のエラーが発生することを確認
      end
    end

    context '設定の確認' do
      it 'キューはdefaultであること' do
        expect(DailyStatsAggregatorJob.new.queue_name).to eq('default')
      end
    end
  end
end
