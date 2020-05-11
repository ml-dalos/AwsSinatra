module AWS
  class Object
    attr_reader :bucket, :url, :name, :size, :last_modified

    def initialize(bucket:, template:)
      @bucket = bucket
      @client = bucket.client
      @resource = bucket.resource
      @object = template
      @name =  template.key
      @size = template.size
      @last_modified = template.last_modified
      @url = template.public_url
    end

    def public?
      @public ||= @object.acl.grants.any? do |grant|
        grant.grantee.uri == 'http://acs.amazonaws.com/groups/global/AllUsers' &&
        grant.permission == 'READ'
      end
    end

    def self.delete(bucket, params = {})
      bucket.object(params[:name]).delete
    end

    def self.create(bucket, params = {})
      bucket.object(params[:filename]).upload_file(params[:tempfile])
    end

    def self.change_access(client, params = {})
      client.client.put_object_acl(acl: params[:access], bucket: params[:bucket], key: params[:key])
    end
  end
end