# Services

Services are used to process HTTP requests.

The processing of an HTTP request is broken up in different process steps, each step being a service. For example there is a service to determine the requested resource URL, there is a service to prepare the response etc.

This way, each domain will have a stack of services that implement the services required for that domain. Of course, for a WWW domain many of these services will be the same and shared between domains.

The services are called in a predetermined sequence. The first services can communicate to the later services by way of a service information dictionary.

Each service receives the same set of parameters:

- The HTTP request itself
- The connection object that is used for the server/client communication
- The domain for which it is invoked
- The service information directory
- The response data

Services have to be registered before they can be used.

There is a special service called "Service.serverAdmin" that implements the server administration interface. It is active by default when no other domains have been defined. However when domains are defined the serveradmin service is lost and must be added explicitly to one of the domains.

Services should in general evaluate the `response.code` before starting their execution. If this field is set, then it is likely that the service should _not_ be continued.