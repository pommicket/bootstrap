; CALLING CONVENTION:
;  Here is the process for calling a function:
;     - the caller pushes the arguments on to the stack, from right to left
;     - the caller subtracts sizeof(return type) from rsp
;     - the caller calls the function
;     - the caller stores away the return value
;     - the caller adds (sizeof(return type) + sizeof arg0 + ... + sizeof argn) to rsp
; STACK LAYOUT:
;    arg n
;    ...
;    arg 0
;    return value   [rbp+16]
;    return address [rbp+8]
;    old rbp        [rbp]
;    local variables



global code_output
global codegen_second_pass ; = 0 on first global pass, 1 on second global pass
global functions_addresses ; ident list of addresses
global functions_labels ; ident list of ident lists of label addresses
global curr_function_labels ; ident list of labels for current function (written to in 1st pass, read from in 2nd pass)

#define REG_RAX 0
#define REG_RBX 3
#define REG_RCX 1
#define REG_RDX 2
#define REG_RSP 4
#define REG_RBP 5
#define REG_RSI 6
#define REG_RDI 7

function emit_byte
	argument byte
	*1code_output = byte
	code_output += 1
	return

function emit_bytes
	argument bytes
	argument count
	memcpy(code_output, bytes, count)
	code_output += count
	return
	
function emit_word
	argument word
	*2code_output = word
	code_output += 2
	return

function emit_dword
	argument word
	*4code_output = word
	code_output += 4
	return

function emit_qword
	argument word
	*8code_output = word
	code_output += 8
	return

; e.g. emit_mov_reg(REG_RAX, REG_RBX)  emits  mov rax, rbx
function emit_mov_reg
	argument dest
	argument src
	local n
	
	;48 89 (DEST|SRC<<3|0xc0)
	*2code_output = 0x8948
	code_output += 2
	n = 0xc0 | dest
	n |= src < 3
	*1code_output = n
	code_output += 1
	return
	

function emit_sub_rsp_imm32
	argument imm32
	;48 81 ec IMM32
	*2code_output = 0x8148
	code_output += 2
	*1code_output = 0xec
	code_output += 1
	*4code_output = imm32
	code_output += 4
	return

function emit_mov_qword_rsp_rbp
	; 48 89 2c 24
	*4code_output = 0x242c8948
	code_output += 4
	return

function emit_mov_rbp_qword_rsp
	; 48 8b 2c 24
	*4code_output = 0x242c8b48
	code_output += 4
	return

function emit_add_rsp_imm32
	argument imm32
	;48 81 c4 IMM32
	*2code_output = 0x8148
	code_output += 2
	*1code_output = 0xc4
	code_output += 1
	*4code_output = imm32
	code_output += 4
	return

function emit_ret
	*1code_output = 0xc3
	code_output += 1
	return

; make sure you put the return value in the proper place before calling this
function generate_return
	emit_mov_reg(REG_RSP, REG_RBP)
	emit_mov_rbp_qword_rsp()
	emit_add_rsp_imm32(8)
	emit_ret()
	return

function generate_statement
	argument statement
	; @TODO
	return

function generate_function
	argument function_name
	argument function_statement
	local out0
	
	if codegen_second_pass != 0 goto genf_second_pass
		curr_function_labels = ident_list_create(4000) ; ~ 200 labels per function should be plenty
		ident_list_add(functions_labels, function_name, curr_function_labels)
		goto genf_cont
	:genf_second_pass
		curr_function_labels = ident_list_lookup(functions_labels, function_name)
	:genf_cont
	
	; prologue
	emit_sub_rsp_imm32(8)
	emit_mov_qword_rsp_rbp()
	emit_mov_reg(REG_RBP, REG_RSP)	
	
	generate_statement(function_statement)
	
	; implicit return at end of function
	generate_return()
	
	return

function generate_functions
	local addr
	local c
	local p
	local function_name
	
	function_name = function_statements
	
	:genfunctions_loop
		if *1function_name == 0 goto genfunctions_loop_end
		addr = code_output - output_file_data ; address of this function
		if codegen_second_pass != 0 goto genfs_check_addr
			; first pass; record address of function
			ident_list_add(functions_addresses, function_name, addr)
			goto genfs_cont
		:genfs_check_addr
			c = ident_list_lookup(functions_addresses, function_name)
			if c != addr goto function_addr_mismatch
			goto genfs_cont
		:genfs_cont
		p = memchr(function_name, 0)
		p += 1
		generate_function(function_name, p)
		function_name = p + 8
		goto genfunctions_loop
	:genfunctions_loop_end
	return
	
	:function_addr_mismatch
		; address of function on 2nd pass doesn't line up with 1st pass
		fputs(2, .str_function_addr_mismatch)
		fputs(2, function_name)
		exit(1)
	:str_function_addr_mismatch
		string Function address on first pass doesn't match 2nd pass:
		byte 32
		byte 0

function generate_code
	local p_func
	code_output = output_file_data + FUNCTIONS_ADDR
	codegen_second_pass = 0
	generate_functions()
	code_output = output_file_data + FUNCTIONS_ADDR
	codegen_second_pass = 1
	generate_functions()
	; generate code at the entry point of the executable
	local main_addr
	main_addr = ident_list_lookup(functions_addresses, .str_main)
	if main_addr == 0 goto no_main_function
	
	; on entry, we will have:
	;   argc = *rsp
	;   argv = rsp + 8
	
	
	; @TODO
	return
	:no_main_function
	die(.str_no_main_function)
	:str_no_main_function
		string Error: No main function.
		byte 0
