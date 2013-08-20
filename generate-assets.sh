# Bootstrap

ns=`conjur id:create`
echo Namespace: $ns
conjur group:create $ns/admin

# Create service groups
conjur group:create --as-group $ns/admin $ns/services/a
conjur group:create --as-group $ns/admin $ns/services/b

# Create key escrow and populate with a shared secret
conjur asset:create --as-group $ns/admin environment $ns/services/b
conjur asset:members:add environment $ns/services/b use_variable group:$ns/services/b
openssl genrsa 2048 | conjur environment:variables:create $ns/services/b shared-secret rsa-private-key application/x-pem-file

# Create 1 service 'a' and 2 service 'b'
service_a_1_api_key=`conjur host:create $ns/services/a/1 | jsonfield api_key`
echo ServiceA.1.APIKey $service_a_1_api_key
service_b_1_api_key=`conjur host:create $ns/services/b/1 | jsonfield api_key`
echo ServiceB.1.APIKey $service_b_1_api_key
service_b_2_api_key=`conjur host:create $ns/services/b/2 | jsonfield api_key`
echo ServiceB.2.APIKey $service_b_2_api_key

conjur group:members:add $ns/services/a host:$ns/services/a/1
conjur group:members:add $ns/services/b host:$ns/services/b/1
conjur group:members:add $ns/services/b host:$ns/services/b/2

# Grant services/a permission to execute services/b
conjur resource:create service $ns/services/b
conjur resource:permit service $ns/services/b group:$ns/services/a execute
