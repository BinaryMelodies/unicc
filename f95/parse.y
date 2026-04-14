
%{
module parser
    implicit none

    type YYSTYPE
        sequence
        integer :: i
        character (len=80) :: s
        integer :: l
    end type YYSTYPE

    type(YYSTYPE) :: yylval

    character (len=80) :: buffered_line
    integer :: buffered_line_position

    type definition
        character (len=80) :: name
        integer :: length
        integer :: value
    end type definition

    integer :: definition_count
    type(definition), dimension(32) :: definitions
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
		{
			$$%i = $1%i
		}
	| term '*' factor
		{
			$$%i = $1%i * $3%i
		}
	| term '/' factor
		{
			if($3%i == 0) then
				write(*, *) "Division by zero"
			else
				$$%i = $1%i / $3%i
			end if
		}
	;

expression
	: term
		{
			$$%i = $1%i
		}
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

    character (len=1) function getchar()

        if(buffered_line_position == 0)then
            read(*, "(a)") buffered_line
            buffered_line_position = 1
        end if

        if(buffered_line_position == len(buffered_line) + 1) then
            buffered_line_position = 0
            getchar = achar(10)
        else
            getchar = buffered_line(buffered_line_position:buffered_line_position)
            buffered_line_position = buffered_line_position+1
        end if

    end function

    subroutine ungetchar()
        if(buffered_line_position >= 1) then
            buffered_line_position = buffered_line_position - 1
        end if

    end subroutine

    integer function yylex()
        character (len=1) :: c

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
                yylex = TOKINT
            else if(('A' <= c .and. c <= 'Z') .or. ('a' <= c .and. c <= 'z') .or. c == '_') then

                yylval%l = 1
                do
                    yylval%s(yylval%l:yylval%l) = c
                    c=getchar()

                    if(('A' <= c .and. c <= 'Z') .or. ('a' <= c .and. c <= 'z') .or. c == '_' .or. ('0' <= c .and. c <= '9')) then
                        yylval%l = yylval%l + 1
                        cycle
                    else
                        exit
                    end if
                end do

                call ungetchar
                yylex = TOKIDN
            else if(c == ' ') then
                cycle
            else
                yylex = iachar(c)
            end if

            exit

        end do

    end function

    subroutine yyerror(s)
        character (len=*), intent(in) :: s

        write(*, "(A)") s
    end subroutine

    subroutine defvar(s, sl, i)
        character (len=80), intent(in) :: s
        integer, intent(in) :: sl
        integer, intent(in) :: i

        definition_count = definition_count + 1

        definitions(definition_count)%name = s
        definitions(definition_count)%length = sl
        definitions(definition_count)%value = i

    end subroutine

    logical function lookup(s, sl, yi)
        character (len=80), intent(in) :: s
        integer, intent(in) :: sl
        integer, intent(out) :: yi

        integer :: n

        lookup = .false.

        yi = 0
        do n = 1, definition_count
            if(s(1:sl) == definitions(n)%name(1:definitions(n)%length)) then
                yi = definitions(n)%value
                lookup = .true.
                exit
            end if
        end do

    end function

end module parser

program parse
    use parser
    implicit none

    integer :: i

    buffered_line_position = 0

    i = yyparse()

end program

