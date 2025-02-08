
%{
using System;
using System.Text;
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
			new Definition((string)$1, (int)$3);
		}
	| expression
		{
			Console.WriteLine($1);
		}
	;

primary
	: IDENTIFIER
		{
			object value = Definition.lookup((string)$1);
			if(value == null) {
				Console.WriteLine("Undefined name " + $1);
				$$ = 0;
			} else {
				$$ = value;
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
			$$ = -(int)$2;
		}
	;

term
	: factor
	| term '*' factor
		{
			$$ = (int)$1 * (int)$3;
		}
	| term '/' factor
		{
			if((int)$3 == 0)
			{
				Console.WriteLine("Division by zero");
				$$ = 0;
			}
			else
			{
				$$ = (int)$1 / (int)$3;
			}
		}
	;

expression
	: term
	| expression '+' term
		{
			$$ = (int)$1 + (int)$3;
		}
	| expression '-' term
		{
			$$ = (int)$1 - (int)$3;
		}
	;

%%

public static Definition globals;
public class Definition {
	public string name;
	public object value;
	public Definition next;

	public Definition(string name, object value) {
		this.name = name;
		this.value = value;
		this.next = globals;
		globals = this;
	}

	public static object lookup(string name) {
		for(Definition definition = globals; definition != null; definition = definition.next) {
			if(globals.name.Equals(name))
				return globals.value;
		}
		return null;
	}
}

public void yyerror(string message) {
	Console.WriteLine("Error: " + message);
}

int last_char;
bool has_last_char;

public int Peek() {
	if(!has_last_char)
	{
		last_char = Console.In.Read();
		has_last_char = true;
	}
	return last_char;
}

public int Read() {
	Peek();
	has_last_char = false;
	return last_char;
}

public int yylex() {
	int c = Read();
	while(c == ' ' || c == '\t')
		c = Read();
	if('0' <= c && c <= '9')
	{
		int value = c - '0';
		c = Peek();
		while('0' <= c && c <= '9')
		{
			c = Read();
			value = 10 * value + c - '0';
			c = Peek();
		}
		yylval = value;
		return INTEGER;
	}
	else if(('A' <= c && c <= 'Z') || ('a' <= c && c <= 'z') || c == '_')
	{
		StringBuilder buffer = new StringBuilder();
		buffer.Append((char)c);
		for(c = Peek(); ('A' <= c && c <= 'Z') || ('a' <= c && c <= 'z') || c == '_' || ('0' <= c && c <= '9'); c = Peek())
		{
			Read();
			buffer.Append((char)c);
		}
		yylval = buffer.ToString();
		return IDENTIFIER;
	}
	else if(c == 4)
	{
		return 0;
	}
	else
	{
		return c;
	}
}

static void Main(string[] args) {
	new Parser().yyparse();
}

