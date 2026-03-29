
%{
	class YYSTYPE;
	begin
	end;

	YYSTYPE class YYInteger(i);
		integer i;
	begin
	end;

	YYSTYPE class YYString(s);
		text s;
	begin
	end;

	class Definition(defname, defvalue, next);
		text defname;
		integer defvalue;
		ref(Definition) next;
	begin
	end;

	ref(YYSTYPE) yylval;
	ref(Definition) globals;

	character buffered_character;
	boolean has_buffered_character;

	character procedure getchar;
	begin
		if has_buffered_character then
		begin
			getchar := buffered_character;
			has_buffered_character := false;
		end
		else
		begin
			getchar := sysin.inchar;
		end
	end;

	procedure ungetc(c);
		character c;
	begin
		buffered_character := c;
		has_buffered_character := true
	end;
%}

%token IDENTIFIER
%token T_INTEGER

%start program
%%

program
	: %empty
	| program line ';'
	;

line
	: IDENTIFIER '=' expression
		{
			globals :- new Definition($1 qua YYString.s, $3 qua YYInteger.i, globals)
		}
	| expression
		{
			outint($1 qua YYInteger.i, 10);
			outimage
		}
	;

primary
	: IDENTIFIER
		{
			ref(Definition) current_definition;
			if globals =/= none then
			begin
				for current_definition :- globals, current_definition.next while current_definition =/= none do
				begin
					if current_definition.defname = $1 qua YYString.s then
					begin
						$$ :- new YYInteger(current_definition.defvalue);
						go to done
					end
				end
			end;
			outtext("Undefined name ");
			outtext($1 qua YYString.s);
			outimage;
			$$ :- new YYInteger(0);
		done:
		}
	| T_INTEGER
		{
			$$ :- $1
		}
	| '(' expression ')'
		{
			$$ :- $2
		}
	;

factor
	: primary
		{
			$$ :- $1
		}
	| '-' factor
		{
			$$ :- new YYInteger(-$2 qua YYInteger.i)
		}
	;

term
	: factor
		{
			$$ :- $1
		}
	| term '*' factor
		{
			$$ :- new YYInteger($1 qua YYInteger.i * $3 qua YYInteger.i)
		}
	| term '/' factor
		{
			if $3 qua YYInteger.i = 0 then
			begin
				outtext("Division by zero");
				outimage;
				$$ :- new YYInteger(0)
			end
			else
				$$ :- new YYInteger($1 qua YYInteger.i / $3 qua YYInteger.i)
		}
	;

expression
	: term
		{
			$$ :- $1
		}
	| expression '+' term
		{
			$$ :- new YYInteger($1 qua YYInteger.i + $3 qua YYInteger.i)
		}
	| expression '-' term
		{
			$$ :- new YYInteger($1 qua YYInteger.i - $3 qua YYInteger.i)
		}
	;

%%

	integer procedure yylex;
	begin
		character c;
		c := getchar;

		while c = ' ' or c = '!9!' !HT; do
			c := getchar;

		if c = '!25!' !EOF; then
		begin
			yylex := 0
		end
		else if '0' <= c and c <= '9' then
		begin
			yylval :- new YYInteger(rank(c) - rank('0'));
			c := getchar;
			while '0' <= c and c <= '9' do
			begin
				yylval qua YYInteger.i := yylval qua YYInteger.i * 10 + rank(c) - rank('0');
				c := getchar;
			end;
			ungetc(c);
			yylex := T_INTEGER
		end
		else if 'A' <= c and c <= 'Z' or 'a' <= c and c <= 'z' or c = '_' then
		begin
			yylval :- new YYString(blanks(1));
			yylval qua YYString.s.setpos(1);
			yylval qua YYString.s.putchar(c);
			c := getchar;
			while 'A' <= c and c <= 'Z' or 'a' <= c and c <= 'z' or c = '_' or '0' <= c and c <= '9' do
			begin
				yylval qua YYString.s :- yylval qua YYString.s & " ";
				yylval qua YYString.s.setpos(yylval qua YYString.s.length);
				yylval qua YYString.s.putchar(c);
				c := getchar;
			end;
			ungetc(c);
			yylex := IDENTIFIER
		end
		else
		begin
			yylex := rank(c)
		end
	end;

	procedure yyerror(s);
		text s;
	begin
		outtext(s);
		outimage
	end;

	has_buffered_character := false;
	yyparse

