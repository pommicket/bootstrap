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
		
		b = get_keyword_id(in)
		if b != 0 goto tokenize_keyword
		
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
	:tokenize_loop_end
	
	return 0

function print_tokens
	argument tokens
	local p
	local s
	p = tokens
	:print_tokens_loop
		if *2p == 0 goto print_tokens_loop_end
		if *2p > 20 goto print_token_keyword 
		fputs(2, .str_print_bad_token)
		exit(1)
		:print_token_keyword
			s = get_keyword_str(*2p)
			puts(s)
			goto print_token_data
		
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
	:str_print_bad_token
		string Unrecognized token type in print_tokens. Aborting.
		byte 10
