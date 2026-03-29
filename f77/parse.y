
%{
      LOGICAL LOOKUP

      STRUCTURE /YYSTYPE/
      INTEGER I
      CHARACTER*80 S
      INTEGER L
      END STRUCTURE
%}

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
			CALL DEFVAR($1.S,$1.L,$3.I)
		}
	| expression
		{
			WRITE(*,1)$1.I
			1 FORMAT(I10)
		}
	;

primary
	: TOKIDN
		{
			IF(.NOT.LOOKUP($1.S,$1.L,$$.I))THEN
			WRITE(*,2)$1.S
			2 FORMAT('Undefined name ',A)
			ENDIF
		}
	| TOKINT
		{
			$$.I = $1.I
		}
	| '(' expression ')'
		{
			$$.I = $2.I
		}
	;

factor
	: primary
		{
			$$.I = $1.I
		}
	| '-' factor
		{
			$$.I = -$2.I
		}
	;

term
	: factor
	| term '*' factor
		{
			$$.I = $1.I * $3.I
		}
	| term '/' factor
		{
			IF($3.I.EQ.0)THEN
				WRITE(*,*)'Division by zero'
			ELSE
				$$.I = $1.I / $3.I
			ENDIF
		}
	;

expression
	: term
	| expression '+' term
		{
			$$.I = $1.I + $3.I
		}
	| expression '-' term
		{
			$$.I = $1.I - $3.I
		}
	;

%%

************************************************************************

      CHARACTER*1 FUNCTION GETCHAR()

      IMPLICIT NONE

      CHARACTER LINE*80
      INTEGER LINEPOS
      COMMON/IO/LINE,LINEPOS

      IF(LINEPOS.EQ.0)THEN
1     FORMAT(A)
      READ(*,1)LINE
      LINEPOS=1
      ENDIF

      IF(LINEPOS.EQ.LEN(LINE)+1)THEN
      LINEPOS=0
      GETCHAR=ACHAR(10)
      ELSE
      GETCHAR=LINE(LINEPOS:LINEPOS)
      LINEPOS=LINEPOS+1
      END IF

      END FUNCTION

************************************************************************

      SUBROUTINE UNGETCHAR()

      IMPLICIT NONE

      CHARACTER LINE*80
      INTEGER LINEPOS
      COMMON/IO/LINE,LINEPOS

      IF(LINEPOS.GE.1)THEN
      LINEPOS=LINEPOS-1
      END IF

      END SUBROUTINE

************************************************************************

      INTEGER FUNCTION YYLEX()

      IMPLICIT NONE

      CHARACTER LINE*80
      INTEGER LINEPOS
      COMMON/IO/LINE,LINEPOS

      STRUCTURE /YYSTYPE/
      INTEGER I
      CHARACTER*80 S
      INTEGER L
      END STRUCTURE

      RECORD/YYSTYPE/YYLVAL
      COMMON/YY/YYLVAL

      CHARACTER GETCHAR*1
      CHARACTER C*1

      INTEGER TOKIDN,TOKINT
      PARAMETER(TOKIDN=256,TOKINT=257)

1     C=GETCHAR()

      IF('0'.LE.C.AND.C.LE.'9')THEN

      YYLVAL.I=IACHAR(C)-IACHAR('0')
2     C=GETCHAR()

      IF('0'.LE.C.AND.C.LE.'9')THEN
      YYLVAL.I=YYLVAL.I*10+IACHAR(C)-IACHAR('0')
      GOTO 2
      ELSE
      GOTO 3
      END IF

3     CALL UNGETCHAR
      YYLEX=TOKINT

      ELSEIF(('A'.LE.C.AND.C.LE.'Z').OR.('a'.LE.C.AND.C.LE.'z').OR.C .EQ.'_')THEN

      YYLVAL.L=1
4     YYLVAL.S(YYLVAL.L:YYLVAL.L)=C
      C=GETCHAR()

      IF(('A'.LE.C.AND.C.LE.'Z').OR.('a'.LE.C.AND.C.LE.'z').OR.C.EQ. '_'.OR.('0'.LE.C.AND.C.LE.'9'))THEN
      YYLVAL.L=YYLVAL.L+1
      GOTO 4
      ELSE
      GOTO 5
      ENDIF

5     CALL UNGETCHAR
      YYLEX=TOKIDN

      ELSEIF(C.EQ.' ')THEN

      GOTO 1

      ELSE

      YYLEX=IACHAR(C)

      END IF

      END FUNCTION

************************************************************************

      SUBROUTINE YYERROR(S)
      CHARACTER*(*) S

1     FORMAT(A)
      WRITE(*,1)S

      END SUBROUTINE

************************************************************************

      SUBROUTINE DEFVAR(S, SL, I)
      CHARACTER*80 S
      INTEGER SL
      INTEGER I

      INTEGER NDEF
      CHARACTER*80 DEFS(32)
      INTEGER DEFSL(32)
      INTEGER DEFI(32)
      COMMON/DEF/NDEF,DEFS,DEFSL,DEFI

      NDEF = NDEF + 1

      DEFS(NDEF) = S
      DEFSL(NDEF) = SL
      DEFI(NDEF) = I

      END SUBROUTINE

************************************************************************

      LOGICAL FUNCTION LOOKUP(S, SL, YI)
      CHARACTER*80 S
      INTEGER SL
      INTEGER YI

      INTEGER NDEF
      CHARACTER*80 DEFS(32)
      INTEGER DEFSL(32)
      INTEGER DEFI(32)
      COMMON/DEF/NDEF,DEFS,DEFSL,DEFI

      INTEGER N

      LOOKUP = .FALSE.

      DO 1 N = 1, NDEF
      IF(S(1:SL).EQ.DEFS(N)(1:DEFSL(N)))THEN
      YI = DEFI(N)
      LOOKUP = .TRUE.
      GOTO 2
      ENDIF
1     CONTINUE

      YI = 0

2     CONTINUE

      END FUNCTION

************************************************************************

      PROGRAM PARSE

      IMPLICIT NONE

      CHARACTER LINE*80
      INTEGER LINEPOS
      COMMON/IO/LINE,LINEPOS

      INTEGER NDEF
      CHARACTER*80 DEFS(32)
      INTEGER DEFSL(32)
      INTEGER DEFI(32)
      COMMON/DEF/NDEF,DEFS,DEFSL,DEFI

      INTEGER YYPARSE

      INTEGER I

      LINEPOS=0

      I=YYPARSE()
C 2     FORMAT(I5,I5,'[',A,']')
C      I=YYLEX()
C      WRITE(*,*)I,YLI,YLS

      END PROGRAM

