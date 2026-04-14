
%{
import java.io.IOException;
import java.io.PushbackInputStream;
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
			new Definition((String)$1, (Integer)$3);
		}
	| expression
		{
			System.out.println($1);
		}
	;

primary
	: IDENTIFIER
		{
			Object value = Definition.lookup((String)$1);
			if(value == null) {
				System.err.println("Undefined name " + $1);
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
			$$ = -(Integer)$2;
		}
	;

term
	: factor
		{
			$$ = $1;
		}
	| term '*' factor
		{
			$$ = (Integer)$1 * (Integer)$3;
		}
	| term '/' factor
		{
			if((Integer)$3 == 0)
			{
				System.err.println("Division by zero");
				$$ = 0;
			}
			else
			{
				$$ = (Integer)$1 / (Integer)$3;
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
			$$ = (Integer)$1 + (Integer)$3;
		}
	| expression '-' term
		{
			$$ = (Integer)$1 - (Integer)$3;
		}
	;

%%

public static Definition globals;
public static class Definition {
	public String name;
	public Object value;
	public Definition next;

	public Definition(String name, Object value) {
		this.name = name;
		this.value = value;
		this.next = globals;
		globals = this;
	}

	public static Object lookup(String name) {
		for(Definition definition = globals; definition != null; definition = definition.next) {
			if(definition.name.equals(name))
				return definition.value;
		}
		return null;
	}
}

public void yyerror(String message) {
	System.err.println("Error: " + message);
}

PushbackInputStream in = new PushbackInputStream(System.in);
public int yylex() throws IOException {
	int c = in.read();
	while(c == ' ' || c == '\t')
		c = in.read();
	if('0' <= c && c <= '9')
	{
		int value = c - '0';
		for(c = in.read(); '0' <= c && c <= '9'; c = in.read())
		{
			value = 10 * value + c - '0';
		}
		in.unread(c);
		yylval = value;
		return INTEGER;
	}
	else if(('A' <= c && c <= 'Z') || ('a' <= c && c <= 'z') || c == '_')
	{
		StringBuilder buffer = new StringBuilder();
		buffer.append((char)c);
		for(c = in.read(); ('A' <= c && c <= 'Z') || ('a' <= c && c <= 'z') || c == '_' || ('0' <= c && c <= '9'); c = in.read())
		{
			buffer.append((char)c);
		}
		in.unread(c);
		yylval = buffer.toString();
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

public static void main(String[] args) throws Exception {
	new Parser().yyparse();
}

