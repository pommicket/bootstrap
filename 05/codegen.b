; CALLING CONVENTION:
;  Here is the process for calling a function:
;     - the caller pushes the arguments on to the stack, from right to left
;     - the caller subtracts sizeof(return type) from rsp, rounded up to the nearest 8 bytes
;     - the caller calls the function
;     - the caller stores away the return value
;     - the caller adds (sizeof(return type) + sizeof arg0 + ... + sizeof argn) to rsp  - where each sizeof is rounded up to the nearest 8 bytes
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

function emit_mov_qword_rsp_plus_imm32_rax
	argument imm32
	; 48 89 84 24 IMM32
	*4code_output = 0x24848948
	code_output += 4
	*4code_output = imm32
	code_output += 4
	return

function emit_mov_rax_qword_rsp_plus_imm32
	argument imm32
	; 48 8b 84 24 IMM32
	*4code_output = 0x24848b48
	code_output += 4
	*4code_output = imm32
	code_output += 4
	return

function emit_mov_rax_imm64
	argument imm64
	; 48 b8 IMM64
	*2code_output = 0xb848
	code_output += 2
	*8code_output = imm64
	code_output += 8
	return

function emit_call_rax
	; ff d0
	*2code_output = 0xd0ff
	code_output += 2
	return

function emit_push_rax
	; 50
	*1code_output = 0x50
	code_output += 1
	return

function emit_syscall
	; 0f 05
	*2code_output = 0x050f
	code_output += 2
	return

function emit_lea_rax_rbp_plus_imm32
	; 48 8d 85 IMM32
	argument imm32
	*2code_output = 0x8d48
	code_output += 2
	*1code_output = 0x85
	code_output += 1
	*4code_output = imm32
	code_output += 4
	return

function emit_rep_movsb
	; f3 a4
	*2code_output = 0xa4f3
	code_output += 2
	return

function emit_movsq
	; 48 a5
	*2code_output = 0xa548
	code_output += 2
	return

; make sure you put the return value in the proper place before calling this
function generate_return
	emit_mov_reg(REG_RSP, REG_RBP)
	emit_mov_rbp_qword_rsp()
	emit_add_rsp_imm32(8)
	emit_ret()
	return

; returns pointer to end of expression
function generate_push_expression
	argument expr
	local c
	c = *1expr
	if c == EXPRESSION_CONSTANT_INT goto generate_push_int
	
	die(.str_genpushexprNI)
	:str_genpushexprNI
		string generate_push_expression not implemented.
		byte 0
	:generate_push_int
		expr += 8
		emit_mov_rax_imm64(*8expr)
		emit_push_rax()
		expr += 8
		return expr

; copy sizeof(type) bytes, rounded up to the nearest 8, from rsi to rdi
function generate_copy_rsi_to_rdi_qwords
	argument type
	local n
	n = type_sizeof(type)
	n = round_up_to_8(n)
	if n == 8 goto rsi2rdi_qwords_simple
	; this is a struct or something, use  rep movsb
	emit_mov_rax_imm64(n)
	emit_mov_reg(REG_RCX, REG_RAX)
	emit_rep_movsb()
	return
	
	:rsi2rdi_qwords_simple
	; copy 8 bytes from rsi to rdi
	; this is a little "optimization" over rep movsb with rcx = 8, mainly it just makes debugging easier (otherwise you'd need 8 `stepi`s in gdb to skip over the instruction)
	emit_movsq()
	return

function generate_statement
	argument statement
	local dat1
	local dat2
	local dat3
	local dat4
	local n
	local p
	local c
	
	dat1 = statement + 8
	dat1 = *8dat1
	dat2 = statement + 16
	dat2 = *8dat2
	dat3 = statement + 24
	dat3 = *8dat3
	dat4 = statement + 32
	dat4 = *8dat4
	
	c = *1statement
	
	if c == STATEMENT_BLOCK goto gen_block
	if c == STATEMENT_RETURN goto gen_return
	; @TODO
	die(.str_genstmtNI)
	:str_genstmtNI
		string generate_statement not implemented.
		byte 0
	:gen_block
		:gen_block_loop
			if *1dat1 == 0 goto gen_block_loop_end
			generate_statement(dat1)
			dat1 += 40
			goto gen_block_loop
		:gen_block_loop_end
		return
	:gen_return
		if dat1 == 0 goto gen_return_noexpr
		generate_push_expression(dat1)
		; copy sizeof(return expression) rounded up to 8 bytes from [rsp] to [rbp+16]
		emit_mov_reg(REG_RSI, REG_RSP)
		emit_lea_rax_rbp_plus_imm32(16)
		emit_mov_reg(REG_RDI, REG_RAX)
		p = dat1 + 4
		generate_copy_rsi_to_rdi_qwords(*4p)
		
		:gen_return_noexpr
		generate_return()
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
		generate_function(function_name, *8p)
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

; emit ELF header and code.
function generate_code
	
	code_output = output_file_data
	emit_qword(0x00010102464c457f) ; elf identifier, 64-bit little endian, ELF version 1
	emit_qword(0) ; reserved
	emit_word(2) ; executable file
	emit_word(0x3e) ; architecture x86-64
	emit_dword(1) ; ELF version 1
	emit_qword(ENTRY_ADDR) ; entry point
	emit_qword(0x40) ; program header table offset
	emit_qword(0) ; section header table offset
	emit_dword(0) ; flags
	emit_word(0x40) ; size of header
	emit_word(0x38) ; size of program header
	emit_word(3) ; # of program headers = 3 (code, rwdata, rodata)
	emit_word(0) ; size of section header
	emit_word(0) ; # of section headers
	emit_word(0) ; index of .shstrtab

	; from /usr/include/elf.h:
	;#define PF_X		(1 << 0)	/* Segment is executable */
	;#define PF_W		(1 << 1)	/* Segment is writable */
	;#define PF_R		(1 << 2)	/* Segment is readable */
	
	; program header 1 (code)
	emit_dword(1) ; loadable segment
	emit_dword(1) ; execute only
	emit_qword(ENTRY_ADDR) ; offset in file
	emit_qword(ENTRY_ADDR) ; virtual address
	emit_qword(0) ; physical address
	emit_qword(TOTAL_CODE_SIZE) ; size in executable file
	emit_qword(TOTAL_CODE_SIZE) ; size when loaded into memory
	emit_qword(4096) ; alignment
	
	; program header 2 (rodata)
	emit_dword(1) ; loadable segment
	emit_dword(4) ; read only
	emit_qword(RODATA_ADDR) ; offset in file
	emit_qword(RODATA_ADDR) ; virtual address
	emit_qword(0) ; physical address
	emit_qword(RODATA_SIZE) ; size in executable file
	emit_qword(RODATA_SIZE) ; size when loaded into memory
	emit_qword(4096) ; alignment
	
	; program header 3 (rwdata)
	emit_dword(1) ; loadable segment
	emit_dword(6) ; read/write
	emit_qword(RWDATA_ADDR) ; offset in file
	emit_qword(RWDATA_ADDR) ; virtual address
	emit_qword(0) ; physical address
	emit_qword(RWDATA_SIZE) ; size in executable file
	emit_qword(RWDATA_SIZE) ; size when loaded into memory
	emit_qword(4096) ; alignment
	
	
	
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
	code_output = output_file_data + ENTRY_ADDR
	; add rsp, 8
	emit_add_rsp_imm32(8)
	; mov rax, rsp  (set rax to argv)
	emit_mov_reg(REG_RAX, REG_RSP)
	; sub rsp, 32  (undo add rsp, 8 from before and add space for argv, argc, return value)
	emit_sub_rsp_imm32(32)
	; mov [rsp+16], rax  (put argv in the right place)
	emit_mov_qword_rsp_plus_imm32_rax(16)
	; mov rax, [rsp+24]  (set rax to argc)
	emit_mov_rax_qword_rsp_plus_imm32(24)
	; mov [rsp+8], rax   (put argc in the right place)
	emit_mov_qword_rsp_plus_imm32_rax(8)
	; mov rax, main
	emit_mov_rax_imm64(main_addr)
	; call rax
	emit_call_rax()
	; mov rax, [rsp]
	emit_mov_rax_qword_rsp_plus_imm32(0)
	; mov rdi, rax
	emit_mov_reg(REG_RDI, REG_RAX)
	; mov rax, 0x3c (SYS_exit)
	emit_mov_rax_imm64(0x3c)
	; syscall
	emit_syscall()
		
	return
	:no_main_function
	die(.str_no_main_function)
	:str_no_main_function
		string Error: No main function.
		byte 0
