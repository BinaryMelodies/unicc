# UniCC - A universal compiler compiler

UniCC is a programming language agnostic Yacc-like parser generator, written in Python.
It takes a programming language template file (typically with a `.def` extension) a grammar file (with a `.y` extension), and generates a LALR parser.

Instead of generating a parser, UniCC can also do the parsing on the fly, and the Yacc grammar it uses is stored in its parsed form in the code.

The repository contains examples for a couple of target languages:
* BASIC, compiled using the FreeBASIC compiler
* C, compiled using GCC
* C Sharp, compiled using Mono
* FORTRAN 77 with record extensions, compiled using GFortran
* Java
* Pascal, compiled using the FreePascal compiler
* Rust
* PL/I using the [Iron Springs PL/I compiler](http://www.iron-spring.com/) compiler (note: the variable `$PLIPATH` must be set to point to the root of the PL/I installation)

The examples are very simple and do not always reflect best programming practices.
The same calculator application is implemented in each language.
To test them under a UNIX-like environment, change into the target directory and type `./calc`.

This project was an experiment and proof of concept to write a Yacc-like tool that works smoothly with any programming language.
There are likely still bugs.

