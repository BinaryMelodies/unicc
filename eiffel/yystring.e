class
	YYSTRING
inherit
	YYSTYPE
redefine
		s
	end
create {ANY}
	make
feature {}
	sval: STRING
feature {ANY}
	make(sarg: STRING)
		do
			sval := sarg
		end
	s: STRING
		do
			Result := sval
		end
end
