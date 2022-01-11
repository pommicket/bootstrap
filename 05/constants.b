; this is the format of the executables we produce:
;   elf header + code 4MB  addresses 0x400000-0x7fffff
;   read-only data    4MB  addresses 0x800000-0xbfffff
;   read-write data   4MB  addresses 0xc00000-0xffffff
#define RODATA_OFFSET 0x400000
#define RODATA_ADDR 0x800000

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

#define SYMBOL_COMMA 200
#define SYMBOL_EQ 201
#define SYMBOL_PLUS_EQ 202
#define SYMBOL_MINUS_EQ 203
#define SYMBOL_TIMES_EQ 204
#define SYMBOL_DIV_EQ 205
#define SYMBOL_PERCENT_EQ 206
#define SYMBOL_LSHIFT_EQ 207
#define SYMBOL_RSHIFT_EQ 208
#define SYMBOL_AND_EQ 209
#define SYMBOL_XOR_EQ 210
#define SYMBOL_OR_EQ 211
#define SYMBOL_QUESTION 212
#define SYMBOL_OR_OR 213
#define SYMBOL_AND_AND 214
#define SYMBOL_OR 215
#define SYMBOL_XOR 216
#define SYMBOL_AND 217
#define SYMBOL_EQ_EQ 218
#define SYMBOL_NOT_EQ 219
#define SYMBOL_LT 220
#define SYMBOL_GT 221
#define SYMBOL_LT_EQ 222
#define SYMBOL_GT_EQ 223
#define SYMBOL_LSHIFT 224
#define SYMBOL_RSHIFT 225
#define SYMBOL_PLUS 226
#define SYMBOL_MINUS 227
#define SYMBOL_TIMES 228
#define SYMBOL_DIV 229
#define SYMBOL_PERCENT 230
#define SYMBOL_PLUS_PLUS 231
#define SYMBOL_MINUS_MINUS 232
#define SYMBOL_NOT 233
#define SYMBOL_TILDE 234
#define SYMBOL_ARROW 235
#define SYMBOL_DOTDOTDOT 236
#define SYMBOL_COLON 237
#define SYMBOL_LBRACE 238
#define SYMBOL_RBRACE 239
#define SYMBOL_LSQUARE 240
#define SYMBOL_RSQUARE 241
#define SYMBOL_LPAREN 242
#define SYMBOL_RPAREN 243
#define SYMBOL_SEMICOLON 244


#define TOKEN_IDENTIFIER 1
#define TOKEN_CONSTANT_FLOAT 2
#define TOKEN_CONSTANT_INT 3
#define TOKEN_CONSTANT_CHAR 4
#define TOKEN_STRING_LITERAL 5

; these are stored in the "info" field of the token
#define NUMBER_NO_SUFFIX 0
#define NUMBER_SUFFIX_U 1
#define NUMBER_SUFFIX_L 2
#define NUMBER_SUFFIX_UL 3
#define NUMBER_SUFFIX_F 4

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

:keyword_table
	byte SYMBOL_SEMICOLON
	byte 59
	byte 0
	byte SYMBOL_EQ
	string =
	byte 0
	byte SYMBOL_LBRACE
	string {
	byte 0
	byte SYMBOL_RBRACE
	string }
	byte 0
	byte SYMBOL_LSQUARE
	string [
	byte 0
	byte SYMBOL_RSQUARE
	string ]
	byte 0
	byte SYMBOL_LPAREN
	string (
	byte 0
	byte SYMBOL_RPAREN
	string )
	byte 0
	byte SYMBOL_COMMA
	string ,
	byte 0
	byte SYMBOL_PLUS_EQ
	string +=
	byte 0
	byte SYMBOL_MINUS_EQ
	string -=
	byte 0
	byte SYMBOL_TIMES_EQ
	string *=
	byte 0
	byte SYMBOL_DIV_EQ
	string /=
	byte 0
	byte SYMBOL_PERCENT_EQ
	string %=
	byte 0
	byte SYMBOL_LSHIFT_EQ
	string <<=
	byte 0
	byte SYMBOL_RSHIFT_EQ
	string >>=
	byte 0
	byte SYMBOL_AND_EQ
	string &=
	byte 0
	byte SYMBOL_XOR_EQ
	string ^=
	byte 0
	byte SYMBOL_OR_EQ
	string |=
	byte 0
	byte SYMBOL_QUESTION
	string ?
	byte 0
	byte SYMBOL_OR_OR
	string ||
	byte 0
	byte SYMBOL_AND_AND
	string &&
	byte 0
	byte SYMBOL_OR
	string |
	byte 0
	byte SYMBOL_XOR
	string ^
	byte 0
	byte SYMBOL_AND
	string &
	byte 0
	byte SYMBOL_EQ_EQ
	string ==
	byte 0
	byte SYMBOL_NOT_EQ
	string !=
	byte 0
	byte SYMBOL_LT
	string <
	byte 0
	byte SYMBOL_GT
	string >
	byte 0
	byte SYMBOL_LT_EQ
	string <=
	byte 0
	byte SYMBOL_GT_EQ
	string >=
	byte 0
	byte SYMBOL_LSHIFT
	string <<
	byte 0
	byte SYMBOL_RSHIFT
	string >>
	byte 0
	byte SYMBOL_PLUS
	string +
	byte 0
	byte SYMBOL_MINUS
	string -
	byte 0
	byte SYMBOL_TIMES
	string *
	byte 0
	byte SYMBOL_DIV
	string /
	byte 0
	byte SYMBOL_PERCENT
	string %
	byte 0
	byte SYMBOL_PLUS_PLUS
	string ++
	byte 0
	byte SYMBOL_MINUS_MINUS
	string --
	byte 0
	byte SYMBOL_NOT
	string !
	byte 0
	byte SYMBOL_TILDE
	string ~
	byte 0
	byte SYMBOL_ARROW
	string ->
	byte 0
	byte SYMBOL_DOTDOTDOT
	string ...
	byte 0
	byte SYMBOL_COLON
	string :
	byte 0
	byte KEYWORD_DOUBLE
	string double
	byte 0
	byte KEYWORD_INT
	string int
	byte 0
	byte KEYWORD_STRUCT
	string struct
	byte 0
	byte KEYWORD_BREAK
	string break
	byte 0
	byte KEYWORD_ELSE
	string else
	byte 0
	byte KEYWORD_LONG
	string long
	byte 0
	byte KEYWORD_SWITCH
	string switch
	byte 0
	byte KEYWORD_CASE
	string case
	byte 0
	byte KEYWORD_ENUM
	string enum
	byte 0
	byte KEYWORD_TYPEDEF
	string typedef
	byte 0
	byte KEYWORD_CHAR
	string char
	byte 0
	byte KEYWORD_EXTERN
	string extern
	byte 0
	byte KEYWORD_RETURN
	string return
	byte 0
	byte KEYWORD_UNION
	string union
	byte 0
	byte KEYWORD_FLOAT
	string float
	byte 0
	byte KEYWORD_SHORT
	string short
	byte 0
	byte KEYWORD_UNSIGNED
	string unsigned
	byte 0
	byte KEYWORD_CONTINUE
	string continue
	byte 0
	byte KEYWORD_FOR
	string for
	byte 0
	byte KEYWORD_VOID
	string void
	byte 0
	byte KEYWORD_DEFAULT
	string default
	byte 0
	byte KEYWORD_GOTO
	string goto
	byte 0
	byte KEYWORD_SIZEOF
	string sizeof
	byte 0
	byte KEYWORD_DO
	string do
	byte 0
	byte KEYWORD_IF
	string if
	byte 0
	byte KEYWORD_STATIC
	string static
	byte 0
	byte KEYWORD_WHILE
	string while
	byte 0
	byte 255

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
