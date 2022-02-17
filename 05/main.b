#define G_DEBUG 1

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

; powers of 10, stored in the following format:
;   ulong significand
;   ulong exponent
; where for i = -1023..1023, powers_of_10 + 16*i points to an entry where
;          10^i = significand * 2^exponent
global powers_of_10

global types
global types_bytes_used
; ident list of type IDs
global typedefs
; ident list of enum values
global enumerators
; struct/unions
;  an ident list of pointers to struct data
;    each struct data is an ident list of 64-bit values, (type << 32) | offset
;    for unions, offset will always be 0.
global structures
global structures_bytes_used
; ident map of "locations" (see token_get_location) where structs are defined
; this is used in a horrible way to avoid getting struct redefinition errors from
;   struct A { int x; } a,b;
; it's not foolproof -- you could have   struct A {int x;} a; struct A {float x;} b;   on one line
;   but that seems extremely unlikely to happen
global structure_locations
; file offset/runtime address to write next piece of read-only data; initialized in main
global rodata_end_addr
; file offset/runtime address to write next piece of read-write data; initialized in main
global rwdata_end_addr
global output_file_data
; ident list of global variables. each one is stored as
;  (type << 32) | address
global global_variables
; ident list of functions. each entry is a pointer to a statement (specifically, a STATEMENT_BLOCK)
global function_statements
; ident list mapping function names to function types (TYPE_FUNCTION {...})
global function_types
; statement_datas[0] = pointer to statement data for block-nesting depth 0 (i.e. function bodies)
; statement_datas[1] = pointer to statement data for block-nesting depth 1 (blocks inside functions)
; statement_datas[2] = pointer to statement data for block-nesting depth 2 (blocks inside blocks inside functions)
; etc. up to statement_datas[BLOCK_DEPTH_LIMIT-1]
; these have to be separated for reasons™
global statement_datas
global statement_datas_ends
; ident lists of (type << 32) | address
;  block_static_variables[0] = static variables inside this function
;  block_static_variables[1] = static variables inside this block inside this function
;  etc.
global block_static_variables
; ident lists of (type << 32) | rbp offset; one per block depth   -- note that rbp offset may be negative!
global local_variables
global block_depth
global expressions
global expressions_end
; current rbp offset (where rsp is)
global local_var_rbp_offset
global function_param_names
; set to 1 by parse_type_declarators if at least one function parameter has no name.
global function_param_has_no_name
; ident list of number of bytes of stack space needed by local variables in each function
global functions_required_stack_space
; a map from pc addresses to program locations will be outputted to this file
global address_map_fd

#include util.b
#include idents.b
#include constants.b
#include preprocess.b
#include tokenize.b
#include parse.b
#include codegen.b

function debug_puts
	argument str
	if G_DEBUG == 0 goto return_0
	return puts(str)
function debug_putsln
	argument str
	if G_DEBUG == 0 goto return_0
	return putsln(str)
	
function types_init
	argument _types
	argument ptypes_bytes_used
	local i
	local p
	
	i = 0
	p = _types
	:fill_initial_types_loop
		*1p = i
		p += 1
		i += 1
		if i <= 16 goto fill_initial_types_loop
	p = _types + TYPE_POINTER_TO_CHAR
	*1p = TYPE_POINTER
	p += 1
	*1p = TYPE_CHAR
	p += 1
	p = _types + TYPE_POINTER_TO_VOID
	*1p = TYPE_POINTER
	p += 1
	*1p = TYPE_VOID
	p += 1
	
	*8ptypes_bytes_used = p - types
	return

function fprint_token_location
	argument fd
	argument token
	token += 2
	fprint_filename(fd, *2token)
	token += 2
	fputc(fd, ':)
	fputn(fd, *4token)
	return

function print_token_location
	argument token
	fprint_token_location(1, token)
	return

function print_statement_location
	argument statement
	; statements & tokens have the same format for locations!
	print_token_location(statement)
	return

function fprint_statement_location
	argument fd
	argument statement
	; statements & tokens have the same format for locations!
	fprint_token_location(fd, statement)
	return
	
; accepts EITHER file index OR pointer to filename
function fprint_filename
	argument fd
	argument file
	if file ] 65535 goto print_filename_string
	file = file_get(file)
	; (fallthrough)
	:print_filename_string
	fputs(fd, file)
	return

function print_filename
	argument file
	fprint_filename(1, file)
	return

; accepts EITHER file index OR pointer to filename
function compile_error
	argument file
	argument line
	argument message
	print_filename(file)
	putc(':)
	putn(line)
	puts(.str_error_prefix)
	puts(message)
	putc(10)
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

function statement_error
	argument statement
	argument message
	token_error(statement, message) ; tokens & statements have the same location format

; accepts EITHER file index OR pointer to filename
function compile_warning
	argument file
	argument line
	argument message
	print_filename(file)
	putc(':)
	putn(line)
	puts(.str_warning_prefix)
	puts(message)
	putc(10)
	return
	
:str_error_prefix
	string : Error:
	byte 32
	byte 0

:str_warning_prefix
	string : Warning:
	byte 32
	byte 0

:str_preprocessing
	string Preprocessing...
	byte 10
	byte 0
:str_tokenizing
	string Turning preprocessing tokens into tokens...
	byte 10
	byte 0
:str_parsing
	string Parsing...
	byte 10
	byte 0

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
	local q
	local i
	local output_fd
	local memory
		
	memory = malloc(4000)
	statement_datas = memory
	statement_datas_ends = memory + 400
	block_static_variables = memory + 800
	local_variables = memory + 1200
	function_param_names = memory + 1600
	
	p = statement_datas
	q = statement_datas_ends
	i = 0
	:statement_datas_loop
		*8p = malloc(4000000) ; supports 100,000 statements at each level
		*8q = *8p
		p += 8
		q += 8
		i += 1
		if i < BLOCK_DEPTH_LIMIT goto statement_datas_loop
	p = block_static_variables
	i = 0
	:bsv_alloc_loop
		*8p = malloc(24000) ; more than enough memory to hold static variable names/addresses for a particular block
		p += 8
		i += 1
		if i < BLOCK_DEPTH_LIMIT goto bsv_alloc_loop
	p = local_variables
	i = 0
	:lv_alloc_loop
		*8p = malloc(100000)
		p += 8
		i += 1
		if i < BLOCK_DEPTH_LIMIT goto lv_alloc_loop
	fill_in_powers_of_10()
	
	typedefs = ident_list_create(100000)
	enumerators = ident_list_create(4000000)
	structures = ident_list_create(2000000)
	structure_locations = ident_list_create(2000000)
	global_variables = ident_list_create(400000)
	function_statements = ident_list_create(800000)
	functions_addresses = ident_list_create(800000)
	functions_labels = ident_list_create(800000)
	function_types = ident_list_create(800000)
	functions_required_stack_space = ident_list_create(800000)
	function_stmt_data = malloc(800000) ; should be at least 40 bytes * max # of functions
	
	dat_banned_objmacros = 255
	dat_banned_fmacros = 255
	
	file_list = malloc(40000)
	*1file_list = 255
	object_macros = malloc(4000000)
	function_macros = malloc(4000000)
	expressions = malloc(16000000)
	expressions_end = expressions
	
	types = malloc(16000000)
	types_init(types, &types_bytes_used)
	
	input_filename = .str_default_input_filename
	output_filename = .str_default_output_filename
	if argc == 1 goto have_filenames
	if argc != 3 goto usage_error
	input_filename = argv1
	output_filename = argv2
	:have_filenames
	output_fd = open_rw(output_filename, 493)
	rodata_end_addr = RODATA_ADDR
	rwdata_end_addr = RWDATA_ADDR
	
	ftruncate(output_fd, RWDATA_END)
	output_file_data = mmap(0, RWDATA_END, PROT_READ_WRITE, MAP_SHARED, output_fd, 0)
	if output_file_data ] 0xffffffffffff0000 goto mmap_output_fd_failed
	
	debug_puts(.str_preprocessing)
	
	pptokens = split_into_preprocessing_tokens(input_filename)
	;print_pptokens(pptokens)
	;print_separator()
	processed_pptokens = malloc(16000000)
	translation_phase_4(input_filename, pptokens, processed_pptokens)
	free(pptokens)
	pptokens = processed_pptokens
	;print_pptokens(pptokens)
	;print_separator()
	;print_object_macros()
	;print_function_macros()
	
	debug_puts(.str_tokenizing)
	
	tokens = malloc(16000000)
	p = tokenize(pptokens, tokens, input_filename, 1)
	;print_tokens(tokens, p)
	;print_separator()
	; NOTE: do NOT free pptokens; identifiers still reference them.
	
	debug_puts(.str_parsing)
	parse_tokens(tokens)
	
	address_map_fd = open_w(.str_addrmap_filename, 420)
	
	generate_code()
	
	p = output_file_data + RODATA_ADDR
	munmap(output_file_data, RWDATA_END)
	close(output_fd)
	close(address_map_fd)
	
	;ident_list_printx64(global_variables)
	;puts(.str_types_bytes_used)
	;putnln(types_bytes_used)
	
	exit(0)
	
:str_addrmap_filename
	string address_map.txt
	byte 0

:str_types_bytes_used
	string types_bytes_used:
	byte 32
	byte 0

:mmap_output_fd_failed
	puts(.str_mmap_output_fd_failed)
	exit(1)
:str_mmap_output_fd_failed
	string Couldn't mmap output file.
	byte 10
	byte 0

:usage_error
	puts(.str_usage_error)
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
