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
;   e8 cast
;   e sizeof, unary prefixes ++ -- & * + - ~ !
;   f . -> () [] postfix ++ --
;   highest
; NB: for equal precedence, operators are applied left-to-right except for assignment operators (precedence 2)

#define SYMBOL_COMMA 200
; NOTE: operator_right_associative and others require SYMBOL_EQ to be the first assignment operator
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
; NOTE: operator_right_associative and others require SYMBOL_OR_EQ to be the last assignment operator
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
#define SYMBOL_DOT 245

#define TOKEN_IDENTIFIER 1
#define TOKEN_CONSTANT_FLOAT 2
#define TOKEN_CONSTANT_INT 3
#define TOKEN_CONSTANT_CHAR 4
#define TOKEN_STRING_LITERAL 5
#define TOKEN_EOF 6

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

; the format of expression headers is:
;    uchar kind  (one of the constants below)
;    uchar info
;    ushort (padding)
;    uint type
; immediately following the header in memory are the arguments of the expression
;    - for constant ints, the 64-bit integral value
;    - for constant floats, the 64-bit double value (even if expression has type float)
;    - for string literals, a 64-bit pointer to the string (for the executable, not for the compiler)
;    - for unary operators, the operand
;    - for binary operators, the first operand followed by the second
;        - for the operators . and ->, the first argument is a 64-bit pointer to the name of the member and the second is the left hand side of the . / -> 
;    - for the ternary operator ? :, the first followed by the second followed by the third
;    - for function calls, the function, followed by each of the arguments to the function — info indicates the number of arguments
; Note that file/line number are not stored in expressions.
#define EXPRESSION_IDENTIFIER 200
#define EXPRESSION_CONSTANT_INT 201
#define EXPRESSION_CONSTANT_FLOAT 202
#define EXPRESSION_STRING_LITERAL 203
#define EXPRESSION_SUBSCRIPT 204
#define EXPRESSION_CALL 205
#define EXPRESSION_DOT 206
#define EXPRESSION_ARROW 207
#define EXPRESSION_POST_INCREMENT 208
#define EXPRESSION_POST_DECREMENT 209
#define EXPRESSION_PRE_INCREMENT 210
#define EXPRESSION_PRE_DECREMENT 211
#define EXPRESSION_ADDRESS_OF 212
#define EXPRESSION_DEREFERENCE 213
; this matters for promotion. if x is a char, sizeof(+x) should be sizeof(int)
#define EXPRESSION_UNARY_PLUS 214
#define EXPRESSION_UNARY_MINUS 215
#define EXPRESSION_BITWISE_NOT 216
#define EXPRESSION_LOGICAL_NOT 217
#define EXPRESSION_SIZEOF 218
#define EXPRESSION_CAST 219
#define EXPRESSION_MUL 220
#define EXPRESSION_DIV 221
#define EXPRESSION_REMAINDER 222
#define EXPRESSION_ADD 223
#define EXPRESSION_SUB 224
#define EXPRESSION_LSHIFT 225
#define EXPRESSION_RSHIFT 226
#define EXPRESSION_LT 227
#define EXPRESSION_GT 228
#define EXPRESSION_LEQ 229
#define EXPRESSION_GEQ 230
#define EXPRESSION_EQ 231
#define EXPRESSION_NEQ 232
#define EXPRESSION_BITWISE_AND 233
#define EXPRESSION_BITWISE_XOR 234
#define EXPRESSION_BITWISE_OR 235
#define EXPRESSION_LOGICAL_AND 236
#define EXPRESSION_LOGICAL_OR 237
; e.g. x == 5 ? 6 : 7
#define EXPRESSION_CONDITIONAL 238
#define EXPRESSION_ASSIGN 239
#define EXPRESSION_ASSIGN_ADD 240
#define EXPRESSION_ASSIGN_SUB 241
#define EXPRESSION_ASSIGN_MUL 242
#define EXPRESSION_ASSIGN_DIV 243
#define EXPRESSION_ASSIGN_REMAINDER 244
#define EXPRESSION_ASSIGN_LSHIFT 245
#define EXPRESSION_ASSIGN_RSHIFT 246
#define EXPRESSION_ASSIGN_AND 247
#define EXPRESSION_ASSIGN_XOR 248
#define EXPRESSION_ASSIGN_OR 249
#define EXPRESSION_COMMA 250

; TYPES: A type is a 4-byte index into the global array `types`. Byte 0 in `types`
; is reserved, and bytes 1-16 contain the values 1-16. Thus TYPE_INT, etc.
; can be used as types directly.
; The format of each type is as follows:
;  char, unsigned char, etc.: TYPE_CHAR, TYPE_UNSIGNED_CHAR, etc. as a single byte
;  pointer to type t: TYPE_PTR t
;  array of n t's: TYPE_ARRAY {n as 8 bytes} t
;  struct/union: TYPE_STRUCT/TYPE_UNION {0 for incomplete types/4-byte pointer to struct/union}
;  function: TYPE_FUNCTION {arg1 type} {arg2 type} ... {argn type} 0 {return type}
#define TYPE_VOID 1
#define TYPE_CHAR 3
#define TYPE_UNSIGNED_CHAR 4
#define TYPE_SHORT 5
#define TYPE_UNSIGNED_SHORT 6
#define TYPE_INT 7
#define TYPE_UNSIGNED_INT 8
#define TYPE_LONG 9
#define TYPE_UNSIGNED_LONG 10
#define TYPE_FLOAT 11
; note that long double is treated the same as double.
#define TYPE_DOUBLE 12
#define TYPE_POINTER 13
#define TYPE_STRUCT 14
#define TYPE_UNION 15
#define TYPE_ARRAY 16
#define TYPE_FUNCTION 17

; types willl be initialized (in main) so that this refers to the type char*
#define TYPE_POINTER_TO_CHAR 20

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
	byte SYMBOL_DOT
	string .
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
:str_void
	string void
	byte 0
:str_char
	string char
	byte 0
:str_unsigned_char
	string unsigned char
	byte 0
:str_short
	string short
	byte 0
:str_unsigned_short
	string unsigned short
	byte 0
:str_int
	string int
	byte 0
:str_unsigned_int
	string unsigned int
	byte 0
:str_long
	string long
	byte 0
:str_unsigned_long
	string unsigned long
	byte 0
:str_float
	string float
	byte 0
:str_double
	string double
	byte 0
:str_struct
	string struct
	byte 0
:str_union
	string union
	byte 0
