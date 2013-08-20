# Bootstrap

ns=`conjur id:create`
conjur group:create $ns/admin

# Create service groups
conjur group:create --as-group $ns/admin $ns/services/a
conjur group:create --as-group $ns/admin $ns/services/b

# Create key escrow and populate with a shared secret
conjur asset:create --as-group $ns/admin environment $ns/services/b
conjur asset:members:add environment $ns/services/b use_variable group:$ns/services/b
key=`openssl genrsa 2048`
echo $key | conjur environment:variables:create $ns/services/b shared-secret rsa-private-key application/x-pem-file

# Create 1 service 'a' and 2 service 'b'
service_a_1_api_key=`conjur host:create $ns/services/a/1 | jsonfield api_key`
service_b_1_api_key=`conjur host:create $ns/services/b/1 | jsonfield api_key`
service_b_2_api_key=`conjur host:create $ns/services/b/2 | jsonfield api_key`

conjur group:members:add $ns/services/a host:$ns/services/a/1
conjur group:members:add $ns/services/b host:$ns/services/b/1
conjur group:members:add $ns/services/b host:$ns/services/b/2

# Grant services/a permission to execute services/b
conjur resource:create service $ns/services/b
conjur resource:permit service $ns/services/b group:$ns/services/a execute

