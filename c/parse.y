
%{

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef union YYSTYPE
{
	char * s;
	int i;
} YYSTYPE;

YYSTYPE yylval;

int yylex(void);
void yyerror(const char * s);

struct definition
{
	char * name;
	int value;
	struct definition * next;
};
struct definition * globals;

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
			struct definition * definition = malloc(sizeof(struct definition));
			definition->name = $1.s;
			definition->value = $3.i;
			definition->next = globals;
			globals = definition;
		}
	| expression
		{
			printf("%d\n", $1.i);
		}
	;

primary
	: IDENTIFIER
		{
			for(struct definition * definition = globals; definition; definition = definition->next)
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
			free($1.s);
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
				fprintf(stderr, "Division by zero\n");
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

int yylex(void)
{
	int c = getchar();
	while(c == ' ' || c == '\t')
		c = getchar();
	if('0' <= c && c <= '9')
	{
		ungetc(c, stdin);
		scanf("%d", &yylval.i);
		return INTEGER;
	}
	else if(('A' <= c && c <= 'Z') || ('a' <= c && c <= 'z') || c == '_')
	{
		char * buffer = malloc(2);
		buffer[0] = c;
		buffer[1] = '\0';
		for(c = getchar(); ('A' <= c && c <= 'Z') || ('a' <= c && c <= 'z') || c == '_' || ('0' <= c && c <= '9'); c = getchar())
		{
			buffer = realloc(buffer, strlen(buffer) + 2);
			buffer[strlen(buffer) + 1] = '\0';
			buffer[strlen(buffer)] = c;
		}
		ungetc(c, stdin);
		yylval.s = buffer;
		return IDENTIFIER;
	}
	else if(c == -1)
	{
		return 0;
	}
	else
	{
		return c;
	}
}

void yyerror(const char * s)
{
	fprintf(stderr, "Error: %s\n", s);
}

int main()
{
	return yyparse();
}

