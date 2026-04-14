class
	YYDEFINITION
create {ANY}
	make
feature {ANY}
	name: STRING
	value: INTEGER
	make(dname: STRING; dvalue: INTEGER)
		do
			name := dname
			value := dvalue
		end
end
