; C OPERATOR PRECEDENCE
;   lowest
;   1 ,
;   2 = += -= *= /= %= <<= >>= &= ^= |=
;   3 ? ... :
;   4 ||
;   5 &&
;   6 |
;   7 ^
;   8 &
;   9 == !=
;   a < > <= >=
;   b << >>
;   c + -
;   d * / %
;   e unary prefixes ++ -- & * + - ~ !
;   f . -> () [] postfix ++ --
;   highest
; NB: for equal precedence, operators are applied left-to-right except for assignment operators (precedence 2)

; pattern for binary operators is: 0x10px where p is precedence
; NB: these four can also be unary: & * + -
#define MASK_SYMBOL_PRECEDENCE 0x0ff0
#define SYMBOL_COMMA 0x1010
#define SYMBOL_EQ 0x1020
#define SYMBOL_PLUS_EQ 0x1021
#define SYMBOL_MINUS_EQ 0x1022
#define SYMBOL_TIMES_EQ 0x1023
#define SYMBOL_DIV_EQ 0x1024
#define SYMBOL_PERCENT_EQ 0x1025
#define SYMBOL_LSHIFT_EQ 0x1026
#define SYMBOL_RSHIFT_EQ 0x1027
#define SYMBOL_AND_EQ 0x1028
#define SYMBOL_XOR_EQ 0x1029
#define SYMBOL_OR_EQ 0x102a
#define SYMBOL_QUESTION 0x1030
#define SYMBOL_OR_OR 0x1040
#define SYMBOL_AND_AND 0x1050
#define SYMBOL_OR 0x1060
#define SYMBOL_XOR 0x1070
#define SYMBOL_AND 0x1080
#define SYMBOL_EQ_EQ 0x1090
#define SYMBOL_NOT_EQ 0x1091
#define SYMBOL_LT 0x10a0
#define SYMBOL_GT 0x10a1
#define SYMBOL_LT_EQ 0x10a2
#define SYMBOL_GT_EQ 0x10a3
#define SYMBOL_LSHIFT 0x10b0
#define SYMBOL_RSHIFT 0x10b1
#define SYMBOL_PLUS 0x10c0
#define SYMBOL_MINUS 0x10c1
#define SYMBOL_TIMES 0x10d0
#define SYMBOL_DIV 0x10d1
#define SYMBOL_PERCENT 0x10d2

#define SYMBOL_PLUS_PLUS 100
#define SYMBOL_MINUS_MINUS 101
#define SYMBOL_NOT 102
#define SYMBOL_TILDE 103
#define SYMBOL_ARROW 104
#define SYMBOL_DOTDOTDOT 105
#define SYMBOL_COLON 106
#define SYMBOL_LBRACE 107
#define SYMBOL_RBRACE 108
#define SYMBOL_LSQUARE 109
#define SYMBOL_RSQUARE 110
#define SYMBOL_LPAREN 111
#define SYMBOL_RPAREN 112
#define SYMBOL_SEMICOLON 113


#define TOKEN_IDENTIFIER 1
#define TOKEN_CONSTANT_FLOAT 2
#define TOKEN_CONSTANT_INT 3
#define TOKEN_CONSTANT_CHAR 4
#define TOKEN_STRING 5


; #define KEYWORD_AUTO 21  (@NONSTANDARD auto only exists in C for legacy reasons and doesn't appear in TCC's source code)
#define KEYWORD_DOUBLE 22
#define KEYWORD_INT 23
#define KEYWORD_STRUCT 24
#define KEYWORD_BREAK 25
#define KEYWORD_ELSE 26
#define KEYWORD_LONG 27
#define KEYWORD_SWITCH 28
#define KEYWORD_CASE 29
#define KEYWORD_ENUM 30
; #define KEYWORD_REGISTER 31 (we can just #define register)
#define KEYWORD_TYPEDEF 32
#define KEYWORD_CHAR 33
#define KEYWORD_EXTERN 34
#define KEYWORD_RETURN 35
#define KEYWORD_UNION 36
; #define KEYWORD_CONST 37 (we can just #define const)
#define KEYWORD_FLOAT 38
#define KEYWORD_SHORT 39
#define KEYWORD_UNSIGNED 40
#define KEYWORD_CONTINUE 41
#define KEYWORD_FOR 42
; #define KEYWORD_SIGNED 43 (again, just #define signed)
#define KEYWORD_VOID 44
#define KEYWORD_DEFAULT 45
#define KEYWORD_GOTO 46
#define KEYWORD_SIZEOF 47
; #define KEYWORD_VOLATILE 48 (just #define volatile if need be)
#define KEYWORD_DO 49
#define KEYWORD_IF 50
#define KEYWORD_STATIC 51
#define KEYWORD_WHILE 52

:str_missing_closing_paren
	string Missing closing ).
	byte 0
:str_comment_start
	string /*
	byte 0
:str_comment_end
	string */
	byte 0
:str_lshift_eq
	string <<=
	byte 0
:str_rshift_eq
	string >>=
	byte 0
:str_eq_eq
	string ==
	byte 0
:str_not_eq
	string !=
	byte 0
:str_gt_eq
	string >=
	byte 0
:str_lt_eq
	string <=
	byte 0
:str_plus_plus
	string ++
	byte 0
:str_minus_minus
	string --
	byte 0
:str_plus_eq
	string +=
	byte 0
:str_minus_eq
	string -=
	byte 0
:str_times_eq
	string *=
	byte 0
:str_div_eq
	string /=
	byte 0
:str_percent_eq
	string %=
	byte 0
:str_and_eq
	string &=
	byte 0
:str_or_eq
	string |=
	byte 0
:str_xor_eq
	string ^=
	byte 0
:str_and_and
	string &&
	byte 0
:str_or_or
	string ||
	byte 0
:str_lshift
	string <<
	byte 0
:str_rshift
	string >>
	byte 0
:str_arrow
	string ->
	byte 0
:str_dotdotdot
	string ...
	byte 0
:str_hash_hash
	string ##
	byte 0
:str_eq
	string =
	byte 0
:str_not
	string !
	byte 0
:str_tilde
	string ~
	byte 0
:str_lt
	string <
	byte 0
:str_gt
	string >
	byte 0
:str_and
	string &
	byte 0
:str_or
	string |
	byte 0
:str_xor
	string ^
	byte 0
:str_plus
	string +
	byte 0
:str_minus
	string -
	byte 0
:str_times
	string *
	byte 0
:str_div
	string /
	byte 0
:str_percent
	string %
	byte 0
:str_question
	string ?
	byte 0
:str_comma
	string ,
	byte 0
:str_colon
	string :
	byte 0
:str_semicolon
	byte 59
	byte 0
:str_dot
	string .
	byte 0
:str_lparen
	string (
	byte 0
:str_rparen
	string )
	byte 0
:str_lsquare
	string [
	byte 0
:str_rsquare
	string ]
	byte 0
:str_lbrace
	string {
	byte 0
:str_rbrace
	string }
	byte 0
:str_error
	string error
	byte 0
:str_define
	string define
	byte 0
:str_undef
	string undef
	byte 0
:str_pragma
	string pragma
	byte 0
:str_line
	string line
	byte 0
:str_include
	string include
	byte 0
:str_ifdef
	string ifdef
	byte 0
:str_ifndef
	string ifndef
	byte 0
:str_if
	string if
	byte 0
:str_elif
	string elif
	byte 0
:str_else
	string else
	byte 0
:str_endif
	string endif
	byte 0
:str_double
	string double
	byte 0
:str_int
	string int
	byte 0
:str_struct
	string struct
	byte 0
:str_break
	string break
	byte 0
:str_long
	string long
	byte 0
:str_switch
	string switch
	byte 0
:str_case
	string case
	byte 0
:str_enum
	string enum
	byte 0
:str_typedef
	string typedef
	byte 0
:str_char
	string char
	byte 0
:str_extern
	string extern
	byte 0
:str_return
	string return
	byte 0
:str_union
	string union
	byte 0
:str_float
	string float
	byte 0
:str_short
	string short
	byte 0
:str_unsigned
	string unsigned
	byte 0
:str_continue
	string continue
	byte 0
:str_for
	string for
	byte 0
:str_void
	string void
	byte 0
:str_default
	string default
	byte 0
:str_goto
	string goto
	byte 0
:str_sizeof
	string sizeof
	byte 0
:str_do
	string do
	byte 0
:str_static
	string static
	byte 0
:str_while
	string while
	byte 0

:str___FILE__
	string __FILE__
	byte 0
:str___LINE__
	string __LINE__
	byte 0
:str___DATE__
	string __DATE__
	byte 0
:str___TIME__
	string __TIME__
	byte 0
:str___STDC__
	string __STDC__
	byte 0
