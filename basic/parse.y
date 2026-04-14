
%{
Type YYSTYPE
	i As Integer
	s As String
End Type

Dim Shared LastChar As String

Declare Function yylex() As Integer
Declare Sub yyerror(message As String)
Declare Sub DefineVariable(varname As String, value As Integer)
Declare Function Lookup(varname As String, ByRef value As Integer) As Boolean
%}

%token T_IDENTIFIER
%token T_INTEGER

%start _program
%%

_program
	: %empty
	| _program line '\n'
	;

line
	: T_IDENTIFIER '=' expression
		{
			DefineVariable $1.s, $3.i
		}
	| expression
		{
			Print $1.i
		}
	;

primary
	: T_IDENTIFIER
		{
			If Not Lookup($1.s, $$.i) Then
				Print "Undefined name "; $1.s
				$$.i = 0
			End If
		}
	| T_INTEGER
		{
			$$ = $1
		}
	| '(' expression ')'
		{
			$$ = $2
		}
	;

factor
	: primary
		{
			$$ = $1
		}
	| '-' factor
		{
			$$.i = -$2.i
		}
	;

term
	: factor
		{
			$$ = $1
		}
	| term '*' factor
		{
			$$.i = $1.i * $3.i
		}
	| term '/' factor
		{
			If $3.i = 0 Then
				Print "Division by zero"
				$$.i = 0
			Else
				$$.i = Int($1.i / $3.i)
			End If
		}
	;

expression
	: term
		{
			$$ = $1
		}
	| expression '+' term
		{
			$$.i = $1.i + $3.i
		}
	| expression '-' term
		{
			$$.i = $1.i - $3.i
		}
	;

%%

' TODO: requires proper editing

Function yylex() As Integer

	Dim v As Integer

	If LastChar = "" Then
		LastChar = Input$(1)
	End If

	If "0" <= LastChar And LastChar <= "9" Then
		YYLVAL.i = 0
		Do While "0" <= LastChar And LastChar <= "9"
			YYLVAL.i = YYLVAL.i * 10 + Asc(LastChar) - Asc("0")
			Print LastChar;
			LastChar = Input$(1)
		Loop
		Return T_INTEGER
	ElseIf ("A" <= LastChar And LastChar <= "Z") Or ("a" <= LastChar And LastChar <= "z") Or LastChar = "_" Then
		YYLVAL.s = ""
		Do While ("A" <= LastChar And LastChar <= "Z") Or ("a" <= LastChar And LastChar <= "z") Or LastChar = "_" Or ("0" <= LastChar And LastChar <= "9")
			YYLVAL.s = YYLVAL.s + LastChar
			Print LastChar;
			LastChar = Input$(1)
		Loop
		Return T_IDENTIFIER
	ElseIf LastChar = Chr$(13) Then
		LastChar = ""
		Print Chr$(13) + Chr$(10)
		Return 10
	ElseIf LastChar = Chr$(4) Then
		Return 0
	Else
		Print LastChar;
		v = Asc(LastChar)
		LastChar = ""
		Return v
	End If

End Function

Sub yyerror(message As String)
	Print message
End Sub

Type Definition
	name As String
	value As Integer
End Type

Dim Shared definitions(16) As Definition
Dim Shared definition_count As Integer

definition_count = 0

Sub DefineVariable(varname As String, value As Integer)
	definition_count = definition_count + 1
	definitions(definition_count).name = varname
	definitions(definition_count).value = value
End Sub

Function Lookup(varname As String, ByRef value As Integer) As Boolean
	Dim i As Integer

	For i = 1 To definition_count
		If definitions(i).name = varname Then
			value = definitions(i).value
			Return True
		End If
	Next I
	Return False
End Function

yyparse

