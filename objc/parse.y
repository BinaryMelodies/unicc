
%{

#include <Foundation/Foundation.h>
#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

id yylval;

int yylex(void);
void yyerror(const char * s);

NSMutableDictionary<NSString *, NSNumber *> * globals;

%}

%define yystype {id}

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
			[globals setValue: $3 forKey: $1];
		}
	| expression
		{
			NSLog(@"%d\n", [$1 intValue]);
		}
	;

primary
	: IDENTIFIER
		{
			NSNumber * value = [globals objectForKey: $1];
			if(value != nil)
			{
				$$ = value;
			}
			else
			{
				NSLog(@"Undefined name %@\n", $1);
				$$ = [NSNumber numberWithInt: 0];
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
			$$ = [NSNumber numberWithInt: -[$2 intValue]];
		}
	;

term
	: factor
		{
			$$ = $1;
		}
	| term '*' factor
		{
			$$ = [NSNumber numberWithInt: [$1 intValue] * [$3 intValue]];
		}
	| term '/' factor
		{
			if([$3 intValue] == 0)
			{
				NSLog(@"Division by zero\n");
				$$ = [NSNumber numberWithInt: 0];
			}
			else
			{
				$$ = [NSNumber numberWithInt: [$1 intValue] / [$3 intValue]];
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
			$$ = [NSNumber numberWithInt: [$1 intValue] + [$3 intValue]];
		}
	| expression '-' term
		{
			$$ = [NSNumber numberWithInt: [$1 intValue] - [$3 intValue]];
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
		int value;
		ungetc(c, stdin);
		scanf("%d", &value);
		yylval = [NSNumber numberWithInt: value];
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
		yylval = [NSString stringWithUTF8String: buffer];
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
	NSLog(@"Error: %s\n", s);
}

int main()
{
	NSAutoreleasePool * pool;
	pool = [NSAutoreleasePool new];

	globals = [NSMutableDictionary new];
	int result = yyparse();

	RELEASE(pool);
	return result;
}

