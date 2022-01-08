; add 24 + 16 = 40 to the stack pointer to put argc, argv in the right place
byte 0x48
byte 0x81
byte 0xc4
byte 40
byte 0
byte 0
byte 0
goto main

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
	
	input_filename = .str_default_input_filename
	output_filename = .str_default_output_filename
	if argc == 1 goto have_filenames
	if argc != 3 goto usage_error
	input_filename = argv1
	output_filename = argv2
	:have_filenames
	split_into_preprocessing_tokens(input_filename)
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
