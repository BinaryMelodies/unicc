
%{

import std.stdio;
import std.ascii;

union YYSTYPE
{
	string s;
	int i;
};

YYSTYPE yylval;

int yylex();
void yyerror(string s);

int[string] globals;

%}

%token IDENTIFIER
%token INTEGER

%start program
%%

program
	: %empty
	| program line '\n'
	;

line
	: IDENTIFIER '=' expression
		{
			globals[$1.s] = $3.i;
		}
	| expression
		{
			writefln("%d", $1.i);
		}
	;

primary
	: IDENTIFIER
		{
			if($1.s in globals)
			{
				$$.i = globals[$1.s];
			}
			else
			{
				stderr.writefln("Undefined name %s", $1.s);
				$$.i = 0;
			}
		}
	| INTEGER
		{
			$$ = $1;
		}
	| '(' expression ')'
		{
			$$ = $2;
		}
	;

factor
	: primary
		{
			$$ = $1;
		}
	| '-' factor
		{
			$$.i = -$2.i;
		}
	;

term
	: factor
		{
			$$ = $1;
		}
	| term '*' factor
		{
			$$.i = $1.i * $3.i;
		}
	| term '/' factor
		{
			if($3.i == 0)
			{
				stderr.writeln("Division by zero");
				$$.i = 0;
			}
			else
			{
				$$.i = $1.i / $3.i;
			}
		}
	;

expression
	: term
		{
			$$ = $1;
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

static char getc_buffer;
static bool getc_buffered = false;

int getchar()
{
	if(getc_buffered)
		getc_buffered = false;
	else
		readf("%c", &getc_buffer);
	return getc_buffer;
}

void ungetc(int c)
{
	getc_buffered = true;
	getc_buffer = cast(char)c;
}

int yylex()
{
	int c;
	c = getchar();
	while(c == ' ' || c == '\t')
	{
		c = getchar();
	}
	if(c == 0xFF)
	{
		return -1;
	}
	else if(isDigit(c))
	{
		yylval.i = c - '0';
		c = getchar();
		while(isDigit(c))
		{
			yylval.i = 10 * yylval.i + c - '0';
			c = getchar();
		}
		ungetc(c);
		return INTEGER;
	}
	else if(isAlpha(c))
	{
		yylval.s = "" ~ cast(char)c;
		c = getchar();
		while(isAlphaNum(c) || c == '_')
		{
			yylval.s ~= c;
			c = getchar();
		}
		ungetc(c);
		return IDENTIFIER;
	}
	else
	{
		return c;
	}
}

void yyerror(string s)
{
	stderr.writefln("Error: %s", s);
}

int main()
{
	return yyparse();
}

