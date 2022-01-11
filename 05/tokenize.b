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

; return keyword ID associated with str, or 0 if it's not a keyword
function get_keyword_id
	argument keyword_str
	local p
	local c
	local b
	p = .keyword_table
	:keyword_id_loop
		c = *1p
		if c == 255 goto no_such_keyword_str
		p += 1
		b = str_equals(keyword_str, p)
		if b != 0 goto got_keyword_id
		p = memchr(p, 0)
		p += 1
		goto keyword_id_loop
	:no_such_keyword_str
	return 0
	:got_keyword_id
	return c

; get string associated with keyword id, or "@BAD_KEYWORD_ID" if it's not a keyword
function get_keyword_str
	argument keyword_id
	local p
	local c
	local b
	p = .keyword_table
	:keyword_str_loop
		c = *1p
		if c == 255 goto no_such_keyword_id
		if c == keyword_id goto found_keyword_id
		p = memchr(p, 0)
		p += 1
		goto keyword_str_loop
	:found_keyword_id
		return p + 1
	:no_such_keyword_id
		return .str_no_such_keyword_id
	:str_no_such_keyword_id
		string @BAD_KEYWORD_ID
		byte 0
	
; turn pptokens into tokens, written to out.
; tokens are 16 bytes and have the following format:
;    uchar type
;    uchar info
;    ushort file
;    uint line
;    ulong data
; This corresponds to translation phases 5-6 and the first half of 7
function tokenize
	argument pptokens
	argument out
	local in
	local file
	local line_number
	local b
	local c
	local n
	local data
	
	in = pptokens
	:tokenize_loop
		c = *1in
		if c == '$ goto tokenize_line_directive
		if c == 32 goto tokenize_skip_pptoken
		if c == 10 goto tokenize_newline
		if c == '' goto tokenize_constant_char
		if c == 0 goto tokenize_loop_end
		
		b = get_keyword_id(in)
		if b != 0 goto tokenize_keyword
		
		b = isdigit_or_dot(c)
		if b != 0 goto tokenize_number
		
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
		:token_no_data
			data = 0
			; (fallthrough)
		:token_output ; write token location & data (see local variable data), and continue tokenizing
			*2out = file
			out += 2
			*4out = line_number
			out += 4
			*8out = data
			out += 8
			goto tokenize_loop
		:tokenize_keyword
			pptoken_skip(&in)
			*1out = b ; type
			; no info for keywords
			out += 2
			goto token_no_data
		:tokenize_number
			; first, check if it's a float
			b = strchr(in, '.)
			if b != 0 goto tokenize_float
			b = strchr(in, 'x) ; e may appear in hex integer literals, so we need to check this
			if b != 0 goto tokenize_hex_integer
			b = strchr(in, 'X)
			if b != 0 goto tokenize_hex_integer
			b = strchr(in, 'e) ; exponent
			if b != 0 goto tokenize_float
			b = strchr(in, 'E) ; exponent
			if b != 0 goto tokenize_float
			if *1in == '0 goto tokenize_octal_integer ; fun fact: in the C89 standard, 0 is considered an octal integer
				; plain ol' decimal constant
				n = strtoi(&in, 10)
				goto tokenize_finish_integer
			:tokenize_hex_integer
				if *1in != '0 goto bad_number_token
				in += 1
				c = *1in
				c &= 223 ; 223 = ~32 -- remove case
				if c != 'X goto bad_number_token
				in += 1
				n = strtoi(&in, 16)
				goto tokenize_finish_integer
			:tokenize_octal_integer
				in += 1 ; skip 0
				n = strtoi(&in, 8)
				goto tokenize_finish_integer
			:tokenize_finish_integer
			c = read_number_suffix(file, line_number, &in)
			if c == NUMBER_SUFFIX_F goto f_suffix_on_integer
			in += 1 ; move past null separator
			*1out = TOKEN_CONSTANT_INT
			out += 1
			*1out = c ; info = suffix
			out += 1
			data = n
			goto token_output
		:tokenize_constant_char
			in += 1
			c = read_c_char(&in)
			if *1in != '' goto bad_char_constant
			if c ] 255 goto bad_char_constant
			pptoken_skip(&in)
			*1out = TOKEN_CONSTANT_CHAR
			out += 2 ; no info
			data = c
			goto token_output
		:tokenize_float
			; @TODO
			byte 0xcc
		
	:tokenize_loop_end
	
	return 0
	:f_suffix_on_integer
		compile_error(file, line_number, .str_f_suffix_on_integer)
	:str_f_suffix_on_integer
		string Integer with f suffix.
		byte 0
	:bad_number_token
		compile_error(file, line_number, .str_bad_number_token)
	:str_bad_number_token
		string Bad number literal.
		byte 0
	:bad_char_constant
		compile_error(file, line_number, .str_bad_char_constant)
	:str_bad_char_constant
		string Bad character constant. Note that multibyte constants are not supported.
		byte 0

; return character or escaped character from *p_in, advancing accordingly
; returns -1 on bad character
function read_c_char
	argument p_in
	local in
	local c
	local x
	in = *8p_in
	if *1in == '\ goto escape_sequence
	; no escape sequence; just a normal character
	c = *1in
	in += 1
	goto escape_sequence_return
	
	:escape_sequence
		in += 1
		c = *1in
		in += 1
		if c == 'x goto escape_sequence_hex
		if c == '' goto escape_sequence_single_quote
		if c == '" goto escape_sequence_double_quote
		if c == '? goto escape_sequence_question
		if c == '\ goto escape_sequence_backslash
		if c == 'a goto escape_sequence_bell
		if c == 'b goto escape_sequence_backspace
		if c == 'f goto escape_sequence_form_feed
		if c == 'n goto escape_sequence_newline
		if c == 'r goto escape_sequence_carriage_return
		if c == 't goto escape_sequence_tab
		if c == 'v goto escape_sequence_vertical_tab
		; octal
		in -= 1
		x = isoctdigit(*1in)
		if x == 0 goto return_minus1
		c = *1in - '0
		in += 1
		x = isoctdigit(*1in)
		if x == 0 goto escape_sequence_return
		c <= 3
		c += *1in - '0
		in += 1
		x = isoctdigit(*1in)
		if x == 0 goto escape_sequence_return
		c <= 3
		c += *1in - '0
		in += 1
		if c ] 255 goto return_minus1 ; e.g. '\712'
		goto escape_sequence_return
	:escape_sequence_hex
		x = in
		c = strtoi(&in, 16)
		if in == x goto return_minus1 ; e.g. '\xhello'
		if c ] 255 goto return_minus1 ; e.g. '\xabc'
		goto escape_sequence_return
	:escape_sequence_single_quote
		c = ''
		goto escape_sequence_return
	:escape_sequence_double_quote
		c = '"
		goto escape_sequence_return
	:escape_sequence_question
		c = '?
		goto escape_sequence_return
	:escape_sequence_backslash
		c = '\
		goto escape_sequence_return
	:escape_sequence_bell
		c = 7
		goto escape_sequence_return
	:escape_sequence_backspace
		c = 8
		goto escape_sequence_return
	:escape_sequence_form_feed
		c = 12
		goto escape_sequence_return
	:escape_sequence_newline
		c = 10
		goto escape_sequence_return
	:escape_sequence_carriage_return
		c = 13
		goto escape_sequence_return
	:escape_sequence_tab
		c = 9
		goto escape_sequence_return
	:escape_sequence_vertical_tab
		c = 11
		goto escape_sequence_return
	:escape_sequence_return
	*8p_in = in
	return c
		
		
function read_number_suffix
	argument file
	argument line_number
	argument p_s
	local s
	local c
	local suffix
	s = *8p_s
	c = *1s
	suffix = 0
	if c == 0 goto number_suffix_return
	if c == 'u goto number_suffix_u
	if c == 'l goto number_suffix_l
	if c == 'f goto number_suffix_f
	goto bad_number_suffix
	:number_suffix_u
		s += 1
		c = *1s
		if c == 'l goto number_suffix_ul
		if c != 0 goto bad_number_suffix
		suffix = NUMBER_SUFFIX_U
		goto number_suffix_return
	:number_suffix_l
		s += 1
		c = *1s
		if c == 'u goto number_suffix_ul
		if c != 0 goto bad_number_suffix
		suffix = NUMBER_SUFFIX_L
		goto number_suffix_return
	:number_suffix_ul
		s += 1
		c = *1s
		if c != 0 goto bad_number_suffix
		suffix = NUMBER_SUFFIX_UL
		goto number_suffix_return
	:number_suffix_f
		s += 1
		c = *1s
		if c != 0 goto bad_number_suffix
		suffix = NUMBER_SUFFIX_F
		goto number_suffix_return
	:number_suffix_return
	*8p_s = s
	return suffix
	
	:bad_number_suffix
		compile_error(file, line_number, .str_bad_number_suffix)
	:str_bad_number_suffix
		string Bad number suffix.
		byte 0
	
function print_tokens
	argument tokens
	local p
	local s
	p = tokens
	:print_tokens_loop
		if *1p == 0 goto print_tokens_loop_end
		if *1p > 20 goto print_token_keyword 
		if *1p == TOKEN_CONSTANT_INT goto print_token_int
		if *1p == TOKEN_CONSTANT_CHAR goto print_token_char
		fputs(2, .str_print_bad_token)
		exit(1)
		:print_token_keyword
			s = get_keyword_str(*1p)
			puts(s)
			goto print_token_data
		:print_token_int
			puts(.str_constant_int)
			goto print_token_info
		:print_token_char
			puts(.str_constant_char)
			goto print_token_data
		:print_token_info
		p += 1
		putc('~)
		putn(*1p)
		p -= 1
		:print_token_data
		p += 2
		putc('@)
		putn(*2p)
		p += 2
		putc(':)
		putn(*4p)
		p += 4
		putc(61)
		putn(*8p)
		p += 8
		putc(32)
		goto print_tokens_loop
	:print_tokens_loop_end
	putc(10)
	return
	:str_constant_int
		string integer
		byte 0
	:str_constant_char
		string character
		byte 0
	:str_print_bad_token
		string Unrecognized token type in print_tokens. Aborting.
		byte 10
		byte 0
