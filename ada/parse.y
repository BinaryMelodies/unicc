
%{
with Ada.Text_IO;
with Ada.Characters.Latin_1;
with Ada.Characters.Handling;
with Ada.Strings.Unbounded;
with Ada.IO_Exceptions;

procedure Parse is
	type TokenValueType is (EmptyToken, IntegerToken, StringToken);
	type YYSTYPE(ValueType : TokenValueType := EmptyToken) is
		record
			case ValueType is
				when IntegerToken =>
					i : Integer;
				when StringToken =>
					s : Ada.Strings.Unbounded.Unbounded_String;
				when others =>
					null;
			end case;
		end record;

	yylval : YYSTYPE := (ValueType => EmptyToken);

	procedure YYError(s : String) is
	begin
		Ada.Text_IO.Put_Line(s);
	end YYError;

__ADA_INSERT_TOKEN_TYPES__

	next_eol : Boolean := False;

	function YYLex return TokenType is
		c : Character;
		EOL : Boolean;
		value : Integer;
		text : Ada.Strings.Unbounded.Unbounded_String;
	begin
		if next_eol then
			Ada.Text_IO.Get(c);
			if c = ' ' or c = Ada.Characters.Latin_1.HT then
				Ada.Text_IO.Look_Ahead(c, EOL);
				next_eol := False;
			else
				-- keep next_eol True so that we know c is not simply a look ahead but a read character
				EOL := False;
			end if;
		else
			Ada.Text_IO.Look_Ahead(c, EOL);
		end if;

		while not EOL and (c = ' ' or c = Ada.Characters.Latin_1.HT) loop
			Ada.Text_IO.Get(c);
			Ada.Text_IO.Look_Ahead(c, EOL);
		end loop;

		if EOL then
			next_eol := True;
			yylval := (ValueType => EmptyToken);
			return Character'Pos(Ada.Characters.Latin_1.LF);
		else
			if not next_eol then
				-- c was just looked ahead
				Ada.Text_IO.Get(c);
			end if;
			next_eol := False;
		end if;

		if Ada.Characters.Handling.Is_Digit(c) then
			value := Character'Pos(c) - Character'Pos('0');
			Ada.Text_IO.Look_Ahead(c, EOL);
			while not EOL and Ada.Characters.Handling.Is_Digit(c) loop
				Ada.Text_IO.Get(c);
				value := 10 * value + Character'Pos(c) - Character'Pos('0');
				Ada.Text_IO.Look_Ahead(c, EOL);
			end loop;
			yylval := (IntegerToken, value);
			return T_INTEGER;
		elsif Ada.Characters.Handling.Is_Letter(c) or c = '_' then
			Ada.Strings.Unbounded.Append(text, c);
			Ada.Text_IO.Look_Ahead(c, EOL);
			while not EOL and (Ada.Characters.Handling.Is_Letter(c) or c = '_' or Ada.Characters.Handling.Is_Digit(c)) loop
				Ada.Text_IO.Get(c);
				Ada.Strings.Unbounded.Append(text, c);
				Ada.Text_IO.Look_Ahead(c, EOL);
			end loop;
			yylval := (StringToken, text);
			return T_IDENTIFIER;
		else
			yylval := (ValueType => EmptyToken);
			return Character'Pos(c);
		end if;
	exception
		when Ada.IO_Exceptions.End_Error =>
			yylval := (ValueType => EmptyToken);
			return EOF;
	end YYLex;
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
			null; -- TODO
		}
	| expression
		{
			Ada.Text_IO.Put(Integer'Image($1.i));
			Ada.Text_IO.Put_Line("");
		}
	;

primary
	: T_IDENTIFIER
		{
			null; -- TODO
		}
	| T_INTEGER
		{
			$$ := $1;
		}
	| '(' expression ')'
		{
			$$ := $2;
		}
	;

factor
	: primary
		{
			$$ := $1;
		}
	| '-' factor
		{
			$$ := (IntegerToken, -$2.i);
		}
	;

term
	: factor
		{
			$$ := $1;
		}
	| term '*' factor
		{
			$$ := (IntegerToken, $1.i * $3.i);
		}
	| term '/' factor
		{
			if $3.i = 0 then
				Ada.Text_IO.Put_Line("Division by zero\n");
				$$ := (IntegerToken, 0);
			else
				$$ := (IntegerToken, $1.i / $3.i);
			end if;
		}
	;

expression
	: term
		{
			$$ := $1;
		}
	| expression '+' term
		{
			$$ := (IntegerToken, $1.i + $3.i);
		}
	| expression '-' term
		{
			$$ := (IntegerToken, $1.i - $3.i);
		}
	;

%%

	result : Integer;

begin
	YYParse(result);
end Parse;

