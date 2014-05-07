module Markety
  class RequestCampaign
    attr_accessor :request_options

    def initialize(options = {})
      @request_options = {}
      @request_options[:source] = (options[:source] || CampaignSourceType::MKTOWS)
      @request_options[:lead_list] = {}

      # @Required
      @request_options[:lead_list][:lead_key] = [options[:emails]].flatten
        .compact.map do |j|
        if j.is_a?(Hash)
          { key_type: j[:type], key_value: j[:value] }
        else
          { key_type: 'EMAIL', key_value: j }
        end
      end

      # campaignId
      if options[:campaign_id].present?
        @request_options[:campaign_id] = options[:campaign_id]
      end

      # campaignName
      if options[:campaign_name].present?
        @request_options[:campaign_name] = options[:campaign_name]
      end

      # programName
      if options[:program_name].present?
        @request_options[:program_name] = options[:program_name]
      end

      # programTokenList
      if options[:program_tokens].present?
        @request_options[:program_token_list] = {}
        @request_options[:program_token_list][:attrib] = options[:program_tokens]
      end

    end

    def parse_result(hash_response = {})
      hash_response[:success_request_campaign][:result][:success]
    end
  end
end
