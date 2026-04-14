# UniCC - A universal compiler compiler

UniCC is a programming language agnostic Yacc-like parser generator, written in Python.
It takes a programming language template file (typically with a `.def` extension) a grammar file (with a `.y` extension), and generates a LALR parser.
Check the Makefiles for example usage.

Instead of generating a parser, UniCC can also do the parsing on the fly in Python.
The Yacc grammar it uses is itself stored in its parsed form in the code.

The repository contains examples for a couple of target languages:
* BASIC, compiled using [the FreeBASIC compiler](https://www.freebasic.net/)
* C and C++, compiled using [the GNU Compiler Collection](https://gcc.gnu.org/)
* C Sharp, compiled using [Mono](https://www.mono-project.com/)
* FORTRAN 77 with or without record extensions, compiled using GFortran (part of the GNU Compiler Collection)
* FORTRAN 90/95
* Java
* Pascal, compiled using [the FreePascal compiler](https://www.freepascal.org/)
* Rust
* PL/I using the [Iron Springs PL/I compiler](http://www.iron-spring.com/) compiler (note: the variable `$PLIPATH` must be set to point to the root of the PL/I installation)
* ALGOL 60 using [GNU MARST](https://www.gnu.org/software/marst/marst.html)
* ALGOL W using [AWE](https://github.com/glynawe/awe)
* Simula using [GNU CIM](https://www.gnu.org/software/cim/)
* ALGOL 68 using the ELLA ALGOL 68RS compiler (note: the variable `$A68C` is expected to point to a script that generates a binary provided by the `-o` option, a simple example script is provided under the `algol68` directory)
* FoxPro (experimental, tested with Microsoft FoxPro 2.6 for MS-DOS)
* COBOL using [GnuCOBOL](https://gnucobol.sourceforge.io/)

The examples are very simple and do not always reflect best programming practices.
The same calculator application is implemented in each language.
To test them under a UNIX-like environment, change into the target directory and type `./calc`.

This project was an experiment and proof of concept to write a Yacc-like tool that works smoothly with any programming language.
There are likely still bugs.

## Design

The parser acts as a stand alone library, but it is only exposed to the user as a compiler generator.
It implements a modified subset of the YACC language, recognizing only a few directives:

* `%{ /* target language code */ %}`
  - Inserts a code snippet directly into the generated code
* `%token terminal_name_list`
  - Declares several identifiers as terminal symbols
* `%start initial_nonterminal`
  - Declares the first rule of the production tree
* `%define name value`
  - Assigns a value to some translator specific name (depends on the target language and `.def` file). Longer text can be enclosed in braces (`{` and `}`)
* `%%`
  - Starts the rules or terminates them. After the rules, any remaining text is inserted into the generated file.

Notably, the parser does not handle precedence declarations and value typing information.
Depending on the target language, value information can still be present, but this is up to programmer to implement.
This design choice was made to make it possible to create language agnostic parsers.
For example, the following YACC code:
```
%type <i> expression
%%
expression : expression '+' expression { $$ = $1 + $3; }
```
should be replaced with
```
%%
expression : expression '+' expression { $$.i = $1.i + $3.i; }
```
or the appropriate syntax for the target language.

Generally, the included `.def` files will provide an interface very similar to traditional YACC: a function called `yyparse()` should be invoked, and it expects the presence of at least an `yylex()` and `yyparse(error_message)` function.
Usually, the value type is expected to be `YYSTYPE`.
The value of the scanned token is expected to be held in a variable called `yylval`, declared in the parser code (this permits referencing this variable in languages where type definitions aren't a feature, such as PL/I).
Target languages may implement more or less features, for example passing additional parameters to the parser or lexer.
Some notable design choices:

* Some historical languages such as ALGOL 60 and FORTRAN 77 (without the DEC structure extensions) do not offer a structured data type, making it very hard to store token value information. For these languages, the `$n` (for any integer `n`) and `$$` are instead treated as integer indices into a phantom array. The programmer then has to prepare accessing this array themself. Note however that the FORTRAN 77 target can also handle structures, provided the extensions are enabled.

* Most target languages offer a free-form syntax, or at least allow arbitrary indentation for the source lines. Notable exceptions include COBOL and FORTRAN 77 where the source lines have a very rigid format. The code generation for these backends has been altered so that the code provided in `{ }` expressions can have arbitrary indentation and line length, and the lines are automatically adjusted to fit the maximum column count and for spacing.

* For all targets, the braces in a `{ }` literal must be balanced, otherwise the parser will run into problems.

* The definition files themselves have the format of a preprocessed text file. `@@` characters prefixed to the line escape into Python and execute it there directly during the generation. To cope with the indented syntax of Python, blocks are assumed to begin if such a line ends with `:` and a block must be closed by an `@@end` directive appearing alone on a line.

* Lines that do not begin with `@@` can also have Python code interspersed using the `@@{...}` syntax (where the ellipsis should be replaced with some valid Python expression). This is accomplished using Python string interpolation, and this must be kept in mind when including such expressions.

The `%define` command may be used to pass additional information to the target generator.
Since these are only observed by the `.def` file, their interpretation is entirely dependent on the target.
However, some common identifiers include the following.
Not all of them are meaningful for all targets.

* `yystype`
  - The name of the value type used by the parser. It usually defaults to some meaningful type value for the language, but for example the ALGOL 60 and FORTRAN 77 generators will avoid directly handling value types if this name is not defined.
* `yyparse_parameters`, `yyparse_parameter_declarations`
  - Declaration list of parameters `yyparse` will take. For languages that have to declare parameter types separately from the parameter list, the second name should also be used (see Fortran 95, PL/I or FoxPro).
* `yylex_arguments`
  - The expression list that should be passed to `yylex`.
* `yyempty`
  - Default value to be used for initializing the value stack (see Rust).

