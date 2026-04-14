
%{
create {ANY}
	make
feature {}
	yylval: YYSTYPE
	globals: ARRAY[YYDEFINITION]

	make_int(i: INTEGER): YYSTYPE
		local
			yyi: YYINTEGER
		do
			create yyi.make(i)
			Result := yyi
		end

	make_str(s: STRING): YYSTYPE
		local
			yys: YYSTRING
		do
			create yys.make(s)
			Result := yys
		end

	current_definition: YYDEFINITION
	idx: INTEGER
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
			create current_definition.make($1.s, $3.i)
			globals.add_last(current_definition)
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
			current_definition := Void

			from
				idx := globals.lower
			until
				idx >= globals.lower + globals.count
			or
				current_definition /= Void
			loop
				if (globals@idx).name.is_equal($1.s) then
					current_definition := globals@idx
				end
				idx := idx + 1
			end

			if current_definition = Void then
				io.put_line("Undefined name " + $1.s)
				$$ := make_int(0)
			else
				$$ := make_int(current_definition.value)
			end
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
			$$ := make_int(-$2.i)
		}
	;

term
	: factor
		{
			$$ := $1
		}
	| term '*' factor
		{
			$$ := make_int($1.i * $3.i)
		}
	| term '/' factor
		{
			if $3.i = 0 then
				io.put_line("Division by zero")
				$$ := make_int(0)
			else
				$$ := make_int($1.i // $3.i)
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
			$$ := make_int($1.i + $3.i)
		}
	| expression '-' term
		{
			$$ := make_int($1.i - $3.i)
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
				yylval := make_int(value)
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
				yylval := make_str(text)
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

