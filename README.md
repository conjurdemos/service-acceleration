service-acceleration-demo
=========================

Simulates a call from service a to service b.

Service b checks the caller's execute permission, then creates and signs a token.

Future invocations of the token to a different service will check the token if it's present.
