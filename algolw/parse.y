
%{
	record YYInteger(integer as_integer);
	record YYString(string(16) as_string);
	record Definition(string(16) defined_name; integer defined_value; reference(Definition) next_definition);

	reference(YYInteger, YYString) yylval;
	reference(Definition) globals;

	string(80) buffered_line;
	integer buffer_position;

	integer procedure getchar;
	begin
		integer char;

		if XCPLIMIT(ENDFILE) = 0 then
		begin
			char := 0;
		end
		else if buffer_position = 80 then
		begin
			char := 21; % We might as well use the EBCDIC code for new line %
			buffer_position := buffer_position + 1;
		end
		else if buffer_position > 80 then
		begin
			readcard(buffered_line);
			buffer_position := 0;
			char := decode(buffered_line(buffer_position | 1));
			buffer_position := buffer_position + 1
		end
		else
		begin
			char := decode(buffered_line(buffer_position | 1));
			buffer_position := buffer_position + 1
		end;
		char
	end;

	procedure ungetc;
	begin
		if buffer_position > 0 then
			buffer_position := buffer_position - 1;
	end;
%}

%define yystype {reference(YYInteger, YYString)}

%token IDENTIFIER
%token T_INTEGER

%start program
%%

program
	: %empty
	| program line '\n'
	;

line
	: IDENTIFIER '=' expression
		{
			globals := Definition(as_string($1), as_integer($3), globals)
		}
	| expression
		{
			write(as_integer($1));
			iocontrol(2)
		}
	;

primary
	: IDENTIFIER
		{
			reference(Definition) current_definition;
			current_definition := globals;
			while current_definition ¬= null do
			begin
				if defined_name(current_definition) = as_string($1) then
				begin
					$$ := YYInteger(defined_value(current_definition));
					go to done
				end;
				current_definition := next_definition(current_definition)
			end;
			write("Undefined name ", as_string($1));
			$$ := YYInteger(0);
		done:
		}
	| T_INTEGER
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
			$$ := YYInteger(-as_integer($2))
		}
	;

term
	: factor
		{
			$$ := $1
		}
	| term '*' factor
		{
			$$ := YYInteger(as_integer($1) * as_integer($3))
		}
	| term '/' factor
		{
			if as_integer($3) = 0 then
			begin
				write("Division by zero");
				$$ := YYInteger(0)
			end
			else
				$$ := YYInteger(as_integer($1) div as_integer($3))
		}
	;

expression
	: term
		{
			$$ := $1
		}
	| expression '+' term
		{
			$$ := YYInteger(as_integer($1) + as_integer($3))
		}
	| expression '-' term
		{
			$$ := YYInteger(as_integer($1) - as_integer($3))
		}
	;

%%

	integer procedure yylex;
	begin
		% The ALGOL W compiler uses EBCDIC, so we have to interpret these as EBCDIC values! %

		logical procedure isalpha(integer value c);
		begin
			c = 109 %_%
			or (129 %a% <= c and c <= 137 %i%)
			or (145 %j% <= c and c <= 153 %r%)
			or (162 %s% <= c and c <= 169 %z%)
			or (193 %A% <= c and c <= 201 %I%)
			or (209 %J% <= c and c <= 217 %R%)
			or (226 %S% <= c and c <= 233 %Z%)
		end;

		integer char;
		integer yytype;

		char := getchar;
		while char = 5 %tab% or char = 64 %space% do
			char := getchar;

		if 240 %0% <= char and char <= 249 %9% then
		begin
			yylval := YYInteger(char - 240);
			char := getchar;
			while 240 %0% <= char and char <= 249 %9% do
			begin
				as_integer(yylval) := as_integer(yylval) * 10 + char - 240;
				char := getchar;
			end;
			ungetc;
			yytype := T_INTEGER;
		end
		else if isalpha(char) then
		begin
			integer length;
			yylval := YYString(code(char));
			length := 1;
			char := getchar;
			while isalpha(char) or 240 %0% <= char and char <= 249 %9% do
			begin
				as_string(yylval)(length | 1) := code(char);
				char := getchar;
				length := length + 1;
			end;
			ungetc;
			yytype := IDENTIFIER;
		end
		else if char = 21 %\n% then
		begin
			yytype := 10
		end
		else if char = 77 %(% then
		begin
			yytype := 40
		end
		else if char = 78 %+% then
		begin
			yytype := 43
		end
		else if char = 92 %*% then
		begin
			yytype := 42
		end
		else if char = 93 %)% then
		begin
			yytype := 41
		end
		else if char = 94 %semicolon% then
		begin
			yytype := 59
		end
		else if char = 96 %-% then
		begin
			yytype := 45
		end
		else if char = 97 %/% then
		begin
			yytype := 47
		end
		else if char = 126 %=% then
		begin
			yytype := 61
		end
		else
		begin
			yytype := 0
		end;
		yytype
	end;

	procedure yyerror(string value s);
	begin
		write(s)
	end;

	integer yytext;

	yyinit;
	readcard(buffered_line);
	buffer_position := 0;
	ENDFILE := EXCEPTION(, 1, , false, " ");
	globals := null;
	yytext := yyparse

