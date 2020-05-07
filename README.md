### Simple Sinatra APP for AWS SDK testing

Add AWS credentials into file secrets.yml:

```
aws:
  access_key_id: XXXXX
  secret_access_key: YYYYY
  bucket: bucket-name
  region: us-east-2
```

For starting app use:

`bundle exec rackup`