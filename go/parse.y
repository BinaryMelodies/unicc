
%{
package main

import "bufio"
import "fmt"
import "os"
import "unicode"

type YYSTYPE struct {
	i int
	s string
}
var yylval YYSTYPE

var globals map[string]int = make(map[string]int)
%}

%token IDENTIFIER
%token INTEGER

%start program
%%

program
	: %empty
	| program line '\n'
	;

line
	: IDENTIFIER '=' expression
		{
			globals[$1.s] = $3.i
		}
	| expression
		{
			fmt.Println($1.i)
		}
	;

primary
	: IDENTIFIER
		{
			value, is_element := globals[$1.s]
			if is_element {
				$$.i = value
			} else {
				fmt.Println("Undefined name", $1.s)
				$$.i = 0
			}
		}
	| INTEGER
		{
			$$.i = $1.i
		}
	| '(' expression ')'
		{
			$$.i = $2.i
		}
	;

factor
	: primary
		{
			$$.i = $1.i
		}
	| '-' factor
		{
			$$.i = -$2.i
		}
	;

term
	: factor
		{
			$$.i = $1.i
		}
	| term '*' factor
		{
			$$.i = $1.i * $3.i
		}
	| term '/' factor
		{
			if $3.i == 0 {
				fmt.Println("Division by zero")
				$$.i = 0
			} else {
				$$.i = $1.i / $3.i
			}
		}
	;

expression
	: term
		{
			$$.i = $1.i
		}
	| expression '+' term
		{
			$$.i = $1.i + $3.i
		}
	| expression '-' term
		{
			$$.i = $1.i - $3.i
		}
	;

%%

var input * bufio.Reader

func yylex() int {
	var c byte
	var e error

	for c, e = input.ReadByte(); c == ' ' || c == '\t'; c, e = input.ReadByte() { }

	if e != nil {
		return _EOF
	} else if unicode.IsDigit(rune(c)) {
		yylval.i = int(c - '0')
		for c, e = input.ReadByte(); e == nil && unicode.IsDigit(rune(c)); c, e = input.ReadByte() {
			yylval.i = yylval.i * 10 + int(c - '0')
		}
		input.UnreadByte()
		return INTEGER
	} else if unicode.IsLetter(rune(c)) || c == '_' {
		yylval.s = string(c)
		for c, e = input.ReadByte(); e == nil && (unicode.IsLetter(rune(c)) || unicode.IsDigit(rune(c)) || c == '_'); c, e = input.ReadByte() {
			yylval.s = yylval.s + string(c)
		}
		input.UnreadByte()
		return IDENTIFIER
	} else {
		return int(c)
	}
}

func yyerror(s string) {
	fmt.Println(s)
}

func main() {
	input = bufio.NewReader(os.Stdin)
	os.Exit(yyparse())
}

