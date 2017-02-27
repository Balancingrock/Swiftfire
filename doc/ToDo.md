This does not constitute a promise for implementation, just a list of things that I am thinking about.

- Research if it is necessary to use getsockopt to find errors before they interfere with send or recv
- Monitor the accept queue (if possible)
- Provide a "Max clients reached, try again in a few minutes"
- Improve error handling: not all errors should lead to termination
- EINTR (interrupted) should lead to retry on: accept, read, send, select. (i.e. operational calls, not setup calls)
- ECONNABORTED should lead to retry on accept
- Make it impossible in the GUI to request anything but closeConnection for the server level blacklist
