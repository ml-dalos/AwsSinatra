require_relative  '../aws/client'
require_relative '../aws/bucket'
require_relative '../aws/object'
module AWS
  VALID_REGIONS = %w[
    ap-south-1
    ap-northeast-2
    ap-southeast-1
    ap-southeast-2
    ap-northeast-1
    ca-central-1
    eu-central-1
    eu-west-1
    eu-west-2
    eu-west-3
    eu-north-1
    sa-east-1
    us-east-1
    us-east-2
    us-west-1
    us-west-2
  ]
end