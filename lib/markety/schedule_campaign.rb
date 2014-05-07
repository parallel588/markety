module Markety
  class ScheduleCampaign
    attr_accessor :request_options

    def initialize(options = {})
      @request_options = {}

      # campaignName
      if options[:campaign_name].present?
        @request_options[:campaign_name] = options[:campaign_name]
      end

      # programName
      if options[:program_name].present?
        @request_options[:program_name] = options[:program_name]
      end
      if options[:run_at].present?
        @request_options[:campaign_run_at] = options[:run_at]
      end

      # programTokenList
      if options[:program_tokens].present?
        @request_options[:program_token_list] = {}
        @request_options[:program_token_list][:attrib] = options[:program_tokens]
      end
    end

    def parse_result(hash_response = {})
      hash_response[:success_schedule_campaign][:result][:success]
    end
  end
end
