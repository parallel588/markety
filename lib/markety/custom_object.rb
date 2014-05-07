module Markety
  class CustomObject
    SYNC_CUSTOM_OBJECTS_OPERATION = :sync_custom_objects
    INSERT = 'INSERT'
    UPDATE = 'UPDATE'
    UPSERT = 'UPSERT'

    class << self
      def lists(client)

      end

      def insert(client, name, attributes = {})
        client.send(:send_request, SYNC_CUSTOM_OBJECTS_OPERATION, {
                      operation: INSERT,
                      obj_type_name: name,
                      custom_obj_list: {
                        custom_obj: custom_obj_attributes(attributes)
                      }
                    })
      end
      def update(client, name, attributes = {})
        client.send(:send_request, SYNC_CUSTOM_OBJECTS_OPERATION, {
                      operation: UPDATE,
                      obj_type_name: name,
                      custom_obj_list: {
                        custom_obj: custom_obj_attributes(attributes)
                      }
                    })
      end
      def upsert(client, name, attributes = {})
        client.send(:send_request, SYNC_CUSTOM_OBJECTS_OPERATION, {
                      operation: UPSERT,
                      obj_type_name: name,
                      custom_obj_list: {
                        custom_obj: custom_obj_attributes(attributes)
                      }
                    })
      end

      def custom_obj_attributes(attributes = {})
        custom_obj_list = {}
        if attributes.key?(:key_list)
          custom_obj_list[:custom_obj_key_list] = attributes[:key_list]
        end
        if attributes.key?(:attribute_list)
          custom_obj_list[:custom_obj_attribute_list] = attributes[:attribute_list]
        end
        custom_obj_list
      end

    end

  end
end
