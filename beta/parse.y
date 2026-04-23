%{
ORIGIN '~beta/basiclib/betaenv'
---- program: descriptor ----
(#
	YYSTYPE: (#
		i:< (#
			result: @Integer
		do inner
		exit result
		#);

		s:< (#
			result: ^Text
		do inner
		exit result[]
		#)
	#);

	YYINTEGER: YYSTYPE(#
		value: @Integer;
		i::< (#
		do
			value -> result
		#)
	enter value
	exit value
	#);

	YYSTRING: YYSTYPE(#
		value: @Text;
		s::< (#
		do
			value[] -> result[]
		#)
	enter value
	exit value
	#);

	yylval: ^YYSTYPE;

	Definition: (#
		name: ^Text;
		value: @Integer;
		next: ^Definition;
	enter (name[], value)
	do
		globals[] -> next[];
		this(Definition)[] -> globals[]
	#);

	globals: ^Definition;
%}

%token T_IDENTIFIER
%token T_INTEGER

%start program
%%

program
	: %empty
	| program line '\n'
	;

line
	: T_IDENTIFIER '=' expression
		{
			(#
				new_definition: ^Definition
			do
				&Definition[] -> new_definition[];
				($1.s, $3.i) -> new_definition
			#)
		}
	| expression
		{
			$1.i -> putint;
			putline
		}
	;

primary
	: T_IDENTIFIER
		{
			&YYINTEGER[] -> $$[];
			(#
				current_definition: ^Definition
			do
				globals[] -> current_definition[];
				Lookup: (#
				do
					(if true
					// current_definition[] = NONE then
						'Undefined name ' -> puttext;
						$1.s -> puttext;
						putline;
						0 -> ($$[] -> qua(# as::YYINTEGER #)).value
					// $1.s -> current_definition.name.equal then
						current_definition.value -> ($$[] -> qua(# as::YYINTEGER #)).value
					else
						current_definition.next[] -> current_definition[];
						restart Lookup
					if)
				#)
			#)
		}
	| T_INTEGER
		{
			$1[] -> $$[]
		}
	| '(' expression ')'
		{
			$2[] -> $$[]
		}
	;

factor
	: primary
		{
			$1[] -> $$[]
		}
	| '-' factor
		{
			&YYINTEGER[] -> $$[];
			-$2.i -> ($$[] -> qua(# as::YYINTEGER #)).value
		}
	;

term
	: factor
		{
			$1[] -> $$[]
		}
	| term '*' factor
		{
			&YYINTEGER[] -> $$[];
			$1.i * $3.i -> ($$[] -> qua(# as::YYINTEGER #)).value
		}
	| term '/' factor
		{
			&YYINTEGER[] -> $$[];
			(if $3.i = 0 then
				'Division by zero' -> putline;
				0 -> ($$[] -> qua(# as::YYINTEGER #)).value
			else
				$1.i div $3.i -> ($$[] -> qua(# as::YYINTEGER #)).value
			if)
		}
	;

expression
	: term
		{
			$1[] -> $$[]
		}
	| expression '+' term
		{
			&YYINTEGER[] -> $$[];
			$1.i + $3.i -> ($$[] -> qua(# as::YYINTEGER #)).value
		}
	| expression '-' term
		{
			&YYINTEGER[] -> $$[];
			$1.i - $3.i -> ($$[] -> qua(# as::YYINTEGER #)).value
		}
	;

%%

	buffer: @Char;
	is_buffered: @Boolean;
	getchar: (#
		do
			(if is_buffered then
				false -> is_buffered
			else
				get -> buffer
			if)
		exit
			buffer
	#);

	ungetc: (#
	enter buffer
	do
		true -> is_buffered
	#);

	yylex:
	(#
		c: @Char;
		i: ^YYINTEGER;
		s: ^YYSTRING;
		token: @Integer;
	do
		Loop: (# do
			getchar -> c;
			(if (c = ' ') or (c = Ascii.HT) then
				restart Loop
			if)
		#);

		(if true
		// c -> Ascii.isDigit then
			&YYINTEGER[] -> i[];
			c - '0' -> i;
			Loop: (# do
				getchar -> c;
				(if c -> Ascii.isDigit then
					i * 10 + c - '0' -> i;
					restart Loop
				if)
			#);
			c -> ungetc;
			i[] -> yylval[];
			T_INTEGER -> token
		// (c -> Ascii.isLetter) or (c = '_') then
			&YYSTRING[] -> s[];
			c -> s;
			Loop: (# do
				getchar -> c;
				(if (c -> Ascii.isLetter) or (c = '_') or (c -> Ascii.isDigit) then
					c -> s.value.put;
					restart Loop
				if)
			#);
			c -> ungetc;
			s[] -> yylval[];
			T_IDENTIFIER -> token
		// c = 255 then
			_EOF -> token
		else
			c -> token
		if)
	exit
		token
	#);

	yyerror: (#
		s: @Text
	enter s

	do
		s[] -> putline
	#)

do
	yyparse
#)

