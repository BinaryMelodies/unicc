
%{
with Ada.Characters; use Ada.Characters;
with Ada.Characters.Handling; use Ada.Characters.Handling;
with Ada.Characters.Latin_1;
with Ada.IO_Exceptions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;

procedure Parse is
	type TokenValueType is (EmptyToken, IntegerToken, StringToken);
	type YYSTYPE(ValueType : TokenValueType := EmptyToken) is
		record
			case ValueType is
				when IntegerToken =>
					i : Integer;
				when StringToken =>
					s : Unbounded_String;
				when others =>
					null;
			end case;
		end record;

	type definition is
		record
			name : Unbounded_String;
			value : Integer;
		end record;
	globals : array(1 .. 64) of definition;
	global_count : Integer := 0;

	yylval : YYSTYPE := (ValueType => EmptyToken);

	procedure YYError(s : String) is
	begin
		Put_Line(s);
	end YYError;

__ADA_INSERT_TOKEN_TYPES__

	next_eol : Boolean := False;

	function YYLex return TokenType is
		c : Character;
		EOL : Boolean;
		value : Integer;
		text : Unbounded_String;
	begin
		if next_eol then
			Get(c);
			if c = ' ' or c = Latin_1.HT then
				Look_Ahead(c, EOL);
				next_eol := False;
			else
				-- keep next_eol True so that we know c is not simply a look ahead but a read character
				EOL := False;
			end if;
		else
			Look_Ahead(c, EOL);
		end if;

		while not EOL and (c = ' ' or c = Latin_1.HT) loop
			Get(c);
			Look_Ahead(c, EOL);
		end loop;

		if EOL then
			next_eol := True;
			yylval := (ValueType => EmptyToken);
			return Character'Pos(Latin_1.LF);
		else
			if not next_eol then
				-- c was just looked ahead
				Get(c);
			end if;
			next_eol := False;
		end if;

		if Is_Digit(c) then
			value := Character'Pos(c) - Character'Pos('0');
			Look_Ahead(c, EOL);
			while not EOL and Is_Digit(c) loop
				Get(c);
				value := 10 * value + Character'Pos(c) - Character'Pos('0');
				Look_Ahead(c, EOL);
			end loop;
			yylval := (IntegerToken, value);
			return T_INTEGER;
		elsif Is_Letter(c) or c = '_' then
			Append(text, c);
			Look_Ahead(c, EOL);
			while not EOL and (Is_Letter(c) or c = '_' or Is_Digit(c)) loop
				Get(c);
				Append(text, c);
				Look_Ahead(c, EOL);
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

	found_name : Boolean;
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
			global_count := global_count + 1;
			globals(global_count) := ($1.s, $3.i);
		}
	| expression
		{
			Put_Line(Integer'Image($1.i));
		}
	;

primary
	: T_IDENTIFIER
		{
			found_name := False;
			for I in globals'Range loop
				if I > global_count then
					exit;
				end if;
				if globals(I).name = $1.s then
					$$ := (IntegerToken, globals(I).value);
					found_name := True;
					exit;
				end if;
			end loop;
			if not found_name then
				Put_Line("Undefined name " & To_String($1.s));
				$$ := (IntegerToken, 0);
			end if;
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
				Put_Line("Division by zero\n");
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

