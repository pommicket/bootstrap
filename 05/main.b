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

function compile_error
	argument file
	argument line
	argument message
	fputs(2, file)
	fputc(2, ':)
	fputn(2, line)
	fputs(2, .str_error_prefix)
	fputs(2, message)
	fputc(2, 10)
	exit(1)
	
:str_error_prefix
	string : Error:
	byte 32
	byte 0

#include util.b
#include constants.b
#include preprocess.b

function main
	argument argv2
	argument argv1
	argument argv0
	argument argc
	local input_filename
	local output_filename
	local pptokens
	
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
	print_pptokens(pptokens)
	print_separator()
	pptokens = translation_phase_4(input_filename, pptokens)
	;print_pptokens(pptokens)
	print_object_macros()
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
