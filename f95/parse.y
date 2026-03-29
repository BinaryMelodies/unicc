
%{
    logical :: lookup

    type YYSTYPE
        sequence
        integer :: i
        character (len=80) :: s
        integer :: l
    end type YYSTYPE
%}

%define yystype {type(YYSTYPE)}

%token TOKIDN
%token TOKINT

%start program
%%

program
	: %empty
	| program line '\n'
	;

line
	: TOKIDN '=' expression
		{
			call defvar($1%s, $1%l, $3%i)
		}
	| expression
		{
			write(*, "(I10)") $1%i
		}
	;

primary
	: TOKIDN
		{
			if(.not. lookup($1%s, $1%l, $$%i)) then
				write(*, "('Undefined name ',A)") $1%s
			end if
		}
	| TOKINT
		{
			$$%i = $1%i
		}
	| '(' expression ')'
		{
			$$%i = $2%i
		}
	;

factor
	: primary
		{
			$$%i = $1%i
		}
	| '-' factor
		{
			$$%i = -$2%i
		}
	;

term
	: factor
	| term '*' factor
		{
			$$%i = $1%i * $3%i
		}
	| term '/' factor
		{
			if($3%i == 0) then
				WRITE(*, *) "Division by zero"
			else
				$$%i = $1%i / $3%i
			end if
		}
	;

expression
	: term
	| expression '+' term
		{
			$$%i = $1%i + $3%i
		}
	| expression '-' term
		{
			$$%i = $1%i - $3%i
		}
	;

%%

function getchar()
    implicit none
    character (len=1) :: getchar

    character (len=80) :: line
    integer :: linepos
    common /io/ line,linepos

    if(linepos == 0)then
        read(*, "(a)") line
        linepos = 1
    end if

    if(LINEPOS == LEN(LINE)+1) then
        linepos = 0
        getchar = achar(10)
    else
        getchar = line(linepos:linepos)
        linepos = linepos+1
    end if

end function

subroutine ungetchar()
    implicit none

    character (len=80) :: line
    integer :: linepos
    common /io/ line,linepos

    if(linepos >= 1) then
        linepos = linepos - 1
    end if

end subroutine

function yylex()
    implicit none
    integer :: yylex

    character (len=80) :: line
    integer :: linepos
    common /io/ line,linepos

    type YYSTYPE
        sequence
        integer :: i
        character (len=80) :: s
        integer :: l
    end type YYSTYPE

    type(YYSTYPE) yylval
    common /yy/ yylval

    character (len=1) :: getchar
    character (len=1) :: c

    integer, parameter :: tokidn = 256
    integer, parameter :: tokint = 257

    do
        c = getchar()
        if('0' <= c .and. c <= '9') then
            yylval%i = iachar(c) - iachar('0')
            do
                c = getchar()
                if('0' <= c .and. c <= '9') then
                    yylval%i = yylval%i * 10 + iachar(c) - iachar('0')
                    cycle
                else
                    exit
                end if
            end do

            call ungetchar
            yylex = tokint
        elseif(('A' <= c .and. c <= 'Z') .or. ('a' <= c .and. c <= 'z') .or. c == '_') then

            yylval%l = 1
            do
                yylval%s(yylval%l:yylval%l) = c
                c=getchar()

                if(('A' <= c .and. c <= 'Z') .or. ('a' <= c .and. c <= 'z') .or. c == '_' .or. ('0' <= c .and. c <= '9')) then
                    yylval%l = yylval%l + 1
                    cycle
                else
                    exit
                endif
            end do

            call ungetchar
            yylex=tokidn
        else if(c == ' ') then
            cycle
        else
            yylex = iachar(c)
        end if

        exit

    end do

end function

subroutine yyerror(s)
    implicit none
    character (len=*), intent(in) :: s

    write(*, "(A)") s

end subroutine

subroutine defvar(s, sl, i)
    implicit none
    character (len=80), intent(in) :: s
    integer, intent(in) :: sl
    integer, intent(in) :: i

    integer :: ndef
    character (len=80), dimension(32) :: defs
    integer, dimension(32) :: defsl
    integer, dimension(32) :: defi
    common /def/ ndef,defs,defsl,defi

    ndef = ndef + 1

    defs(ndef) = s
    defsl(ndef) = sl
    defi(ndef) = i

end subroutine

function lookup(s, sl, yi)
    implicit none
    logical :: lookup
    character (len=80), intent(in) :: s
    integer, intent(in) :: sl
    integer, intent(out) :: yi

    integer :: ndef
    character (len=80), dimension(32) :: defs
    integer, dimension(32) :: defsl
    integer, dimension(32) :: defi
    common /def/ ndef,defs,defsl,defi

    integer :: n

    lookup = .false.

    yi = 0
    do n = 1, ndef
        if(s(1:sl) == defs(n)(1:defsl(n))) then
            yi = defi(n)
            lookup = .true.
            exit
        end if
    end do

end function

program parse
    implicit none

    character (len=80) :: line
    integer :: linepos
    common /io/ line,linepos

    integer :: ndef
    character (len=80), dimension(32) :: defs
    integer, dimension(32) :: defsl
    integer, dimension(32) :: defi
    common /def/ ndef,defs,defsl,defi

    integer :: yyparse

    integer :: i

    linepos = 0

    i = yyparse()

end program

