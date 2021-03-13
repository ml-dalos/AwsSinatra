### Simple Sinatra APP to explore AWS SDK features

Add AWS credentials, information about author and credentials for basic auth into file config/secrets.yml:

```
aws:
  access_key_id: XXXXX
  secret_access_key: YYYYY
  bucket: bucket-name
  region: us-east-2
author:
  name: Ivan Ivanov
  date: 01 january 2021
  group: 550505
auth:
  username: cool_username
  password: cool_password
```

For starting app use:

`bundle exec rackup`
