class
	YYINTEGER
inherit
	YYSTYPE
redefine
		i
	end
create {ANY}
	make
feature {}
	ival: INTEGER
feature {ANY}
	make(iarg: INTEGER)
		do
			ival := iarg
		end
	i: INTEGER
		do
			Result := ival
		end
end
