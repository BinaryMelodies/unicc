class
	CALC
create {ANY}
	make
feature {ANY}
	make
		local
			parse: PARSE
			return: INTEGER
		do
			create parse.make
			return := parse.yyparse
		end
end
