
%{
      LOGICAL LOOKUP

      INTEGER STKI(128)
      CHARACTER*80 STKS(128)
      INTEGER STKSL(128)
      INTEGER YLI
      CHARACTER*80 YLS
      INTEGER YLSL
      INTEGER YI
      CHARACTER*80 YS
      INTEGER YSL
      COMMON/YY/STKI,STKS,STKSL,YLI,YLS,YLSL,YI,YS,YSL
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
			CALL DEFVAR(STKS($1),STKSL($1),STKI($3))
		}
	| expression
		{
			WRITE(*,1)STKI($1)
			1 FORMAT(I10)
		}
	;

primary
	: TOKIDN
		{
			IF(.NOT.LOOKUP(STKS($1),STKSL($1)))THEN
			WRITE(*,2)$1
			2 FORMAT('Undefined name ',A)
			ENDIF
		}
	| TOKINT
		{
			YI = STKI($1)
		}
	| '(' expression ')'
		{
			YI = STKI($2)
		}
	;

factor
	: primary
		{
			YI = STKI($1)
		}
	| '-' factor
		{
			YI = -STKI($2)
		}
	;

term
	: factor
	| term '*' factor
		{
			YI = STKI($1) * STKI($3)
		}
	| term '/' factor
		{
			IF($3.EQ.0)THEN
				WRITE(*,*)'Division by zero'
			ELSE
				YI = STKI($1) / STKI($3)
			ENDIF
		}
	;

expression
	: term
	| expression '+' term
		{
			YI = STKI($1) + STKI($3)
		}
	| expression '-' term
		{
			YI = STKI($1) - STKI($3)
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

      INTEGER STKI(128)
      CHARACTER*80 STKS(128)
      INTEGER STKSL(128)
      INTEGER YLI
      CHARACTER*80 YLS
      INTEGER YLSL
      INTEGER YI
      CHARACTER*80 YS
      INTEGER YSL
      COMMON/YY/STKI,STKS,STKSL,YLI,YLS,YLSL,YI,YS,YSL

      CHARACTER GETCHAR*1
      CHARACTER C*1

      INTEGER TOKIDN,TOKINT
      PARAMETER(TOKIDN=256,TOKINT=257)

1     C=GETCHAR()

      IF('0'.LE.C.AND.C.LE.'9')THEN

      YLI=IACHAR(C)-IACHAR('0')
2     C=GETCHAR()

      IF('0'.LE.C.AND.C.LE.'9')THEN
      YLI=YLI*10+IACHAR(C)-IACHAR('0')
      GOTO 2
      ELSE
      GOTO 3
      END IF

3     CALL UNGETCHAR
      YYLEX=TOKINT

      ELSEIF(('A'.LE.C.AND.C.LE.'Z').OR.('a'.LE.C.AND.C.LE.'z').OR.C .EQ.'_')THEN

      YLSL=1
4     YLS(YLSL:YLSL)=C
      C=GETCHAR()

      IF(('A'.LE.C.AND.C.LE.'Z').OR.('a'.LE.C.AND.C.LE.'z').OR.C.EQ. '_'.OR.('0'.LE.C.AND.C.LE.'9'))THEN
      YLSL=YLSL+1
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
* Stores the values in YL* to the stack position I

      SUBROUTINE YYSTR(I)
      INTEGER I

      INTEGER STKI(128)
      CHARACTER*80 STKS(128)
      INTEGER STKSL(128)
      INTEGER YLI
      CHARACTER*80 YLS
      INTEGER YLSL
      INTEGER YI
      CHARACTER*80 YS
      INTEGER YSL
      COMMON/YY/STKI,STKS,STKSL,YLI,YLS,YLSL,YI,YS,YSL

      STKI(I) = YLI
      STKS(I) = YLS
      STKSL(I) = YLSL
      END SUBROUTINE

************************************************************************
* Stores the values in Y* to the stack position I

      SUBROUTINE YYSTR2(I)
      INTEGER I

      INTEGER STKI(128)
      CHARACTER*80 STKS(128)
      INTEGER STKSL(128)
      INTEGER YLI
      CHARACTER*80 YLS
      INTEGER YLSL
      INTEGER YI
      CHARACTER*80 YS
      INTEGER YSL
      COMMON/YY/STKI,STKS,STKSL,YLI,YLS,YLSL,YI,YS,YSL

      STKI(I) = YI
      STKS(I) = YS
      STKSL(I) = YSL
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

      LOGICAL FUNCTION LOOKUP(S, SL)
      CHARACTER*80 S
      INTEGER SL

      INTEGER STKI(128)
      CHARACTER*80 STKS(128)
      INTEGER STKSL(128)
      INTEGER YLI
      CHARACTER*80 YLS
      INTEGER YLSL
      INTEGER YI
      CHARACTER*80 YS
      INTEGER YSL
      COMMON/YY/STKI,STKS,STKSL,YLI,YLS,YLSL,YI,YS,YSL

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

