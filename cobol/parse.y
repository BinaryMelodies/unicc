%{
       IDENTIFICATION DIVISION.
       PROGRAM-ID. parser.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 ReadingData.
        02 ScannedLine PICTURE X(80) VALUE SPACES.
        02 CurrentPosition PICTURE 99 VALUE 99.
        02 NextCharacter PICTURE X.

       01 ScanningData.
        02 TokenType PICTURE 9(5) VALUE ZERO.
        02 TokenValue.
         03 StringValue PICTURE X(16) VALUE SPACES.
         03 Numerical REDEFINES StringValue PICTURE S9(10) VALUE ZEROES.
        02 TokenCharPosition PICTURE 9(2) VALUE ZEROES.
%}

%define yystype {
         03 StringValue PICTURE X(16) VALUE SPACES.
         03 Numerical REDEFINES StringValue PICTURE S9(10) VALUE ZEROES.
}

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
		}
	| expression
		{
			DISPLAY Numerical IN $1
		}
	;

primary
	: IDENTIFIER
		{
		}
	| INTEGER
		{
			MOVE Numerical IN $1 TO Numerical IN $$
		}
	| '(' expression ')'
		{
			MOVE Numerical IN $2 TO Numerical IN $$
		}
	;

factor
	: primary
		{
			MOVE Numerical IN $1 TO Numerical IN $$
		}
	| '-' factor
		{
			COMPUTE Numerical IN $$ = -Numerical IN $2
		}
	;

term
	: factor
		{
			MOVE Numerical IN $1 TO Numerical IN $$
		}
	| term '*' factor
		{
			COMPUTE Numerical IN $$ = Numerical IN $1 * Numerical IN $3
		}
	| term '/' factor
		{
			IF Numerical IN $3 = 0 THEN
				DISPLAY "Division by zero"
				MOVE 0 TO Numerical IN $$
			ELSE
				COMPUTE Numerical IN $$ = Numerical IN $1 / Numerical IN $3
			END-IF
		}
	;

expression
	: term
		{
			MOVE Numerical IN $1 TO Numerical IN $$
		}
	| expression '+' term
		{
			COMPUTE Numerical IN $$ = Numerical IN $1 + Numerical IN $3
		}
	| expression '-' term
		{
			COMPUTE Numerical IN $$ = Numerical IN $1 - Numerical IN $3
		}
	;

%%
       MAIN SECTION.
        PERFORM YYParse.
        STOP RUN.

       ReadCharacter.
        IF CurrentPosition > 80 THEN
         ACCEPT ScannedLine
         MOVE 1 TO CurrentPosition
        END-IF.
        MOVE
         ScannedLine(CurrentPosition:CurrentPosition)
         TO NextCharacter.
         ADD 1 TO CurrentPosition.

       UnreadCharacter.
        IF CurrentPosition > 1 THEN
         SUBTRACT 1 FROM CurrentPosition
        END-IF.

       YYLex.
        PERFORM ReadCharacter.
        EVALUATE TRUE

         WHEN NextCharacter = ' '
          GO TO YYLex

         WHEN NextCharacter IS ALPHABETIC
          MOVE 1 TO TokenCharPosition
          PERFORM
            TEST BEFORE
            UNTIL NextCharacter = ' '
               OR NextCharacter IS NOT ALPHABETIC
              AND NextCharacter IS NOT NUMERIC
           MOVE NextCharacter
             TO StringValue
                IN TokenValue(TokenCharPosition:TokenCharPosition)
           ADD 1 TO TokenCharPosition
           PERFORM ReadCharacter
          END-PERFORM
          PERFORM UnreadCharacter
          MOVE TIDENTIFIER To TokenType

         WHEN NextCharacter IS NUMERIC
          MOVE NextCharacter TO Numerical IN TokenValue
          PERFORM ReadCharacter
          PERFORM
           TEST BEFORE
           UNTIL NextCharacter IS NOT NUMERIC
            COMPUTE Numerical IN TokenValue =
             Numerical IN TokenValue * 10
             + FUNCTION NUMVAL(NextCharacter)
            PERFORM ReadCharacter
          END-PERFORM
          PERFORM UnreadCharacter
          MOVE TINTEGER To TokenType

         WHEN OTHER
          COMPUTE TokenType =
           FUNCTION ORD(NextCharacter) - 1

        END-EVALUATE.

       YYError.
        DISPLAY "syntax error".

