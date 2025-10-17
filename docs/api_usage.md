# API Usage Samples

## REST (API Key)
```
curl \
  -H "x-api-key: <KEY>" \
  -H "x-company-id: demo" \
  "https://<region>-<project>.cloudfunctions.net/api/v1/crm/customers"
```

## GraphQL (Tenant aware)
```
curl \
  -H "Content-Type: application/json" \
  -H "x-api-key: <KEY>" \
  -H "x-company-id: demo" \
  -d '{"query":"{ customers(company_id:\"demo\"){ id name } }"}' \
  https://<region>-<project>.cloudfunctions.net/api/v1/graphql
```
