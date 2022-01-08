; returns a string of null character-separated preprocessing tokens
; this corresponds to translation phases 1-3 in the C89 standard
function split_into_preprocessing_tokens
	argument filename
	local fd
	local file_contents
	local pptokens
	local p
	local b
	local c
	local in
	local out
	local n
	local line_number
	
	fd = open_r(filename)
	file_contents = malloc(2000000)
	pptokens = malloc(2000000)
	p = file_contents
	:pptokens_read_loop
		n = syscall(0, fd, p, 4096)
		if n == 0 goto pptokens_read_loop_end
		p += n
		goto pptokens_read_loop
	:pptokens_read_loop_end
	
	; okay we read the file. first, delete every backslash-newline sequence (phase 2)
	local newlines ; we add more newlines to keep line numbers right
	newlines = 1
	in = file_contents
	out = file_contents
	:backslashnewline_loop
		c = *1in
		if c == 0 goto backslashnewline_loop_end
		if c == 10 goto proper_newline_loop
		if c != '\ goto not_backslashnewline
			p = in + 1
			c = *1p
			if c != 10 goto not_backslashnewline
				in += 2 ; skip backlash and newline
				newlines += 1 ; add one additional newline the next time around to compensate
				goto backslashnewline_loop
		:not_backslashnewline
			*1out = *1in
			out += 1
			in += 1
			goto backslashnewline_loop
		:proper_newline_loop
			if newlines == 0 goto proper_newline_loop_end
			; output a newline
			*1out = 10
			out += 1
			newlines -= 1
			goto proper_newline_loop
		:proper_newline_loop_end
			newlines = 1
			in += 1
			goto backslashnewline_loop
	:backslashnewline_loop_end
	*1out = 0
	
	; split file into preprocessing tokens, remove comments (phase 3)
	; we're still doing the trick with newlines, this time for ones inside comments
	; this is needed because the following is legal C:
	;   #include/*
	;     */<stdio.h>
	; and is not equivalent to:
	;   #include
	;     <stdio.h>
	newlines = 1
	in = file_contents
	out = pptokens
	line_number = 1
	:pptokens_loop
		c = *1in
		if c == 10 goto pptokens_newline_loop
		if c == 0 goto pptokens_loop_end
		if c == 32 goto pptoken_space
		if c == 9 goto pptoken_space
		b = isdigit(c)
		if b != 0 goto pptoken_number
		b = isalpha_or_underscore(c)
		if b != 0 goto pptoken_identifier
		b = str_startswith(in, .str_comment_start)
		if b != 0 goto pptoken_comment
		; now we check for all the various operators and symbols in C
		
		if c == 59 goto pptoken_single_character ; semicolon
		if c == '( goto pptoken_single_character
		if c == ') goto pptoken_single_character
		if c == '[ goto pptoken_single_character
		if c == '] goto pptoken_single_character
		if c == '{ goto pptoken_single_character
		if c == '} goto pptoken_single_character
		if c == ', goto pptoken_single_character
		if c == '~ goto pptoken_single_character
		if c == '? goto pptoken_single_character
		if c == ': goto pptoken_single_character
		if c == '" goto pptoken_string_or_char_literal
		if c == '' goto pptoken_string_or_char_literal
		b = str_startswith(in, .str_lshift_eq)
		if b != 0 goto pptoken_3_chars
		b = str_startswith(in, .str_rshift_eq)
		if b != 0 goto pptoken_3_chars
		b = str_startswith(in, .str_eq_eq)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_not_eq)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_gt_eq)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_lt_eq)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_plus_plus)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_minus_minus)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_plus_eq)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_minus_eq)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_times_eq)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_div_eq)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_remainder_eq)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_and_eq)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_or_eq)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_xor_eq)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_and_and)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_or_or)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_lshift)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_rshift)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_arrow)
		if b != 0 goto pptoken_2_chars
		b = str_startswith(in, .str_dotdotdot)
		if b != 0 goto pptoken_3_chars
		b = str_startswith(in, .str_hash_hash)
		if b != 0 goto pptoken_2_chars
		if c == '+ goto pptoken_single_character
		if c == '- goto pptoken_single_character
		if c == '* goto pptoken_single_character
		if c == '/ goto pptoken_single_character
		if c == '% goto pptoken_single_character
		if c == '& goto pptoken_single_character
		if c == '| goto pptoken_single_character
		if c == '^ goto pptoken_single_character
		if c == '> goto pptoken_single_character
		if c == '< goto pptoken_single_character
		if c == '! goto pptoken_single_character
		if c == '= goto pptoken_single_character
		if c == '# goto pptoken_single_character
		if c == '. goto pptoken_dot
		
		goto bad_pptoken
		
		:pptoken_comment
			; emit a space ("Each comment is replaced by one space character.")
			*1out = 32
			out += 1
			*1out = 0
			out += 1
			; skip over comment
			:pptoken_comment_loop
				b = str_startswith(in, .str_comment_end)
				if b != 0 goto pptoken_comment_loop_end
				c = *1in
				in += 1
				if c == 0 goto unterminated_comment
				if c == 10 goto pptoken_comment_newline
				goto pptoken_comment_loop
			:pptoken_comment_loop_end
			in += 2 ; skip */
			goto pptokens_loop
			:pptoken_comment_newline
				; keep line numbers correct
				newlines += 1
				goto pptoken_comment_loop
		:pptoken_dot
			; could just be a . or could be .3 -- we need to check if *(in+1) is a digit
			p = in + 1
			b = isdigit(*1p)
			if b != 0 goto pptoken_number
			; okay it's just a dot
			goto pptoken_single_character
		:pptoken_string_or_char_literal
			local delimiter
			local backslash
			delimiter = c
			backslash = 0
			*1out = c
			out += 1
			in += 1
			:pptoken_strchar_loop
				c = *1in
				*1out = c
				in += 1
				out += 1
				if c == '\ goto pptoken_strchar_backslash
				if c == 10 goto unterminated_string
				if c == 0 goto unterminated_string
				b = backslash
				backslash = 0
				if b == 1 goto pptoken_strchar_loop ; string can't end with an odd number of backslashes
				if c == delimiter goto pptoken_strchar_loop_end
				goto pptoken_strchar_loop
				:pptoken_strchar_backslash
					backslash ^= 1
					goto pptoken_strchar_loop
			:pptoken_strchar_loop_end
			*1out = 0
			out += 1
			goto pptokens_loop
		:pptoken_number
			c = *1in
			b = is_ppnumber_char(c)
			if b == 0 goto pptoken_number_end
			*1out = c
			out += 1
			in += 1
			if c == 'e goto pptoken_number_e
			if c == 'E goto pptoken_number_e
			goto pptoken_number
			:pptoken_number_e
				c = *1in
				if c == '+ goto pptoken_number_sign
				if c == '- goto pptoken_number_sign
				goto pptoken_number
			:pptoken_number_sign
				; special code to handle + - immediately following e
				*1out = c
				in += 1
				out += 1
				goto pptoken_number
			:pptoken_number_end
			*1out = 0
			out += 1
			goto pptokens_loop
		:pptoken_identifier
				c = *1in
				b = isalnum_or_underscore(c)
				if b == 0 goto pptoken_identifier_end
				*1out = c
				in += 1
				out += 1
				goto pptoken_identifier
			:pptoken_identifier_end
				*1out = 0
				out += 1
				goto pptokens_loop
		:pptoken_space
			; space character token
			*1out = 32
			in += 1
			out += 1
			*1out = 0
			out += 1
			goto pptokens_loop
		:pptoken_single_character
			; a single character preprocessing token, like {?}
			*1out = c
			in += 1
			out += 1
			*1out = 0
			out += 1
			goto pptokens_loop
		:pptoken_2_chars
			; two-character pptoken (e.g. ##)
			*1out = c
			in += 1
			out += 1
			*1out = *1in
			in += 1
			out += 1
			*1out = 0
			out += 1
			goto pptokens_loop
		:pptoken_3_chars
			; three-character pptoken (e.g. >>=)
			*1out = c
			in += 1
			out += 1
			*1out = *1in
			in += 1
			out += 1
			*1out = *1in
			in += 1
			out += 1
			*1out = 0
			out += 1
			goto pptokens_loop
		:pptokens_newline_loop
			if newlines == 0 goto pptokens_newline_loop_end
			; output a newline
			*1out = 10
			out += 1
			*1out = 0
			out += 1
			line_number += 1
			newlines -= 1
			goto pptokens_newline_loop
		:pptokens_newline_loop_end
			newlines = 1
			in += 1
			goto pptokens_loop	
	:pptokens_loop_end
	
	free(file_contents)
	close(fd)
	return pptokens
	
	:unterminated_comment
		compile_error(filename, line_number, .str_unterminated_comment)
	:str_unterminated_comment
		string Unterminated comment.
		byte 0
	:unterminated_string
		compile_error(filename, line_number, .str_unterminated_string)
	:str_unterminated_string
		string Unterminated string or character literal.
		byte 0
	:bad_pptoken
		compile_error(filename, line_number, .str_bad_pptoken)
	:str_bad_pptoken
		string Bad preprocessing token.
		byte 0

; can the given character appear in a C89 ppnumber?
function is_ppnumber_char
	argument c
	if c == '. goto return_1
	if c < '0 goto return_0
	if c <= '9 goto return_1
	if c < 'A goto return_0
	if c <= 'Z goto return_1
	if c == '_ goto return_1
	if c < 'a goto return_0
	if c <= 'z goto return_1
	goto return_0

function print_pptokens
	argument pptokens
	local p
	p = pptokens
	:print_pptokens_loop
		if *1p == 0 goto print_pptokens_loop_end
		putc('{)
		puts(p)
		putc('})
		p += strlen(p)
		p += 1
		goto print_pptokens_loop
	:print_pptokens_loop_end
	putc(10)
	return

function pptoken_copy_and_advance
	argument p_in
	argument p_out
	local in
	local out
	in = *8p_in
	out = *8p_out
	out = strcpy(out, in)
	in = memchr(in, 0)
	*8p_in = in + 1
	*8p_out = out + 1
	return

function pptoken_skip
	argument p_in
	local in
	in = *8p_in
	in = memchr(in, 0)
	*8p_in = in + 1
	return

; skip any space tokens here
function pptoken_skip_spaces
	argument p_in
	local in
	in = *8p_in
	:pptoken_skip_spaces_loop
		if *1in != 32 goto pptoken_skip_spaces_loop_end
		pptoken_skip(&in)
		goto pptoken_skip_spaces_loop
	:pptoken_skip_spaces_loop_end
	*8p_in = in
	return

; phase 4:
; Preprocessing directives are executed and macro invocations are expanded.
; A #include preprocessing directive causes the named header or source file to be processed from phase 1 through phase 4, recursively.
function translation_phase_4
	argument filename
	argument input
	local output
	local in
	local out
	local p
	local c
	local b
	local line_number
		
	output = malloc(16000000)
	out = output
	in = input
	line_number = 0
	
	:phase4_line
		line_number += 1
		c = *1in
		if c == 0 goto phase4_end
		if c == '# goto pp_directive ; NOTE: ## cannot appear at the start of a line
		
		:process_pptoken
			c = *1in
			if c == 10 goto phase4_next_line
			b = isdigit(c)
			if b != 0 goto phase4_next_pptoken
		
		:phase4_next_pptoken
			pptoken_copy_and_advance(&in, &out)
			goto process_pptoken
		:phase4_next_line
			pptoken_copy_and_advance(&in, &out)
			goto phase4_line
	:pp_directive
		pptoken_skip(&in)
		c = *1in
		if c == 10 goto phase4_next_line ; "null directive" C89 § 3.8.7
		b = str_equals(in, .str_error)
		if b != 0 goto pp_directive_error
		b = str_equals(in, .str_define)
		if b != 0 goto pp_directive_define
		goto unrecognized_directive
	:pp_directive_error
		fputs(2, filename)
		fputc(2, ':)
		fputn(2, line_number)
		fputs(2, .str_directive_error)
		exit(1)
	:pp_directive_define
		local macro_name
		pptoken_skip(&in)
		pptoken_skip_spaces(&in)
		macro_name = in
		pptoken_skip(&in)
		c = *1in
		if c == '( goto function_macro_definition
			; it's an object-like macro, e.g. #define X 47
			p = object_macros + object_macros_size
			; copy name
			p = strcpy(p, macro_name)
			p += 1
			; copy contents
			memccpy_advance(&p, &in, 10) ; copy until newline
			*1p = 255 ; replace newline with special "macro end" character
			p += 1
			object_macros_size = p - object_macros
			in += 2 ; skip newline and following null character
			goto phase4_line
		:function_macro_definition
			; a function-like macro, e.g. #define JOIN(a,b) a##b
			byte 0xcc
	:str_directive_error
		string : #error
		byte 10
		byte 0
	:phase4_end
		return output
	:unrecognized_directive
		compile_error(filename, line_number, .str_unrecognized_directive)
	:str_unrecognized_directive
		string Unrecognized preprocessor directive.
		byte 0

function look_up_object_macro
	argument name
	local p
	p = object_macros
	:objmacro_lookup_loop
		@TODO

function print_object_macros
	local p
	local c
	p = object_macros
	:print_objmacros_loop
		if *1p == 0 goto return_0 ; done!
		puts(p)
		putc(':)
		putc(32)
		p = memchr(p, 0)
		p += 1
		:print_objreplacement_loop
			putc('{)
			puts(p)
			putc('})
			p = memchr(p, 0)
			p += 1
			c = *1p
			if c == 255 goto print_objreplacement_loop_end
			goto print_objreplacement_loop
		:print_objreplacement_loop_end
			p += 1
			fputc(1, 10)
			goto print_objmacros_loop
