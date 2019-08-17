This does not constitute a promise for implementation, just a list of things that I am thinking about.

- Provide a "Max clients reached, try again in a few minutes"
- Improve error handling: not all errors should lead to termination
- EINTR (interrupted) should lead to retry on: accept, read, send, select. (i.e. operational calls, not setup calls)
- ECONNABORTED should lead to retry on accept

- Add trusted certificate to serveradmin
- Make the special trigger 'serveradmin' configurable

- Does it make sense to obfuscate error messages? i.e 'no access' and 'not found' do give information to the outside that seems unnecessary.
