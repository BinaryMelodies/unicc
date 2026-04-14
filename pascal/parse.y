
%{
program Parser;

type YYSTYPE = record
	case Integer of
		1: (i: Integer);
		2: (s: String);
end;

var yylval: YYSTYPE;

function yylex: Integer; forward;

type
	PDefinition = ^TDefinition;
	TDefinition = record
	name: String;
	ivalue: Integer;
	next: PDefinition;
end;

var globals: PDefinition;

procedure define(name: String; ivalue: Integer);
var definition: PDefinition;
begin
	New(definition);
	definition^.name := name;
	definition^.ivalue := ivalue;
	definition^.next := globals;
	globals := definition;
end;

function lookup(name: String; var result: Integer): Boolean;
label done;
var current: PDefinition;
begin
	current := globals;
	while current <> nil do
	begin
		if current^.name = name then
		begin
			result := current^.ivalue;
			lookup := true;
			goto done
		end;
		current := current^.next;
	end;
	lookup := false;
done:
end;

procedure yyerror(message: String);
begin
	WriteLn(StdErr, 'Error: ', message)
end;
%}

%token T_IDENTIFIER
%token T_INTEGER

%start _program
%%

_program
	: %empty
	| _program line '\n'
	;

line
	: T_IDENTIFIER '=' expression
		{
			define($1.s, $3.i);
		}
	| expression
		{
			WriteLn($1.i)
		}
	;

primary
	: T_IDENTIFIER
		{
			if not lookup($1.s, $$.i) then
			begin
				WriteLn(StdErr, 'Undefined name ', $1.s);
				$$.i := 0
			end
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
			$$.i := -$2.i
		}
	;

term
	: factor
		{
			$$ := $1
		}
	| term '*' factor
		{
			$$.i := $1.i * $3.i
		}
	| term '/' factor
		{
			if $3.i = 0 then
			begin
				WriteLn(StdErr, 'Division by zero');
				$$.i := 0
			end
			else
			begin
				$$.i := $1.i div $3.i
			end
		}
	;

expression
	: term
		{
			$$ := $1
		}
	| expression '+' term
		{
			$$.i := $1.i + $3.i
		}
	| expression '-' term
		{
			$$.i := $1.i - $3.i
		}
	;

%%

var buffer: Char;
var buffered: Boolean;

function yylex: Integer;
	var c: Char;

	procedure GetChar;
	begin
		if buffered then
			c := buffer
		else
			Read(c);
		buffered := false;
	end;

	procedure UnGetChar;
	begin
		buffer := c;
		buffered := true
	end;
begin
	GetChar;
	while (c = ' ') or (c = '\t') do
		GetChar;

	if ('0' <= c) and (c <= '9') then
	begin
		yylval.i := 0;
		while ('0' <= c) and (c <= '9') do
		begin
			yylval.i := ord(c) - ord('0');
			GetChar;
		end;
		UnGetChar;
		yylex := T_INTEGER
	end
	else if (('A' <= c) and (c <= 'Z')) or (('a' <= c) and (c <= 'z')) or (c = '_') then
	begin
		yylval.s := '';
		while (('A' <= c) and (c <= 'Z')) or (('a' <= c) and (c <= 'z')) or (c = '_') or (('0' <= c) and (c <= '9')) do
		begin
			yylval.s := yylval.s + c;
			GetChar;
		end;
		UnGetChar;
		yylex := T_IDENTIFIER
	end
	else if c = Char(26) then
	begin
		yylex := 0
	end
	else
	begin
		yylex := Integer(c)
	end
end;

begin
	yyparse
end.

