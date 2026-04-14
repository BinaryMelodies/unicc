
%{
	Boolean is buffered;
	integer buffered character;

	integer yylval;

	integer definition count;
	integer array definition names[0:127];
	integer array definition values[0:127];

	integer procedure getchar;
	begin
		comment
			ALGOL 60 has no concept of a character set, so we must provide a list of characters to index
			When inchar is invoked, it will search the string for the corresponding character and return a 1 based index to it
			If the character is not found, a 0 value is returned;

		if is buffered then
			is buffered := false
		else
			inchar(0, "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_+-*/=();", buffered character);

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
		isalnum := 0 < c & c < 64
	end;

	integer procedure read identifier;
	begin
		comment
			ALGOL 60 has no string processing implemented
			So here a 64 character set is used internally to store strings in integer variables
			Assuming a 32-bit integer, this means we can store up to 5 characters per name;
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

		if character < 11 then
		begin
			yylval := character - 1;
			for character := getchar while 0 < character & character <= 11 do
				yylval := yylval * 10 + character - 1;
			ungetc(character);
			yylex := INTEGER
		end
		else if character < 64 then
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
			comment ( ;
			yylex := 40
		end
		else if character = 70 then
		begin
			comment ) ;
			yylex := 41
		end
		else if character = 71 then
		begin
			comment semicolon ;
			yylex := 59
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

	integer array parser val stk[0:127];
	integer parser yyval;

	procedure store yylval(stk pos);
		value stk pos;
		integer stk pos;
	begin
		parser val stk[stk pos] := yylval
	end;

	procedure store yyval(stk pos);
		value stk pos;
		integer stk pos;
	begin
		parser val stk[stk pos] := parser yyval
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
			if definition count < 128 then
			begin
				definition names[definition count] := parser val stk[$1];
				definition values[definition count] := parser val stk[$3];
				definition count := definition count + 1
			end
			else
			begin
				outstring(1, "Too many variables\n")
			end
		}
	| expression
		{
			outinteger(1, parser val stk[$1]);
			outstring(1, "\n")
		}
	;

primary
	: IDENTIFIER
		{
			integer index;
			for index := 0 step 1 until definition count - 1 do
			begin
				if definition names[index] = parser val stk[$1] then
				begin
					parser yyval := definition values[index];
					go to done
				end
			end;
			outstring(1, "Undefined name ");
			write identifier(parser val stk[$1]);
			outstring(1, "\n");
			parser yyval := 0;
		done:
		}
	| INTEGER
		{
			parser yyval := parser val stk[$1]
		}
	| '(' expression ')'
		{
			parser yyval := parser val stk[$2]
		}
	;

factor
	: primary
		{
			parser yyval := parser val stk[$1]
		}
	| '-' factor
		{
			parser yyval := -parser val stk[$2]
		}
	;

term
	: factor
		{
			parser yyval := parser val stk[$1]
		}
	| term '*' factor
		{
			parser yyval := parser val stk[$1] * parser val stk[$3]
		}
	| term '/' factor
		{
			if parser val stk[$3] = 0 then
			begin
				outstring(1, "Division by zero\n");
				parser yyval := 0
			end
			else
				parser yyval := parser val stk[$1] % parser val stk[$3]
		}
	;

expression
	: term
		{
			parser yyval := parser val stk[$1]
		}
	| expression '+' term
		{
			parser yyval := parser val stk[$1] + parser val stk[$3]
		}
	| expression '-' term
		{
			parser yyval := parser val stk[$1] - parser val stk[$3]
		}
	;

%%

	is buffered := false;
	yyinit;
	yyparse

