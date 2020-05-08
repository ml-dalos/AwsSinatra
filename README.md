### Simple Sinatra APP for AWS SDK testing

Add AWS credentials into file config/secrets.yml:

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
```

For starting app use:

`bundle exec rackup`