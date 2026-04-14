
%{
create {ANY}
	make
feature {}
	yylval: YYSTYPE
	globals: ARRAY[YYDEFINITION]

	define_variable(name: STRING; value: INTEGER)
		local
			current_definition: YYDEFINITION
		do
			create current_definition.make(name, value)
			globals.add_last(current_definition)
		end

	lookup_variable(name: STRING): YYSTYPE
		local
			idx: INTEGER
			current_definition: YYDEFINITION
		do
			current_definition := Void

			from
				idx := globals.lower
			until
				idx >= globals.lower + globals.count
			or
				current_definition /= Void
			loop
				if (globals@idx).name.is_equal(name) then
					current_definition := globals@idx
				end
				idx := idx + 1
			end

			if current_definition = Void then
				io.put_line("Undefined name " + name)
				create {YYINTEGER} Result.make(0)
			else
				create {YYINTEGER} Result.make(current_definition.value)
			end
		end
%}

%token IDENTIFIER
%token INTEGER

%start program
%%

program
	: %empty
	| program line ';'
	;

line
	: IDENTIFIER '=' expression
		{
			define_variable($1.s, $3.i)
		}
	| expression
		{
			io.put_integer($1.i)
			io.put_line("")
		}
	;

primary
	: IDENTIFIER
		{
			$$ := lookup_variable($1.s)
		}
	| INTEGER
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
			create {YYINTEGER} $$.make(-$2.i)
		}
	;

term
	: factor
		{
			$$ := $1
		}
	| term '*' factor
		{
			create {YYINTEGER} $$.make($1.i * $3.i)
		}
	| term '/' factor
		{
			if $3.i = 0 then
				io.put_line("Division by zero")
				create {YYINTEGER} $$.make(0)
			else
				create {YYINTEGER} $$.make($1.i // $3.i)
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
			create {YYINTEGER} $$.make($1.i + $3.i)
		}
	| expression '-' term
		{
			create {YYINTEGER} $$.make($1.i - $3.i)
		}
	;

%%

feature {}
	yyerror(s: STRING)
		do
			io.put_line(s)
		end

	yylex: INTEGER
		local
			value: INTEGER
			text: STRING
		do
			std_input.read_character
			from
			until
				not std_input.last_character.is_separator
			loop
				std_input.read_character
			end

			if std_input.last_character.is_digit then
				value := std_input.last_character.value
				std_input.read_character
				from
				until
					not std_input.last_character.is_digit
				loop
					value := value * 10 + std_input.last_character.value
					std_input.read_character
				end
				std_input.unread_character
				create {YYINTEGER} yylval.make(value)
				Result := integer
			elseif std_input.last_character.is_letter or std_input.last_character = '_' then
				create text.make(16)
				text.extend(std_input.last_character)
				std_input.read_character
				from
				until
					not (std_input.last_character.is_letter or std_input.last_character = '_' or std_input.last_character.is_digit)
				loop
					text.extend(std_input.last_character)
					std_input.read_character
				end
				std_input.unread_character
				create {YYSTRING} yylval.make(text)
				Result := identifier
			else
				Result := std_input.last_character.code
			end
		end

feature {ANY}
	make
		do
			create globals.make(1, 0)
		end

