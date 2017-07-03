This does not constitute a promise for implementation, just a list of things that I am thinking about.

- Research if it is necessary to use getsockopt to find errors before they interfere with send or recv
- Monitor the accept queue (if possible)
- Provide a "Max clients reached, try again in a few minutes"
- Improve error handling: not all errors should lead to termination
- EINTR (interrupted) should lead to retry on: accept, read, send, select. (i.e. operational calls, not setup calls)
- ECONNABORTED should lead to retry on accept

- Add trusted certificate to serveradmin
- Make the special trigger 'serveradmin' configurable
- Consider a better approach to simply listing all client accesses. This list will get way to long to be manageable. Maybe a searchable list? by time of access and/or address? or sort it by times accessed?