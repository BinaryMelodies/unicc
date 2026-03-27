
%{

#[derive(Debug)]
enum YYSTYPE
{
	Empty,
	Integer(i32),
	String(String),
}

impl YYSTYPE
{
	fn as_integer(&self) -> i32
	{
		match self
		{
			YYSTYPE::Integer(i) => *i,
			_ => panic!()
		}
	}

	fn as_string(&self) -> String
	{
		match self
		{
			YYSTYPE::String(s) => s.to_string(),
			_ => panic!()
		}
	}
}

struct BufferedStdin
{
	buffer: Option<u8>
}

impl BufferedStdin
{
	fn next(&mut self) -> Option<u8>
	{
		match self.buffer
		{
		None =>
			std::io::stdin().bytes().next().and_then(|result| result.ok()),
		Some(c) =>
			{
				self.buffer = None;
				Some(c)
			}
		}
	}

	fn putback(&mut self, c: u8)
	{
		// TODO: check that self.buffer is None
		self.buffer = Some(c);
	}
}

struct Definition
{
	name: String,
	value: i32
}

%}

%define yyparse_parameters {stdin: &mut BufferedStdin, globals: &mut Vec<Definition>}
%define yylex_arguments {stdin}

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
			globals.push(Definition{name: $1.as_string(), value: $3.as_integer()});
		}
	| expression
		{
			println!("{:?}", $1.as_integer());
		}
	;

primary
	: IDENTIFIER
		{
			let name: String = $1.as_string();
			let value: i32 = 'result: {
				for definition in &mut *globals
				{
					if definition.name == name
					{
						break 'result definition.value;
					}
				}
				println!("Undefined name {:?}\n", name);
				0
			};
			$$ = YYSTYPE::Integer(value);
		}
	| INTEGER
		{
			$$ = std::mem::replace(&mut $1, YYSTYPE::Empty);
		}
	| '(' expression ')'
		{
			$$ = std::mem::replace(&mut $2, YYSTYPE::Empty);
		}
	;

factor
	: primary
		{
			$$ = std::mem::replace(&mut $1, YYSTYPE::Empty);
		}
	| '-' factor
		{
			$$ = YYSTYPE::Integer(-$2.as_integer());
		}
	;

term
	: factor
		{
			$$ = YYSTYPE::Integer($1.as_integer());
		}
	| term '*' factor
		{
			$$ = YYSTYPE::Integer($1.as_integer() * $3.as_integer());
		}
	| term '/' factor
		{
			let dividend: i32 = $3.as_integer();
			if dividend == 0
			{
				println!("Division by zero");
				$$ = YYSTYPE::Integer(0);
			}
			else
			{
				$$ = YYSTYPE::Integer($1.as_integer() / $3.as_integer());
			}
		}
	;

expression
	: term
		{
			$$ = std::mem::replace(&mut $1, YYSTYPE::Empty);
		}
	| expression '+' term
		{
			$$ = YYSTYPE::Integer($1.as_integer() + $3.as_integer());
		}
	| expression '-' term
		{
			$$ = YYSTYPE::Integer($1.as_integer() - $3.as_integer());
		}
	;

%%

fn yylex(stdin: &mut BufferedStdin) -> (i32, YYSTYPE)
{
	let mut chr: Option<u8>;

	while
	{
		chr = stdin.next();
		chr.and_then(|c| Some(c == ' ' as u8 || c == '\t' as u8)).unwrap_or(false)
	}
	{
	}

	match chr
	{
		None => (0, YYSTYPE::Empty),
		Some(c) =>
			{
				if '0' as u8 <= c && c <= '9' as u8
				{
					let mut v: i32 = c as i32 - '0' as i32;
					while
					{
						chr = stdin.next();
						chr.and_then(|c| Some('0' as u8 <= c && c <= '9' as u8)).unwrap_or(false)
					}
					{
						v = v * 10 + chr.unwrap() as i32 - '0' as i32
					}
					chr.and_then(|c| Some(stdin.putback(c)));
					(INTEGER, YYSTYPE::Integer(v))
				}
				else if ('A' as u8 <= c && c <= 'Z' as u8) || ('a' as u8 <= c && c <= 'z' as u8) || (c == '_' as u8)
				{
					let mut s = String::from("");
					s.push(c as char);
					while
					{
						chr = stdin.next();
						chr.and_then(|c| Some(('A' as u8 <= c && c <= 'Z' as u8) || ('a' as u8 <= c && c <= 'z' as u8) || (c == '_' as u8) || ('0' as u8 <= c && c <= '9' as u8))).unwrap_or(false)
					}
					{
						s.push(chr.unwrap() as char);
					}
					chr.and_then(|c| Some(stdin.putback(c)));
					(IDENTIFIER, YYSTYPE::String(s))
				}
				else
				{
					(c as i32, YYSTYPE::Empty)
				}
			}
	}
}

fn yyerror(msg: &str)
{
	println!("{:?}", msg);
}

fn main()
{
	let mut stdin: BufferedStdin = BufferedStdin{buffer: None};
	let mut globals: Vec<Definition> = Vec::new();
	yyparse(&mut stdin, &mut globals);
}

