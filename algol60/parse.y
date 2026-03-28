
%{
	Boolean is buffered;
	integer buffered character;

	integer yylval;

	integer procedure getchar;
	begin
		if is buffered then
			is buffered := false
		else
			inchar(0, "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_+-*/=;", buffered character);

		getchar := buffered character
	end;

	procedure ungetc(c);
		value c;
		integer c;
	begin
		is buffered := true;
		buffered character := c
	end;

	Boolean procedure isalnum(c);
		value c;
		integer c;
	begin
		isalnum := 0 < c & c <= 64
	end;

	integer procedure read identifier;
	begin
		integer identifier;
		integer character;
		integer length;

		identifier := 0;
		character := getchar;
		for length := 0, length + 1 while isalnum(character) do
		begin
			if length < 5 then
				identifier := identifier + character * (64 ** length);
			character := getchar
		end;
		ungetc(character);
		read identifier := identifier
	end;

	procedure write identifier(identifier);
		value identifier;
		integer identifier;
	begin
		for identifier := identifier, identifier % 64 while identifier != 0 do
		begin
			outchar(1, "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_", identifier - identifier % 64 * 64)
		end
	end;

	integer procedure yylex;
	begin
		integer character;

		character := 0;
		for character := getchar while character = 0 do begin dummy: end;

		if character <= 11 then
		begin
			yylval := character - 1;
			for character := getchar while 0 < character & character <= 11 do
				yylval := yylval * 10 + character - 1;
			ungetc(character);
			yylex := INTEGER
		end
		else if character <= 63 then
		begin
			ungetc(character);
			yylval := read identifier;
			yylex := IDENTIFIER
		end
		else if character = 64 then
		begin
			comment + ;
			yylex := 43
		end
		else if character = 65 then
		begin
			comment - ;
			yylex := 45
		end
		else if character = 66 then
		begin
			comment * ;
			yylex := 42
		end
		else if character = 67 then
		begin
			comment / ;
			yylex := 47
		end
		else if character = 68 then
		begin
			comment = ;
			yylex := 61
		end
		else if character = 69 then
		begin
			comment semicolon ;
			yylex := 59
		end
		else if character = 70 then
		begin
			comment . ;
			yylex := 46
		end
		else
		begin
			yylex := 0
		end
	end;

	procedure yyerror(s);
		string s;
	begin
		outstring(1, s)
	end;
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
		}
	| expression
		{
			outinteger(1, $1);
			outstring(1, "\n")
		}
	;

primary
	: IDENTIFIER
		{
			$$ := $1
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
			$$ := -$2
		}
	;

term
	: factor
		{
			$$ := $1
		}
	| term '*' factor
		{
			$$ := $1 * $3
		}
	| term '/' factor
		{
			if $3 = 0 then
			begin
				outstring(1, "Division by zero\n");
				$$ := 0
			end
			else
				$$ := $1 / $3
		}
	;

expression
	: term
		{
			$$ := $1
		}
	| expression '+' term
		{
			$$ := $1 + $3
		}
	| expression '-' term
		{
			$$ := $1 - $3
		}
	;

%%

	is buffered := false;
	yyinit;
	yyparse

