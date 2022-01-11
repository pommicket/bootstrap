; add 24 + 16 = 40 to the stack pointer to put argc, argv in the right place
byte 0x48
byte 0x81
byte 0xc4
byte 40
byte 0
byte 0
byte 0
goto main


global object_macros_size
global function_macros_size
; these are allocated in main()
global object_macros
global function_macros

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

#include util.b
#include constants.b
#include preprocess.b
#include tokenize.b

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
	
	dat_banned_objmacros = 255
	dat_banned_fmacros = 255
	
	file_list = malloc(40000)
	*1file_list = 255
	object_macros = malloc(4000000)
	function_macros = malloc(4000000)
	
	input_filename = .str_default_input_filename
	output_filename = .str_default_output_filename
	if argc == 1 goto have_filenames
	if argc != 3 goto usage_error
	input_filename = argv1
	output_filename = argv2
	:have_filenames
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
	tokenize(pptokens, tokens)
	print_tokens(tokens)
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
