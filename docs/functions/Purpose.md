# Functions

Functions are used to inject dynamic content into a web page or resource.

If the filename of a requested resource contains the four special characters `.sf.` then Swiftfire will parse that file before passing it on to the client. The parser will replace each function call with the result of the execution of that function call. (It is strongly recommended to place the `.sf.` immediately before the file extension, i.e. `my-beautifull-page.sf.html`)

The Extended-BNF notation of a function call is as follows:

{ } = sequence, [ ] = optional, | = or, .. = any in range

~~~~
<function> ::= <leading-sign><name>[<priority-seperator>[<priority>]]<arguments>

<leading-sign>          ::= "."
<name>                  ::= <letter>|<digit>|<allowed-signs-in-name>{[<letter>|<digit>|<allowed-signs-in-name>]}
<letter>                ::= "A" .. "Z" | "a" .. "z"
<digit>                 ::= "0" .. "9"
<allowed-signs-in-name> ::= "-"|"_"
<priority-seperator>    ::= ":"
<priority>              ::= <digit>{[<digit>]}

<arguments>             ::= "("[<argument>[{<argument-separator><argument>}]]")"|<json-object>
<json-object>           ::= "{"<json-code>"}"
<argument>              ::= <non-quoted-string>|<quoted-string>
<arguments-separator>   ::= ","
<non-quoted-string>     ::= {[" "]}<string>{[" "]}
<quoted-string>         ::= {[" "]}"""{<string>}"""{[" "]}
~~~~

Examples:

	.numberOfHits()
	.customSeparator(1, fourtyTwo)
	.numberOfBoxes:2{"first":"jumping", "second":["throw", "catch"]}

Note: Only a function that does have a corresponding entry in the registered function table will be recognized as a function.

Function calls must be registered before they can be used. The registration maps a name to a function. It is customary to name functions as follows: `function_nofPageHits()`. During registration this can be mapped as follows: `functions.register(name: "nofPageHits", function: function_nofPageHits)`. After this the function is available as `.nofPageHits()`.

A function can have any number of parameters. The parameters in the function call are passed to the actual swift function as an array of strings or as a JSON object, which one is used depends on the definition of the function.

The signature of a function is given by `Function.Signature` and can be found in the file `Core.Functions.Swift`

## Arguments

Arguments can be either a String or a QuotedString. Quotes are only necessary if the argument contains special characters (including whitespaces).

Swiftfire makes it easy for functions to support argument key's through a leading character ('$') in the arguments. For this purpose a supporting operation is provided ("evaluateKeyArgument") that will take an argument, decode the source and return the asked for information. Functions can use this operation to support key arguments for any parameter. An example syntax:

    .show($account.name)

More formal, the syntax is as follows:

~~~~
<key_argument> ::= <dollar-sign><source-name><dot><key>

<dollar-sign> ::= "$"
<source-name> ::= "request"|"service"|"function"|"account"
<dot> ::= "."
<key> ::= <letter>|<digit>
~~~~

See the definition of the operation "evaluateKeyArgument" for more on which information is available from which source.
