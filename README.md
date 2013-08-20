Conjur Demo : Service Acceleration
=========================

In this example, a service A will make many rapid calls to service B. 
For performance reasons, service A will be authorized with Conjur authz
only on the first call. On successful authorization, service B will generate
a signed token, and return the token to service A. Service A uses this token
on subsequent calls to service B. Service B will accept this token as proof
of authorization. 

Multiple instances of service B will be running simultaneously. A token
issued by any service B instance will be accepted by the other instances.

## Permissions Model

Services A and B are modeled as Groups. Each Group will contain the
(one or multiple) running instances of the service.

A key escrow Environment is created for service B. An RSA key pair is 
created and loaded into this Environment. 

Service Group A is granted *execute* permission on service B. 

Three host identities are created and assigned to the service groups:

* Service A, Host 1
* Service B, Host 1
* Service B, Host 2

```
$ source ./generate-assets.sh 
Namespace: 19gj00
Created https://core-sandbox-conjur.herokuapp.com/groups/19gj00/admin
Created https://core-sandbox-conjur.herokuapp.com/groups/19gj00/services/a
Created https://core-sandbox-conjur.herokuapp.com/groups/19gj00/services/b
{
  "id": "19gj00/services/b",
  "variables": {
  },
  "userid": "admin",
  "ownerid": "sandbox:group:19gj00/admin",
  "resource_identifier": "sandbox:environment:19gj00/services/b"
}
Membership granted
Generating RSA private key, 2048 bit long modulus
.........................................................................................+++
..+++
e is 65537 (0x10001)
Variable created
ServiceA.1.APIKey <snip>
ServiceB.1.APIKey <snip>
ServiceB.2.APIKey <snip>
Membership granted
Membership granted
Membership granted
{
  "id": {
    "account": "sandbox",
    "kind": "service",
    "id": "19gj00/services/b"
  },
  "owner": {
    "account": "sandbox",
    "id": "user:admin"
  },
  "permissions": [

  ]
}
Permission granted
```

## Runtime Operation

On startup, each instance of service B connects to the key escrow and 
fetches the key pair. 

When a request is received by service B, service B checks the Authorization
header for a token. If the token can be verified by the escrowed public key,
the request is permitted.

If the token cannot be verified by the escrowed public key, a permission
check with the Conjur authz service is performed. If the permission check
is successful, a service token is created and signed with the escrowed private
key. This service token is returned to the caller in the response.

If there is no token provided, the response is HTTP 401.

If a token is provided but cannot be verified, the response is HTTP 403.

## Hosted Services on Heroku

Two instances of Service B are hosted in Heroku at:

* service-accel-1-demo-conjur
* service-accel-2-demo-conjur

## Demonstration of Operation

demo.rb is a Ruby program which acts as service A and exercises the runtime
operation.

```
$ ruby demo.rb $ns <snip>
Warming up Heroku services
	done
Making initial request
	done
Making requests with service token to services B.1 and B.2
....................
	done
```
