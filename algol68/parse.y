
%{
	MODE YYSTYPE = UNION(INT, STRING);

	PROC as string = (YYSTYPE u) STRING:
	BEGIN
		CASE u IN
		(STRING s): s
		ESAC
	END;

	PROC as integer = (YYSTYPE u) INT:
	BEGIN
		CASE u IN
		(INT i): i
		ESAC
	END;

	YYSTYPE yylval;

	MODE DEFINITION = STRUCT(STRING name, INT value, REF DEFINITION next);
	REF DEFINITION globals := NIL;

	BOOL is buffered;
	CHAR buffered char;
	BOOL file ended;

	PROC getchar = CHAR:
	BEGIN
		IF is buffered THEN
			is buffered := FALSE
		ELIF file ended THEN
			buffered char := REPR 0
		ELSE
			FILE input := stand in;
			on logical file end(input, (REF FILE f)BOOL: BEGIN file ended := TRUE; buffered char := REPR 0; GO TO leave END);
			get(input, buffered char);
		leave:
			EMPTY
		FI;
		buffered char
	END;

	PROC ungetc = (CHAR c)VOID:
	BEGIN
		buffered char := c;
		is buffered := TRUE
	END;

	PROC yylex = INT:
	BEGIN
		INT yytype;
		CHAR c;
		WHILE
			c := getchar;
			c = " "
		DO
			EMPTY
		OD;

		IF "0" <= c AND c <= "9" THEN
			INT value := ABS c - ABS "0";
			WHILE
				c := getchar;
				"0" <= c AND c <= "9"
			DO
				value := value * 10 + ABS c - ABS "0"
			OD;
			ungetc(c);
			yylval := value;
			yytype := integer
		ELIF "A" <= c AND c <= "Z" OR "a" <= c AND c <= "z" OR c = "_" THEN
			STRING name := c;
			WHILE
				c := getchar;
				"A" <= c AND c <= "Z" OR "a" <= c AND c <= "z" OR c = "_" OR "0" <= c AND c <= "9"
			DO
				name := name + c
			OD;
			ungetc(c);
			yylval := name;
			yytype := identifier
		ELSE
			yytype := ABS c
		FI;
		yytype
	END;

	PROC yyerror = (STRING s) VOID:
	BEGIN
		print((s, newline))
	END;
%}

%token IDENTIFIER
%token INTEGER

%start program
%%

program
	: %empty
	| program line ';'
	;

line
	: IDENTIFIER '=' expression
		{
			globals := HEAP DEFINITION := DEFINITION(as string($1), as integer($3), globals)
		}
	| expression
		{
			print((as integer($1), newline))
		}
	;

primary
	: IDENTIFIER
		{
			REF DEFINITION current definition := globals;
			WHILE REF DEFINITION(current definition) :/=: NIL DO
				IF name OF current definition = as string($1) THEN
					$$ := value OF current definition;
					GO TO done
				FI;
				current definition := next OF current definition
			OD;
			print(("Undefined name ", as string($1), newline));
			$$ := 0;
		done:
			EMPTY
		}
	| INTEGER
		{
			$$ := $1
		}
	| '(' expression ')'
		{
			$$ := $2
		}
	;

factor
	: primary
		{
			$$ := $1
		}
	| '-' factor
		{
			$$ := -as integer($2)
		}
	;

term
	: factor
		{
			$$ := $1
		}
	| term '*' factor
		{
			$$ := as integer($1) * as integer($3)
		}
	| term '/' factor
		{
			IF as integer($3) = 0 THEN
				print(("Division by zero", newline));
				$$ := 0
			ELSE
				$$ := as integer($1) % as integer($3)
			FI
		}
	;

expression
	: term
		{
			$$ := $1
		}
	| expression '+' term
		{
			$$ := as integer($1) + as integer($3)
		}
	| expression '-' term
		{
			$$ := as integer($1) - as integer($3)
		}
	;

%%

	VOID(yyparse)

