
%{

SET TALK OFF
CLOSE DATABASES

PUBLIC bufline, buflinepos

bufline = ""
buflinepos = 1

PUBLIC IDENTIFIER, INTEGER
IDENTIFIER = 256
INTEGER = 257

CREATE CURSOR defines (name c(16), value n(10))

CREATE CURSOR yylval (s c(16), i n(10))
APPEND BLANK

DO yyparse

SELECT yylval
USE
SET TALK ON
CANCEL

%}

%define yystype {(s c(16), i n(10))}

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
			INSERT INTO defines (name, value) VALUES ($1.s, $3.i)
		}
	| expression
		{
			SET TALK ON
			? $1.i
			SET TALK OFF
		}
	;

primary
	: IDENTIFIER
		{
			SELECT defines
			LOCATE FOR name = $1.s
			IF FOUND()
				$$.i = defines.value
			ELSE
				SET TALK ON
				? "Undefined name", $1.s
				SET TALK OFF
				$$.i = 0
			ENDIF
		}
	| INTEGER
	| '(' expression ')'
		{
			$$.i = $2.i
		}
	;

factor
	: primary
	| '-' factor
		{
			$$.i = -$2.i
		}
	;

term
	: factor
	| term '*' factor
		{
			$$.i = $1.i * $3.i
		}
	| term '/' factor
		{
			$$.iF $3.i = 0
				SET TALK ON
				? "Division by zero"
				SET TALK OFF
				$$.i = 0
			ELSE
				$$.i = INT($1.i / $3.i)
			ENDIF
		}
	;

expression
	: term
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

FUNCTION GetChar
	DO WHILE .T.
		DO CASE
			CASE buflinepos < LEN(bufline)
				buflinepos = buflinepos + 1
				RETURN ASC(SUBSTR(bufline, buflinepos, 1))
			CASE buflinepos = LEN(bufline)
				buflinepos = buflinepos + 1
				RETURN 10
			OTHERWISE
				ACCEPT TO bufline
				buflinepos = 0
		ENDCASE
	ENDDO

PROCEDURE UnGetChar
	IF buflinepos > 0
		buflinepos = buflinepos - 1
	ENDIF

FUNCTION yylex
	c = GetChar()
	DO WHILE c = 32 OR c = 9
		c = GetChar()
	ENDDO

	DO CASE
		CASE 48 <= c AND c <= 57
			i = c - 48
			c = GetChar()
			DO WHILE 48 <= c AND c <= 57
				i = m.i * 10 + c - 48
				c = GetChar()
			ENDDO
			DO UnGetChar
			SELECT yylval
			GATHER MEMVAR MEMO
			RETURN INTEGER
		CASE 65 <= c AND c <= 90 OR 97 <= c AND c <= 122 OR c = 95
			s = CHR(c)
			c = GetChar()
			DO WHILE 65 <= c AND c <= 90 OR 97 <= c AND c <= 122 OR c = 95 OR 48 <= c AND c <= 57
				s = m.s + CHR(c)
				c = GetChar()
			ENDDO
			DO UnGetChar
			SELECT yylval
			GATHER MEMVAR MEMO
			RETURN IDENTIFIER
		OTHERWISE
			RETURN c
	ENDCASE

PROCEDURE yyerror
	PARAMETER s

	SET TALK ON
	? s
	SET TALK OFF

