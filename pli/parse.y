
%{
calc: procedure options(main);

	declare 1 yylval /*union*/, /* assigning unions is not allowed */
		2 i fixed,
		2 s character(16) varying;

	declare 1 globals,
		2 count fixed initial(0),
		2 definition(128),
			3 name character(16) varying,
			3 value fixed;

	define: procedure(name, value);
		declare
			name character(16) varying,
			value fixed;

		globals.count = globals.count + 1;
		globals.definition(globals.count).name = name;
		globals.definition(globals.count).value = value;
	end define;
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
			call define($1.s, $3.i);
		}
	| expression
		{
			put skip list($1.i);
		}
	;

primary
	: IDENTIFIER
		{
			declare i fixed;
		search_name:
			do i = 1 to globals.count;
				if globals.definition(i).name = $1.s then do;
					$$.i = globals.definition(i).value;
					leave search_name;
				end;
			end;
			if i > globals.count then do;
				put skip list(i, globals.count);
				put skip list("Undefined name ", $1.s);
				$$.i = 0;
			end;
		}
	| INTEGER
		{
			$$.i = $1.i;
		}
	| '(' expression ')'
		{
			$$.i = $2.i;
		}
	;

factor
	: primary
		{
			$$.i = $1.i;
		}
	| '-' factor
		{
			$$.i = -$2.i;
		}
	;

term
	: factor
		{
			$$.i = $1.i;
		}
	| term '*' factor
		{
			$$.i = $1.i * $3.i;
		}
	| term '/' factor
		{
			if $3.i = 0 then do;
				put skip list('Division by zero');
				$$.i = 0;
			end;
			else do;
				$$.i = $1.i / $3.i;
			end;
		}
	;

expression
	: term
		{
			$$.i = $1.i;
		}
	| expression '+' term
		{
			$$.i = $1.i + $3.i;
		}
	| expression '-' term
		{
			$$.i = $1.i - $3.i;
		}
	;

%%

	declare 1 stdin_buffer,
		2 occupied bit(1) initial('0'B),
		2 value character;

	getchar: procedure returns(character);
		declare c character;

		on endfile(sysin) do;
			return('00'X);
		end;

		if stdin_buffer.occupied then do;
			stdin_buffer.occupied = '0'B;
			return(stdin_buffer.value);
		end;
		else do;
			get edit(c)(a(1));
			return(c);
		end;
	end getchar;

	ungetchar: procedure(c);
		declare c character;
		stdin_buffer.occupied = '1'B;
		stdin_buffer.value = c;
	end ungetchar;

	yylex: procedure returns(fixed);
		declare c character;
		declare b unsigned fixed binary(8) based;

		c = getchar;

		do while(addr(c)->b = '20'XU);
			c = getchar;
		end;

		if '30'XU <= addr(c)->b & addr(c)->b <= '39'XU then do;
			yylval.i = addr(c)->b - '30'XU;
			c = getchar;
			do while('30'XU <= addr(c)->b & addr(c)->b <= '39'XU);
				yylval.i = yylval.i * 10 + addr(c)->b - '30'XU;
				c = getchar;
			end;
			call ungetchar(c);
			return(INTEGER);
		end;
		else if ('41'XU <= addr(c)->b & addr(c)->b <= '5A'XU) | ('61'XU <= addr(c)->b & addr(c)->b <= '7A'XU) | (addr(c)->b = '5F'XU) then do;
			yylval.s = c;
			c = getchar;
			do while(('41'XU <= addr(c)->b & addr(c)->b <= '5A'XU) | ('61'XU <= addr(c)->b & addr(c)->b <= '7A'XU) | (addr(c)->b = '5F'XU) | ('30'XU <= addr(c)->b & addr(c)->b <= '39'XU));
				yylval.s = yylval.s || c;
				c = getchar;
			end;
			call ungetchar(c);
			return(IDENTIFIER);
		end;

		return(addr(c)->b);
	end yylex;

	yyerror: procedure(message);
		declare message character(*) varying;
		put skip list(message);
	end yyerror;

	yylval.i = 0;
	yylval.s = '';

	declare result fixed;
	result = yyparse;
end calc;

