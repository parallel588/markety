module Markety
  def self.new_client(access_key, secret_key, end_point, api_version = '2_2')
    client = Savon.client do
      endpoint end_point
      wsdl "http://app.marketo.com/soap/mktows/#{api_version}?WSDL"
      env_namespace "SOAP-ENV"
      namespaces({"xmlns:ns1" => "http://www.marketo.com/mktows/"})
      pretty_print_xml true
    end

    Client.new(client, Markety::AuthenticationHeader.new(access_key, secret_key))
  end

  class Client
    def initialize(savon_client, authentication_header)
      @client = savon_client
      @header = authentication_header
    end

    public

    def new_custom_object(name, attributes = {})
      Markety::CustomObject.insert(self, name, attributes)
    end
    def update_custom_object(name, attributes = {})
      Markety::CustomObject.update(self, name, attributes)
    end
    def upsert_custom_object(name, attributes = {})
      Markety::CustomObject.upsert(self, name, attributes)
    end

    # http://developers.marketo.com/documentation/soap/requestcampaign/
    # This function runs an existing Marketo lead in a Marketo Smart Campaign.
    #
    # example:
    #   client = Markety.new_client(ENV['USER_ID'], ENV['ENCRYPTION_KEY'], ENV['END_POINT'])
    #   result = client.request_campaign({emails: ['test@gmail.com'],
    #                                     program_name: 'TestProgram_Email_via_RequestCampaign',
    #                                     campaign_name: 'Test_Campaign',
    #                                     program_tokens: [
    #                                       {name: 'age', value: '100'},
    #                                       {name: 'subject', value: 'GtSthh'},
    #                                       {name: 'content', value: "wise Qaa"}
    #                                     ] })
    #
    # @option options [String] source - Required
    #   The campaign source. 'MKTOWS' or 'SALES'
    # @option options [Array] emails - Required
    #   The lead list:
    #   example: ['test@email']
    #            [{type: 'EMAIL', value: 'test@email.com'}]
    #   type keyType allows you to specify the field you wish to query the lead by
    #   Possible values include:IDNUM, COOKIE,EMAIL, LEADOWNEREMAIL, SFDCACCOUNTID,
    #                            SFDCCONTACTID, SFDCLEADID,SFDCLEADOWNERID, SFDCOPPTYID
    #
    def request_campaign(options = {})
      request_campaign  = Markety::RequestCampaign.new(options)
      request_options = request_campaign.request_options


      request_campaign.parse_result(send_request(:request_campaign, request_options))


    rescue Exception => e
      @logger.log(e) if @logger
      return nil
    end

    def schedule_campaign(options = {})
      schedule_campaign  = Markety::ScheduleCampaign.new(options)
      request_options = schedule_campaign.request_options


      schedule_campaign.parse_result(send_request(:schedule_campaign, request_options))


    rescue Exception => e
      if @logger
        @logger.log(e)
      else
        puts e.inspect
      end
      return nil
    end

    def get_lead_by_idnum(idnum)
      get_lead(LeadKey.new(LeadKeyType::IDNUM, idnum))
    end


    def get_lead_by_email(email)
      get_lead(LeadKey.new(LeadKeyType::EMAIL, email))
    end

    def set_logger(logger)
      @logger = logger
    end

    def sync_lead(email, first, last, company, mobile)
      lead_record = LeadRecord.new(email)
      lead_record.set_attribute('FirstName', first)
      lead_record.set_attribute('LastName', last)
      lead_record.set_attribute('Email', email)
      lead_record.set_attribute('Company', company)
      lead_record.set_attribute('MobilePhone', mobile)
      sync_lead_record(lead_record)
    end

    def sync_lead_record(lead_record)
      begin
        attributes = []
        lead_record.each_attribute_pair do |name, value|
          attributes << {:attr_name => name, :attr_type => 'string', :attr_value => value}
        end

        response = send_request(:sync_lead, {
          :return_lead => true,
          :lead_record => {
            :email => lead_record.email,
            :lead_attribute_list => {
              :attribute => attributes
            }
          }
        })
        return LeadRecord.from_hash(response[:success_sync_lead][:result][:lead_record])
      rescue Exception => e
        @logger.log(e) if @logger
        return nil
      end
    end

    def sync_lead_record_on_id(lead_record)
      idnum = lead_record.idnum
      raise 'lead record id not set' if idnum.nil?

      begin
        attributes = []
        lead_record.each_attribute_pair do |name, value|
          attributes << {:attr_name => name, :attr_type => 'string', :attr_value => value}
        end

        attributes << {:attr_name => 'Id', :attr_type => 'string', :attr_value => idnum.to_s}

        response = send_request(:sync_lead, {
          :return_lead => true,
          :lead_record =>
          {
            :lead_attribute_list => { :attribute => attributes},
            :id => idnum
          }
        })
        return LeadRecord.from_hash(response[:success_sync_lead][:result][:lead_record])
      rescue Exception => e
        @logger.log(e) if @logger
        return nil
      end
    end

    def add_to_list(list_key, email)
      list_operation(list_key, ListOperationType::ADD_TO, email)
    end

    def remove_from_list(list_key, email)
      list_operation(list_key, ListOperationType::REMOVE_FROM, email)
    end

    def is_member_of_list?(list_key, email)
      list_operation(list_key, ListOperationType::IS_MEMBER_OF, email)
    end

    private
      def list_operation(list_key, list_operation_type, email)
        begin
          response = send_request(:list_operation, {
            :list_operation   => list_operation_type,
            :list_key         => list_key,
            :strict           => 'false',
            :list_member_list => {
              :lead_key => [
              {:key_type => 'EMAIL', :key_value => email}
            ]
          }
        })
        return response
      rescue Exception => e
        @logger.log(e) if @logger
        return nil
      end
    end

    def get_lead(lead_key)
      begin
        response = send_request(:get_lead, {"leadKey" => lead_key.to_hash})
        return LeadRecord.from_hash(response[:success_get_lead][:result][:lead_record_list][:lead_record])
      rescue Exception => e
        @logger.log(e) if @logger
        return nil
      end
    end

    def send_request(namespace, message)
      @header.set_time(DateTime.now)
      response = request(namespace, message, @header.to_hash)
      response.to_hash
    end

    def request(namespace, message, header)
      @client.call(namespace, :message => message, :soap_header => header)
    end
  end
end
