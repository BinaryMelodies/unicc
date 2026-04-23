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
			(*struct definition * definition = malloc(sizeof(struct definition));
			definition->name = $1.s;
			definition->value = $3.i;
			definition->next = globals;
			globals = definition;*)
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
			(*for(struct definition * definition = globals; definition; definition = definition->next)
			{
				if(strcmp($1.s, definition->name) == 0)
				{
					$$.i = definition->value;
					goto done;
				}
			}
			fprintf(stderr, "Undefined name %s\n", $1.s);
			$$.i = 0;
		done:
			free($1.s);*)
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

