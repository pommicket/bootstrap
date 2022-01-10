; #define KEYWORD_AUTO 101  (auto only exists in C for legacy reasons and doesn't appear in TCC's source code)
#define KEYWORD_DOUBLE 102
#define KEYWORD_INT 103
#define KEYWORD_STRUCT 104
#define KEYWORD_BREAK 105
#define KEYWORD_ELSE 106
#define KEYWORD_LONG 107
#define KEYWORD_SWITCH 108
#define KEYWORD_CASE 109
#define KEYWORD_ENUM 110
#define KEYWORD_REGISTER 111
#define KEYWORD_TYPEDEF 112
#define KEYWORD_CHAR 113
#define KEYWORD_EXTERN 114
#define KEYWORD_RETURN 115
#define KEYWORD_UNION 116
; #define KEYWORD_CONST 117 (we can just #define const)
#define KEYWORD_FLOAT 118
#define KEYWORD_SHORT 119
#define KEYWORD_UNSIGNED 120
#define KEYWORD_CONTINUE 121
#define KEYWORD_FOR 122
; #define KEYWORD_SIGNED 123 (again, just #define signed)
#define KEYWORD_VOID 124
#define KEYWORD_DEFAULT 125
#define KEYWORD_GOTO 126
#define KEYWORD_SIZEOF 127
; #define KEYWORD_VOLATILE 128 (just #define volatile if need be)
#define KEYWORD_DO 129
#define KEYWORD_IF 130
#define KEYWORD_STATIC 131
#define KEYWORD_WHILE 132

:str_missing_closing_bracket
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
:str_remainder_eq
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
