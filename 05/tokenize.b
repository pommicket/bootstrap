global file_list ; initialized in main -- null-separated 255-terminated array of strings

; get the name of the file with the given index
function file_get
	argument idx
	local p
	p = file_list
	:file_get_loop
		if idx == 0 goto file_got
		if *1p == 255 goto file_uhoh
		idx -= 1
		p = memchr(p, 0)
		p += 1
		goto file_get_loop
	:file_got
	return p
	:file_uhoh
	fputs(2, .str_bad_file_index)
	exit(1)
	:str_bad_file_index
		string Bad file index. This shouldn't happen.
		byte 10
		byte 0
	
; get the index of the given file, returns -1 if file does not exist
function file_get_index
	argument filename
	local p
	local b
	local i
	p = file_list
	i = 0
	:file_get_index_loop
		if *1p == 255 goto return_minus1
		b = str_equals(p, filename)
		if b != 0 goto file_found
		i += 1
		p = memchr(p, 0)
		p += 1
		goto file_get_index_loop
	:file_found
	return i
	
; add to list of files if not already there
function file_add
	argument filename
	local p
	p = file_get_index(filename)
	if p != -1 goto return_0
	p = memchr(file_list, 255)
	p = strcpy(p, filename)
	p += 1
	*1p = 255
	return

; turn pptokens into tokens, written to out.
; tokens are 16 bytes and have the following format:
;    ushort type
;    ushort file
;    uint line
;    ulong data
function tokenize
	argument pptokens
	argument out
	local in
	local file
	local line_number
	local b
	in = pptokens
	:tokenize_loop
		if *1in == '$ goto tokenize_line_directive
		if *1in == 32 goto tokenize_skip_pptoken
		if *1in == 10 goto tokenize_newline
		if *1in == 0 goto tokenize_loop_end
		
		b = str_equals(in, .str_comma)
		if b != 0 goto keyword_comma
		b = str_equals(in, .str_eq)
		if b != 0 goto keyword_eq
		b = str_equals(in, .str_plus_eq)
		if b != 0 goto keyword_plus_eq
		b = str_equals(in, .str_minus_eq)
		if b != 0 goto keyword_minus_eq
		b = str_equals(in, .str_times_eq)
		if b != 0 goto keyword_times_eq
		b = str_equals(in, .str_div_eq)
		if b != 0 goto keyword_div_eq
		b = str_equals(in, .str_percent_eq)
		if b != 0 goto keyword_percent_eq
		b = str_equals(in, .str_lshift_eq)
		if b != 0 goto keyword_rshift_eq
		b = str_equals(in, .str_and_eq)
		if b != 0 goto keyword_and_eq
		b = str_equals(in, .str_or_eq)
		if b != 0 goto keyword_or_eq
		b = str_equals(in, .str_question)
		if b != 0 goto keyword_question
		b = str_equals(in, .str_or_or)
		if b != 0 goto keyword_or_or
		b = str_equals(in, .str_and_and)
		if b != 0 goto keyword_and_and
		b = str_equals(in, .str_or)
		if b != 0 goto keyword_or
		b = str_equals(in, .str_xor)
		if b != 0 goto keyword_xor
		b = str_equals(in, .str_and)
		if b != 0 goto keyword_and
		b = str_equals(in, .str_eq_eq)
		if b != 0 goto keyword_eq_eq
		b = str_equals(in, .str_not_eq)
		if b != 0 goto keyword_not_eq
		b = str_equals(in, .str_lt)
		if b != 0 goto keyword_lt
		b = str_equals(in, .str_gt)
		if b != 0 goto keyword_gt
		b = str_equals(in, .str_lt_eq)
		if b != 0 goto keyword_lt_eq
		b = str_equals(in, .str_gt_eq)
		if b != 0 goto keyword_gt_eq
		b = str_equals(in, .str_lshift)
		if b != 0 goto keyword_lshift
		b = str_equals(in, .str_rshift)
		if b != 0 goto keyword_rshift
		b = str_equals(in, .str_plus)
		if b != 0 goto keyword_plus
		b = str_equals(in, .str_minus)
		if b != 0 goto keyword_minus
		b = str_equals(in, .str_times)
		if b != 0 goto keyword_times
		b = str_equals(in, .str_div)
		if b != 0 goto keyword_div
		b = str_equals(in, .str_percent)
		if b != 0 goto keyword_percent
		b = str_equals(in, .str_plus_plus)
		if b != 0 goto keyword_plus_plus
		b = str_equals(in, .str_minus_minus)
		if b != 0 goto keyword_minus_minus
		b = str_equals(in, .str_not)
		if b != 0 goto keyword_not
		b = str_equals(in, .str_tilde)
		if b != 0 goto keyword_tilde
		b = str_equals(in, .str_arrow)
		if b != 0 goto keyword_arrow
		b = str_equals(in, .str_dotdotdot)
		if b != 0 goto keyword_dotdotdot
		b = str_equals(in, .str_colon)
		if b != 0 goto keyword_colon
		b = str_equals(in, .str_lbrace)
		if b != 0 goto keyword_lbrace
		b = str_equals(in, .str_rbrace)
		if b != 0 goto keyword_rbrace
		b = str_equals(in, .str_lsquare)
		if b != 0 goto keyword_lsquare
		b = str_equals(in, .str_rsquare)
		if b != 0 goto keyword_rsquare
		b = str_equals(in, .str_lparen)
		if b != 0 goto keyword_lparen
		b = str_equals(in, .str_rparen)
		if b != 0 goto keyword_rparen
		b = str_equals(in, .str_semicolon)
		if b != 0 goto keyword_semicolon
		b = str_equals(in, .str_double)
		if b != 0 goto keyword_double
		b = str_equals(in, .str_int)
		if b != 0 goto keyword_int
		b = str_equals(in, .str_struct)
		if b != 0 goto keyword_struct
		b = str_equals(in, .str_break)
		if b != 0 goto keyword_break
		b = str_equals(in, .str_else)
		if b != 0 goto keyword_else
		b = str_equals(in, .str_long)
		if b != 0 goto keyword_long
		b = str_equals(in, .str_switch)
		if b != 0 goto keyword_switch
		b = str_equals(in, .str_case)
		if b != 0 goto keyword_case
		b = str_equals(in, .str_enum)
		if b != 0 goto keyword_enum
		b = str_equals(in, .str_typedef)
		if b != 0 goto keyword_typedef
		b = str_equals(in, .str_char)
		if b != 0 goto keyword_char
		b = str_equals(in, .str_extern)
		if b != 0 goto keyword_extern
		b = str_equals(in, .str_return)
		if b != 0 goto keyword_return
		b = str_equals(in, .str_union)
		if b != 0 goto keyword_union
		b = str_equals(in, .str_float)
		if b != 0 goto keyword_float
		b = str_equals(in, .str_short)
		if b != 0 goto keyword_short
		b = str_equals(in, .str_unsigned)
		if b != 0 goto keyword_unsigned
		b = str_equals(in, .str_continue)
		if b != 0 goto keyword_continue
		b = str_equals(in, .str_for)
		if b != 0 goto keyword_for
		b = str_equals(in, .str_void)
		if b != 0 goto keyword_void
		b = str_equals(in, .str_default)
		if b != 0 goto keyword_default
		b = str_equals(in, .str_goto)
		if b != 0 goto keyword_goto
		b = str_equals(in, .str_sizeof)
		if b != 0 goto keyword_sizeof
		b = str_equals(in, .str_do)
		if b != 0 goto keyword_do
		b = str_equals(in, .str_if)
		if b != 0 goto keyword_if
		b = str_equals(in, .str_static)
		if b != 0 goto keyword_static
		b = str_equals(in, .str_while)
		if b != 0 goto keyword_while
		
		byte 0xcc
		
		:tokenize_newline
			line_number += 1
			pptoken_skip(&in)
			goto tokenize_loop
		:tokenize_skip_pptoken
			pptoken_skip(&in)
			goto tokenize_loop
		:tokenize_line_directive
			in += 1
			line_number = stoi(in)
			in = memchr(in, 32)
			in += 1
			file_add(in)
			file = file_get_index(in)
			pptoken_skip(&in)
			goto tokenize_loop
		:tokenize_keyword
			*2out = b ; type
			out += 2
			*2out = file
			out += 2
			*4out = line_number
			out += 4
			; no data
			out += 8
			pptoken_skip(&in)
			goto tokenize_loop
		:keyword_comma
			b = SYMBOL_COMMA
			goto tokenize_keyword
		:keyword_eq
			b = SYMBOL_EQ
			goto tokenize_keyword
		:keyword_plus_eq
			b = SYMBOL_PLUS_EQ
			goto tokenize_keyword
		:keyword_minus_eq
			b = SYMBOL_MINUS_EQ
			goto tokenize_keyword
		:keyword_times_eq
			b = SYMBOL_TIMES_EQ
			goto tokenize_keyword
		:keyword_div_eq
			b = SYMBOL_DIV_EQ
			goto tokenize_keyword
		:keyword_percent_eq
			b = SYMBOL_PERCENT_EQ
			goto tokenize_keyword
		:keyword_lshift_eq
			b = SYMBOL_LSHIFT_EQ
			goto tokenize_keyword
		:keyword_rshift_eq
			b = SYMBOL_RSHIFT_EQ
			goto tokenize_keyword
		:keyword_and_eq
			b = SYMBOL_AND_EQ
			goto tokenize_keyword
		:keyword_xor_eq
			b = SYMBOL_XOR_EQ
			goto tokenize_keyword
		:keyword_or_eq
			b = SYMBOL_OR_EQ
			goto tokenize_keyword
		:keyword_question
			b = SYMBOL_QUESTION
			goto tokenize_keyword
		:keyword_or_or
			b = SYMBOL_OR_OR
			goto tokenize_keyword
		:keyword_and_and
			b = SYMBOL_AND_AND
			goto tokenize_keyword
		:keyword_or
			b = SYMBOL_OR
			goto tokenize_keyword
		:keyword_xor
			b = SYMBOL_XOR
			goto tokenize_keyword
		:keyword_and
			b = SYMBOL_AND
			goto tokenize_keyword
		:keyword_eq_eq
			b = SYMBOL_EQ_EQ
			goto tokenize_keyword
		:keyword_not_eq
			b = SYMBOL_NOT_EQ
			goto tokenize_keyword
		:keyword_lt
			b = SYMBOL_LT
			goto tokenize_keyword
		:keyword_gt
			b = SYMBOL_GT
			goto tokenize_keyword
		:keyword_lt_eq
			b = SYMBOL_LT_EQ
			goto tokenize_keyword
		:keyword_gt_eq
			b = SYMBOL_GT_EQ
			goto tokenize_keyword
		:keyword_lshift
			b = SYMBOL_LSHIFT
			goto tokenize_keyword
		:keyword_rshift
			b = SYMBOL_RSHIFT
			goto tokenize_keyword
		:keyword_plus
			b = SYMBOL_PLUS
			goto tokenize_keyword
		:keyword_minus
			b = SYMBOL_MINUS
			goto tokenize_keyword
		:keyword_times
			b = SYMBOL_TIMES
			goto tokenize_keyword
		:keyword_div
			b = SYMBOL_DIV
			goto tokenize_keyword
		:keyword_percent
			b = SYMBOL_PERCENT
			goto tokenize_keyword
		:keyword_plus_plus
			b = SYMBOL_PLUS_PLUS
			goto tokenize_keyword
		:keyword_minus_minus
			b = SYMBOL_MINUS_MINUS
			goto tokenize_keyword
		:keyword_not
			b = SYMBOL_NOT
			goto tokenize_keyword
		:keyword_tilde
			b = SYMBOL_TILDE
			goto tokenize_keyword
		:keyword_arrow
			b = SYMBOL_ARROW
			goto tokenize_keyword
		:keyword_dotdotdot
			b = SYMBOL_DOTDOTDOT
			goto tokenize_keyword
		:keyword_colon
			b = SYMBOL_COLON
			goto tokenize_keyword
		:keyword_lbrace
			b = SYMBOL_LBRACE
			goto tokenize_keyword
		:keyword_rbrace
			b = SYMBOL_RBRACE
			goto tokenize_keyword
		:keyword_lsquare
			b = SYMBOL_LSQUARE
			goto tokenize_keyword
		:keyword_rsquare
			b = SYMBOL_RSQUARE
			goto tokenize_keyword
		:keyword_lparen
			b = SYMBOL_LPAREN
			goto tokenize_keyword
		:keyword_rparen
			b = SYMBOL_RPAREN
			goto tokenize_keyword
		:keyword_semicolon
			b = SYMBOL_SEMICOLON
			goto tokenize_keyword
		:keyword_double
			b = KEYWORD_DOUBLE
			goto tokenize_keyword
		:keyword_int
			b = KEYWORD_INT
			goto tokenize_keyword
		:keyword_struct
			b = KEYWORD_STRUCT
			goto tokenize_keyword
		:keyword_break
			b = KEYWORD_BREAK
			goto tokenize_keyword
		:keyword_else
			b = KEYWORD_ELSE
			goto tokenize_keyword
		:keyword_long
			b = KEYWORD_LONG
			goto tokenize_keyword
		:keyword_switch
			b = KEYWORD_SWITCH
			goto tokenize_keyword
		:keyword_case
			b = KEYWORD_CASE
			goto tokenize_keyword
		:keyword_enum
			b = KEYWORD_ENUM
			goto tokenize_keyword
		:keyword_typedef
			b = KEYWORD_TYPEDEF
			goto tokenize_keyword
		:keyword_char
			b = KEYWORD_CHAR
			goto tokenize_keyword
		:keyword_extern
			b = KEYWORD_EXTERN
			goto tokenize_keyword
		:keyword_return
			b = KEYWORD_RETURN
			goto tokenize_keyword
		:keyword_union
			b = KEYWORD_UNION
			goto tokenize_keyword
		:keyword_float
			b = KEYWORD_FLOAT
			goto tokenize_keyword
		:keyword_short
			b = KEYWORD_SHORT
			goto tokenize_keyword
		:keyword_unsigned
			b = KEYWORD_UNSIGNED
			goto tokenize_keyword
		:keyword_continue
			b = KEYWORD_CONTINUE
			goto tokenize_keyword
		:keyword_for
			b = KEYWORD_FOR
			goto tokenize_keyword
		:keyword_void
			b = KEYWORD_VOID
			goto tokenize_keyword
		:keyword_default
			b = KEYWORD_DEFAULT
			goto tokenize_keyword
		:keyword_goto
			b = KEYWORD_GOTO
			goto tokenize_keyword
		:keyword_sizeof
			b = KEYWORD_SIZEOF
			goto tokenize_keyword
		:keyword_do
			b = KEYWORD_DO
			goto tokenize_keyword
		:keyword_if
			b = KEYWORD_IF
			goto tokenize_keyword
		:keyword_static
			b = KEYWORD_STATIC
			goto tokenize_keyword
		:keyword_while
			b = KEYWORD_WHILE
			goto tokenize_keyword
	:tokenize_loop_end
	
	return 0

function print_tokens
	argument tokens
	local p
	p = tokens
	:print_tokens_loop
		if *2p == 0 goto print_tokens_loop_end
		putn(*2p)
		p += 2
		putc(':)
		putn(*2p)
		p += 2
		putc(':)
		putn(*4p)
		p += 4
		putc(':)
		putn(*8p)
		p += 8
		putc(32)
		goto print_tokens_loop
	:print_tokens_loop_end
	putc(10)
	return
