; returns a string of null character-separated preprocessing tokens and space characters
; this corresponds to translation phases 1-3 in the C89 standard
; each sequence of two or more spaces is replaced with a single space
; spaces around # and ## are removed
function split_into_preprocessing_tokens
	argument filename
	local fd
	local file_contents
	local pptokens
	local pptokens2
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
	p -= 1
	if *1p != 10 goto no_newline_at_end_of_file
	
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
	
	; @NONSTANDARD: this is where trigraphs would go
	
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
	
	pptokens2 = file_contents ; repurpose file contents
	
	; replace each sequence of two or more spaces with a single space
	; "Whether each nonempty sequence of other white-space characters is
	; retained or replaced by one space character is implementation-defined." (C89 § 2.1.1.2)
	in = pptokens
	out = pptokens2
	:join_spaces_loop
		if *1in == 0 goto join_spaces_loop_end
		c = *1in
		pptoken_copy_and_advance(&in, &out)
		if c == 32 goto join_spaces
		goto join_spaces_loop
		:join_spaces
			pptoken_skip_spaces(&in)
			goto join_spaces_loop
	:join_spaces_loop_end
	*1out = 0
	
	; delete space surrounding ## and #
	; we want to delete spaces before # so that all preprocessor directives are at the start of the line
	;   (this makes recognizing them slightly easier)
	in = pptokens2
	out = pptokens
	:delete_hash_spaces_loop
		c = *1in
		if c == 0 goto delete_hash_spaces_loop_end
		if c == '# goto delete_hash_spaces_hash
		pptoken_copy_and_advance(&in, &out)
		goto delete_hash_spaces_loop
		
		:delete_hash_spaces_hash
			if out == pptokens goto copy_and_delete_spaces_after_hash ; little edge case
			p = out - 2
			if *1p != 32 goto copy_and_delete_spaces_after_hash ; no space before ##
			; space before #/##
			; remove it
			out -= 2
			*1out = 0
			:copy_and_delete_spaces_after_hash
			pptoken_copy_and_advance(&in, &out)
			pptoken_skip_spaces(&in)
			goto delete_hash_spaces_loop		
	:delete_hash_spaces_loop_end
	*1out = 0
	
	free(pptokens2)
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
	:no_newline_at_end_of_file
		compile_error(filename, 0, .str_no_newline_at_end_of_file)
	:str_no_newline_at_end_of_file
		string No newline at end of file.
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
	local macro_name
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
			b = isalnum_or_underscore(c)
			if b != 0 goto phase4_try_replacements
			; (fallthrough)
		:phase4_next_pptoken
			pptoken_copy_and_advance(&in, &out)
			goto process_pptoken
		:phase4_next_line
			pptoken_copy_and_advance(&in, &out)
			goto phase4_line
	:phase4_try_replacements
		macro_replacement(filename, line_number, &in, &out)
		goto process_pptoken
	:pp_directive
		pptoken_skip(&in) ; skip #
		pptoken_skip_spaces(&in)
		c = *1in
		if c == 10 goto phase4_next_line ; "null directive" C89 § 3.8.7
		b = str_equals(in, .str_error)
		if b != 0 goto pp_directive_error
		b = str_equals(in, .str_define)
		if b != 0 goto pp_directive_define
		b = str_equals(in, .str_undef)
		if b != 0 goto pp_directive_undef
		goto unrecognized_directive
	:pp_directive_error
		fputs(2, filename)
		fputc(2, ':)
		fputn(2, line_number)
		fputs(2, .str_directive_error)
		exit(1)
	:pp_directive_undef
		pptoken_skip(&in)
		pptoken_skip_spaces(&in)
		macro_name = in
		pptoken_skip(&in)
		pptoken_skip_spaces(&in)
		if *1in != 10 goto bad_undef
		p = look_up_object_macro(macro_name)
		if p == 0 goto undef_not_object
		p -= 2
		*1p = '@ ; replace last character of macro name with @ to "undefine" it
		:undef_not_object
		p = look_up_function_macro(macro_name)
		if p == 0 goto undef_not_function
		p -= 2
		*1p = '@
		:undef_not_function
		goto process_pptoken
	:pp_directive_define
		pptoken_skip(&in)
		pptoken_skip_spaces(&in)
		macro_name = in
		pptoken_skip(&in)
		pptoken_skip_spaces(&in)
		c = *1in
		if c == '( goto function_macro_definition
			; it's an object-like macro, e.g. #define X 47
			
			b = look_up_object_macro(macro_name)
			if b != 0 goto macro_redefinition
			
			p = object_macros + object_macros_size
			; copy name
			p = strcpy(p, macro_name)
			p += 1
			; copy contents
			memccpy_advance(&p, &in, 10) ; copy until newline
			*1p = 255 ; replace newline with special "macro end" character
			p += 1
			object_macros_size = p - object_macros
			goto phase4_next_line
		:function_macro_definition
			; a function-like macro, e.g. #define JOIN(a,b) a##b
			local param_names
			local param_name
			local param_idx
			
			b = look_up_function_macro(macro_name)
			if b != 0 goto macro_redefinition
			
			param_names = malloc(4000)
			pptoken_skip(&in) ; skip opening parenthesis
			pptoken_skip_spaces(&in)
			param_name = param_names
			:macro_params_loop
				c = *1in
				if c == 10 goto phase4_missing_closing_bracket
				b = isalpha_or_underscore(c)
				if b == 0 goto bad_macro_params
				param_name = strcpy(param_name, in)
				param_name += 1
				pptoken_skip(&in)
				pptoken_skip_spaces(&in)
				c = *1in
				if c == ') goto macro_params_loop_end
				if c != ', goto bad_macro_params
				pptoken_skip(&in) ; skip ,
				pptoken_skip_spaces(&in)
				goto macro_params_loop
			:macro_params_loop_end
			
			pptoken_skip(&in) ; skip )
			pptoken_skip_spaces(&in)
			
			p = function_macros + function_macros_size
			p = strcpy(p, macro_name)
			p += 1
			
			:fmacro_body_loop
				if *1in == 10 goto fmacro_body_loop_end
				param_name = param_names
				param_idx = 1
				; check if this token matches any of the parameter names
				:fmacro_param_check_loop
					if *1param_name == 0 goto fmacro_param_check_loop_end
					b = str_equals(in, param_name)
					if b != 0 goto fmacro_param_match
					param_name = memchr(param_name, 0)
					param_name += 1
					param_idx += 1
					goto fmacro_param_check_loop
				:fmacro_param_check_loop_end
					; it's not a parameter; just copy it out
					p = strcpy(p, in)
					p += 1
					pptoken_skip(&in)
					goto fmacro_body_loop
				:fmacro_param_match
					; a match!
					*1p = param_idx ; store the parameter index (1 = first argument) as a pptoken
					p += 2
					pptoken_skip(&in)
					goto fmacro_body_loop
			:fmacro_body_loop_end
			*1p = 255
			p += 1
			function_macros_size = p - function_macros
			free(param_names)
			goto phase4_next_line
	
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
	:macro_redefinition
		; @NONSTANDARD:
		; technically not an error if it was redefined to the same thing, but it's
		; annoying to check for that
		compile_error(filename, line_number, .str_macro_redefinition)
	:str_macro_redefinition
		string Macro redefinition.
		byte 0
	:phase4_missing_closing_bracket
		compile_error(filename, line_number, .str_missing_closing_bracket)
	:bad_macro_params
		compile_error(filename, line_number, .str_bad_macro_params)
	:str_bad_macro_params
		string Bad macro parameter list.
		byte 0
	:bad_undef
		compile_error(filename, line_number, .str_bad_undef)
	:str_bad_undef
		string Bad #undef.
		byte 0

; returns a pointer to the replacement pptokens, or 0 if this macro is not defined
function look_up_macro
	argument macros
	argument name
	local p
	local b
	p = macros
	:macro_lookup_loop
		if *1p == 0 goto return_0
		b = str_equals(p, name)
		if b != 0 goto macro_lookup_loop_end
		; advance to next macro
		p = memchr(p, 255)
		p += 1
		goto macro_lookup_loop
	:macro_lookup_loop_end
	p = memchr(p, 0)
	p += 1
	return p

function look_up_object_macro
	argument name
	return look_up_macro(object_macros, name)

function look_up_function_macro
	argument name
	return look_up_macro(function_macros, name)

; replace pptoken(s) at *p_in into *p_out, advancing both
; NOTE: if *p_in starts with a function-like macro replacement, it is replaced fully,
;       otherwise this function only reads 1 token from *p_in
function macro_replacement
	argument filename
	argument line_number
	argument p_in
	argument p_out
	; "banned" macros prevent #define x x from being a problem
	; C89 § 3.8.3.4
	; "If the name of the macro being replaced is found during this scan
	; of the replacement list, it is not replaced. Further, if any nested
	; replacements encounter the name of the macro being replaced, it is not replaced."
	global 2000 dat_banned_objmacros ; 255-terminated array of strings (initialized in main)
	local old_banned_objmacros_end
	global 2000 dat_banned_fmacros
	local old_banned_fmacros_end
	local banned_fmacros
	local banned_objmacros
	local b
	local c
	local p
	local q
	local replacement
	local in
	local out
	
	in = *8p_in
	out = *8p_out
	banned_objmacros = &dat_banned_objmacros
	banned_fmacros = &dat_banned_fmacros
	old_banned_objmacros_end = memchr(banned_objmacros, 255)
	old_banned_fmacros_end = memchr(banned_fmacros, 255)
	
	p = in
	pptoken_skip(&p)
	if *1p == '( goto fmacro_replacement
	
	p = banned_objmacros
	
	:check_banned_objmacros_loop
		if *1p == 255 goto check_banned_objmacros_loop_end
		b = str_equals(in, p)
		if b != 0 goto no_replacement
		p = memchr(p, 0)
		p += 1
		goto check_banned_objmacros_loop
	:check_banned_objmacros_loop_end
	
	; add this to list of banned macros
	p = strcpy(old_banned_objmacros_end, in)
	p += 1
	*1p = 255
	
	replacement = look_up_object_macro(in)
	if replacement == 0 goto no_replacement
	p = replacement
	pptoken_skip(&in) ; skip macro
	:objreplace_loop
		if *1p == 255 goto done_replacement
		macro_replacement(filename, line_number, &p, &out)
		goto objreplace_loop
	
	:fmacro_replacement
		p = banned_fmacros
		:check_banned_fmacros_loop
			if *1p == 255 goto check_banned_fmacros_loop_end
			b = str_equals(in, p)
			if b != 0 goto no_replacement
			p = memchr(p, 0)
			p += 1
			goto check_banned_fmacros_loop
		:check_banned_fmacros_loop_end
		
		; add this to list of banned macros
		p = strcpy(old_banned_fmacros_end, in)
		p += 1
		*1p = 255
		
		replacement = look_up_function_macro(in)
		if replacement == 0 goto no_replacement
		pptoken_skip(&in) ; skip macro name
		pptoken_skip(&in) ; skip opening bracket
		if *1in == ') goto empty_fmacro_invocation
		
		local arguments
		local fmacro_out
		local fmacro_out_start
		arguments = malloc(4000)
		fmacro_out_start = malloc(8000) ; direct fmacro output. this will need to be re-scanned for macros
		fmacro_out = fmacro_out_start
		
		; store the arguments (separated by 255-characters)
		p = arguments
		:fmacro_arg_loop
			b = fmacro_arg_end(filename, line_number, in)
			b -= in
			memcpy(p, in, b) ; copy the argument to its proper place
			p += b
			in += b ; skip argument
			c = *1in
			in += 2 ; skip , or )
			pptoken_skip_spaces(&in)
			*1p = 255
			p += 1
			if c == ', goto fmacro_arg_loop
		*1p = 255 ; use an additional 255-character to mark the end (note: macro arguments may not be empty)
		
		; print arguments:
		; p += 1
		; p -= arguments
		; syscall(1, 1, arguments, p)
		
		p = replacement
		:freplace_loop
			if *1p == 255 goto freplace_loop_end
			if *1p < 32 goto fmacro_argument
			if *1p == '# goto freplace_hash_operator
			pptoken_copy_and_advance(&p, &fmacro_out)
			goto freplace_loop
			:freplace_hash_operator
				; handle paste and stringify operators
				; NOTE: we already ensured that there's no spaces following #,
				;       and no spaces surrounding ## in split_into_preprocessing_tokens
				p += 1
				if *1p == '# goto freplace_hashhash_operator
				
				; stringify operator
				p += 1 ; skip null separator following #
				q = fmacro_get_arg(filename, line_number, arguments, *1p)
				*1fmacro_out = '"
				fmacro_out += 1
				; @NONSTANDARD: this doesn't work if the argument contains " or \
				:fmacro_stringify_loop
					c = *1q
					q += 1
					if c == 255 goto fmacro_stringify_loop_end
					if c == 0 goto fmacro_stringify_loop
					*1fmacro_out = c
					fmacro_out += 1
					goto fmacro_stringify_loop
				:fmacro_stringify_loop_end
				*1fmacro_out = '"
				fmacro_out += 1
				*1fmacro_out = 0
				fmacro_out += 1
				p += 2 ; skip arg idx & null separator
				goto freplace_loop
				
			:freplace_hashhash_operator
				; the paste operator (e.g. #define JOIN(a,b) a##b)
				; wow! surprisingly simple!
				fmacro_out -= 1
				pptoken_skip(&p)
				goto freplace_loop
		:freplace_loop_end
		
		fmacro_out = fmacro_out_start
		:frescan_loop
			if *1fmacro_out == 0 goto frescan_loop_end
			macro_replacement(filename, line_number, &fmacro_out, &out)
			goto frescan_loop
		:frescan_loop_end
		
		free(arguments)
		free(fmacro_out_start)
		goto done_replacement
		
	:fmacro_argument
		q = p + 3 ; skip these characters: arg idx, null separator, first '#'
		if *1q == '# goto fmacro_argument_no_rescan ; this argument is immediately followed by ## so it shouldn't be scanned for replacements
		q = p - 2 ; skip these characters: null separator, second '#'
		if *1q == '# goto fmacro_argument_no_rescan ; this argument is immediately preceded by ##
		; write argument to *fmacro_out, performing any necessary macro substitutions
		q = fmacro_get_arg(filename, line_number, arguments, *1p)
		:fmacro_arg_replace_loop
			macro_replacement(filename, line_number, &q, &fmacro_out)
			if *1q != 255 goto fmacro_arg_replace_loop
		p += 2 ; skip arg idx & null separator
		goto freplace_loop
		
		:fmacro_argument_no_rescan
			q = fmacro_get_arg(filename, line_number, arguments, *1p)
			fmacro_out = memccpy(fmacro_out, q, 255)
			*1fmacro_out = 0
			p += 2 ; skip arg idx & null separator
			goto freplace_loop
			
	:no_replacement
		pptoken_copy_and_advance(&in, &out)
		; (fallthrough)
	:done_replacement	
		*8p_in = in
		*8p_out = out
		; unban any macros we just banned
		*1old_banned_objmacros_end = 255
		*1old_banned_fmacros_end = 255
		return
	
	:empty_fmacro_invocation
		compile_error(filename, line_number, .str_empty_fmacro_invocation)
	:str_empty_fmacro_invocation
		string No arguments provided to function-like macro.
		byte 0
		
function fmacro_get_arg
	argument filename
	argument line_number
	argument arguments
	argument arg_idx
	:fmacro_argfind_loop
		if *1arguments == 255 goto fmacro_too_few_arguments
		if arg_idx == 1 goto fmacro_arg_found
		arguments = memchr(arguments, 255)
		arguments += 1
		arg_idx -= 1
		goto fmacro_argfind_loop
	:fmacro_arg_found
	return arguments
	:fmacro_too_few_arguments
		compile_error(filename, line_number, .str_fmacro_too_few_arguments)
	:str_fmacro_too_few_arguments
		string Too few arguments to function-like macro.
		byte 0

function fmacro_arg_end
	argument filename
	argument line_number
	argument in
	local bracket_depth
	bracket_depth = 1
	:fmacro_arg_end_loop
		if *1in == 0 goto fmacro_missing_closing_bracket
		if *1in == '( goto fmacro_arg_opening_bracket
		if *1in == ') goto fmacro_arg_closing_bracket
		if *1in == ', goto fmacro_arg_potential_end
		pptoken_skip(&in)
		goto fmacro_arg_end_loop
		:fmacro_arg_potential_end
			if bracket_depth == 1 goto fmacro_arg_end_loop_end
			pptoken_skip(&in)
			goto fmacro_arg_end_loop
		:fmacro_arg_opening_bracket
			bracket_depth += 1
			pptoken_skip(&in)
			goto fmacro_arg_end_loop
		:fmacro_arg_closing_bracket
			bracket_depth -= 1
			if bracket_depth == 0 goto fmacro_arg_end_loop_end
			pptoken_skip(&in)
			goto fmacro_arg_end_loop
	:fmacro_arg_end_loop_end
	
	return in
	
	:fmacro_missing_closing_bracket
		compile_error(filename, line_number, .str_missing_closing_bracket)
	
function print_object_macros
	print_macros(object_macros)
	return

function print_function_macros
	print_macros(function_macros)
	return
	
function print_macros
	argument macros
	local p
	local c
	p = macros
	:print_macros_loop
		if *1p == 0 goto return_0 ; done!
		puts(p)
		putc(':)
		putc(32)
		p = memchr(p, 0)
		p += 1
		:print_replacement_loop
			c = *1p
			if c == 255 goto print_replacement_loop_end
			if c < 32 goto print_macro_param
			putc('{)
			puts(p)
			putc('})
			p = memchr(p, 0)
			p += 1
			goto print_replacement_loop
			:print_macro_param
				putc('{)
				putc('#)
				putn(c)
				putc('})
				p += 2
				goto print_replacement_loop
		:print_replacement_loop_end
			p += 1
			fputc(1, 10)
			goto print_macros_loop

	
