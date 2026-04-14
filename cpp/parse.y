
%{
#include <iostream>
#include <string>
#include <vector>
#include <variant>

typedef std::variant<int, std::string> YYSTYPE;

YYSTYPE yylval;

int yylex(void);
void yyerror(const std::string& s);

class definition
{
public:
	std::string name;
	int value;
	definition(std::string name, int value) : name(name), value(value) { }
};
std::vector<definition> globals;
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
			globals.push_back(definition(std::get<std::string>($1), std::get<int>($3)));
		}
	| expression
		{
			std::cout << std::get<int>($1) << std::endl;
		}
	;

primary
	: IDENTIFIER
		{
			for(std::vector<definition>::iterator definition = globals.begin(); definition != globals.end(); definition++)
			{
				if(std::get<std::string>($1) == definition->name)
				{
					$$.emplace<int>(definition->value);
					goto done;
				}
			}
			std::cerr << "Undefined name " << std::get<std::string>($1) << std::endl;
			$$.emplace<int>(0);
		done: ;
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
			$$.emplace<int>(-std::get<int>($2));
		}
	;

term
	: factor
	| term '*' factor
		{
			$$.emplace<int>(std::get<int>($1) * std::get<int>($3));
		}
	| term '/' factor
		{
			if(std::get<int>($3) == 0)
			{
				std::cerr << "Division by zero" << std::endl;
				$$.emplace<int>(0);
			}
			else
			{
				$$.emplace<int>(std::get<int>($1) / std::get<int>($3));
			}
		}
	;

expression
	: term
	| expression '+' term
		{
			$$.emplace<int>(std::get<int>($1) + std::get<int>($3));
		}
	| expression '-' term
		{
			$$.emplace<int>(std::get<int>($1) - std::get<int>($3));
		}
	;

%%

int yylex(void)
{
	int c = std::cin.get();
	while(c == ' ' || c == '\t')
		c = std::cin.get();
	if('0' <= c && c <= '9')
	{
		int value;
		std::cin.unget();
		std::cin >> value;
		yylval.emplace<int>(value);
		return INTEGER;
	}
	else if(('A' <= c && c <= 'Z') || ('a' <= c && c <= 'z') || c == '_')
	{
		std::string text;
		text += char(c);
		for(c = std::cin.get(); ('A' <= c && c <= 'Z') || ('a' <= c && c <= 'z') || c == '_' || ('0' <= c && c <= '9'); c = std::cin.get())
		{
			text += char(c);
		}
		std::cin.unget();
		yylval.emplace<std::string>(text);
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

void yyerror(const std::string& s)
{
	std::cerr << "Error: " << s << std::endl;
}

int main()
{
	return yyparse();
}

