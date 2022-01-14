; add 24 + 16 = 40 to the stack pointer to put argc, argv in the right place
byte 0x48
byte 0x81
byte 0xc4
byte 40
byte 0
byte 0
byte 0
goto main

global output_fd


global object_macros_size
global function_macros_size
; these are allocated in main()
global object_macros
global function_macros

function fprint_token_location
	argument fd
	argument token
	token += 2
	fprint_filename(fd, *2token)
	token += 2
	fputc(fd, ':)
	fputn(fd, *4token)
	return

; accepts EITHER file index OR pointer to filename
function fprint_filename
	argument fd
	argument file
	if file ] 65535 goto print_filename_string
	file = file_get(file)
	; (fallthrough)
	:print_filename_string
	fputs(2, file)
	return

; accepts EITHER file index OR pointer to filename
function compile_error
	argument file
	argument line
	argument message
	fprint_filename(2, file)
	fputc(2, ':)
	fputn(2, line)
	fputs(2, .str_error_prefix)
	fputs(2, message)
	fputc(2, 10)
	exit(1)

function token_error
	argument token
	argument message
	local p
	local file
	local line
	p = token + 2
	file = *2p
	p += 2
	line = *4p
	compile_error(file, line, message)

; accepts EITHER file index OR pointer to filename
function compile_warning
	argument file
	argument line
	argument message
	fprint_filename(2, file)
	fputc(2, ':)
	fputn(2, line)
	fputs(2, .str_warning_prefix)
	fputs(2, message)
	fputc(2, 10)
	return
	
:str_error_prefix
	string : Error:
	byte 32
	byte 0

:str_warning_prefix
	string : Warning:
	byte 32
	byte 0

; powers of 10, stored in the following format:
;   ulong significand
;   ulong exponent
; where for i = -1023..1023, powers_of_10 + 16*i points to an entry where
;          10^i = significand * 2^exponent
global powers_of_10

global types
global types_end

#include util.b
#include constants.b
#include preprocess.b
#include tokenize.b
#include parse.b


function main
	argument argv2
	argument argv1
	argument argv0
	argument argc
	local input_filename
	local output_filename
	local pptokens
	local processed_pptokens
	local tokens
	local ast
	local p
	local i
	fill_in_powers_of_10()
	
	dat_banned_objmacros = 255
	dat_banned_fmacros = 255
	
	file_list = malloc(40000)
	*1file_list = 255
	object_macros = malloc(4000000)
	function_macros = malloc(4000000)
	
	types = malloc(16000000)
	i = 0
	p = types
	:fill_initial_types_loop
		*1p = i
		p += 1
		i += 1
		if i <= 16 goto fill_initial_types_loop
	p = types + TYPE_POINTER_TO_CHAR
	*1p = TYPE_POINTER
	p += 1
	*1p = TYPE_CHAR
	
	
	types_end = p
	 
	
	input_filename = .str_default_input_filename
	output_filename = .str_default_output_filename
	if argc == 1 goto have_filenames
	if argc != 3 goto usage_error
	input_filename = argv1
	output_filename = argv2
	:have_filenames
	output_fd = open_w(output_filename)
	rodata_end_offset = RODATA_OFFSET
	
	pptokens = split_into_preprocessing_tokens(input_filename)
	;print_pptokens(pptokens)
	;print_separator()
	processed_pptokens = malloc(16000000)
	translation_phase_4(input_filename, pptokens, processed_pptokens)
	free(pptokens)
	pptokens = processed_pptokens
	print_pptokens(pptokens)
	print_separator()
	;print_object_macros()
	;print_function_macros()
	
	tokens = malloc(16000000)
	p = tokenize(pptokens, tokens, input_filename, 1)
	print_tokens(tokens)
	; NOTE: do NOT free pptokens as identifiers still reference them.
	
	ast = malloc(56000000)
	p -= 16
	parse_expression(tokens, p, ast)
	print_expression(ast)
	putc(10)
	
	exit(0)

:usage_error
	fputs(2, .str_usage_error)
	exit(1)

:str_usage_error
	string Please either specify no arguments or an input and output file.

:str_default_input_filename
	string main.c
	byte 0
	
:str_default_output_filename
	string a.out
	byte 0

; NOTE: this language doesn't have proper support for floating-point numbers,
; but we need to do some float stuff. floats are stored as a 58-bit significand
; and an exponent. the significand ranges from 0 (inclusive) to 0x400000000000000 (exclusive)

function normalize_float
	argument p_significand
	argument p_exponent
	local significand
	local exponent
	
	significand = *8p_significand
	if significand == 0 goto normalize_0
	exponent = *8p_exponent
	
	:float_reduce_loop
		if significand [ 0x400000000000000 goto float_reduce_loop_end
		significand >= 1
		exponent += 1
		goto float_reduce_loop
	:float_reduce_loop_end
	:float_increase_loop
		if significand ]= 0x200000000000000 goto float_increase_loop_end
		significand <= 1
		exponent -= 1
		goto float_increase_loop
	:float_increase_loop_end
	*8p_significand = significand
	*8p_exponent = exponent
	return
	:normalize_0
	*8p_exponent = 0
	return

function fill_in_powers_of_10
	local i
	local p
	local significand
	local exponent
	powers_of_10 = malloc(40000)
	powers_of_10 += 20000
	significand = 1 < 57
	exponent = -57
	i = 0
	:pow10_loop_positive
		p = powers_of_10
		p += i < 4
		*8p = significand
		p += 8
		*8p = exponent
		
		significand *= 10
		normalize_float(&significand, &exponent)
		
		i += 1
		if i < 1024 goto pow10_loop_positive
	significand = 1 < 57
	exponent = -57
	i = 0
	:pow10_loop_negative
		p = powers_of_10
		p += i < 4
		*8p = significand
		p += 8
		*8p = exponent
		
		significand *= 32
		exponent -= 5
		significand /= 10
		normalize_float(&significand, &exponent)
		
		i -= 1
		if i > -1024 goto pow10_loop_negative
	return

function print_powers_of_10
	local i
	local j
	local b
	local p
	local significand
	i = -325
	:print_powers_of_10_loop
		putc(49)
		putc(48)
		putc('^)
		putn_signed(i)
		putc(61)
		
		p = powers_of_10
		p += i < 4
		significand = *8p
		j = 57
		:pow10_binary_loop
			b = significand > j
			b &= 1
			b += '0
			putc(b)
			j -= 1
			if j >= 0 goto pow10_binary_loop
		putc('*)
		putc('2)
		putc('^)
		p += 8
		putn_signed(*8p)
		putc(10)
				
		i += 1
		if i < 325 goto print_powers_of_10_loop
	return
