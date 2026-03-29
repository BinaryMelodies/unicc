# UniCC - A universal compiler compiler

UniCC is a programming language agnostic Yacc-like parser generator, written in Python.
It takes a programming language template file (typically with a `.def` extension) a grammar file (with a `.y` extension), and generates a LALR parser.

Instead of generating a parser, UniCC can also do the parsing on the fly, and the Yacc grammar it uses is stored in its parsed form in the code.

The repository contains examples for a couple of target languages:
* BASIC, compiled using [the FreeBASIC compiler](https://www.freebasic.net/)
* C, compiled using [the GNU Compiler Collection](https://gcc.gnu.org/)
* C Sharp, compiled using [Mono](https://www.mono-project.com/)
* FORTRAN 77 with or without record extensions, compiled using GFortran (part of the GNU Compiler Collection)
* Java
* Pascal, compiled using [the FreePascal compiler](https://www.freepascal.org/)
* Rust
* PL/I using the [Iron Springs PL/I compiler](http://www.iron-spring.com/) compiler (note: the variable `$PLIPATH` must be set to point to the root of the PL/I installation)
* ALGOL 60 using [GNU MARST](https://www.gnu.org/software/marst/marst.html)
* ALGOL W using [AWE](https://github.com/glynawe/awe)
* Simula using [GNU CIM](https://www.gnu.org/software/cim/)
* ALGOL 68 using the ELLA ALGOL 68RS compiler (note: the variable `$A68C` is expected to point to a script that generates a binary provided by the `-o` option)

The examples are very simple and do not always reflect best programming practices.
The same calculator application is implemented in each language.
To test them under a UNIX-like environment, change into the target directory and type `./calc`.

This project was an experiment and proof of concept to write a Yacc-like tool that works smoothly with any programming language.
There are likely still bugs.

