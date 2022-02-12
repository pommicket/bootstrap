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
global curr_function_return_type

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

function emit_mov_rax_imm64
	argument imm64
	if imm64 == 0 goto rax_imm64_0
	; 48 b8 IMM64
	*2code_output = 0xb848
	code_output += 2
	*8code_output = imm64
	code_output += 8
	return
	:rax_imm64_0
	emit_zero_rax()
	return

function emit_mov_rbx_imm64
	; 48 bb IMM64
	argument imm64
	*2code_output = 0xbb48
	code_output += 2
	*8code_output = imm64
	code_output += 8
	return

function emit_zero_rax
	; 31 c0
	*2code_output = 0xc031
	code_output += 2
	return
	
function emit_zero_rdx
	; 31 d2
	*2code_output = 0xd231
	code_output += 2
	return
	
function emit_movsx_rax_al
	; 48 0f be c0
	*4code_output = 0xc0be0f48
	code_output += 4
	return

function emit_movsx_rax_ax
	; 48 0f bf c0
	*4code_output = 0xc0bf0f48
	code_output += 4
	return

function emit_movsx_rax_eax
	; 48 63 c0
	*2code_output = 0x6348
	code_output += 2
	*1code_output = 0xc0
	code_output += 1
	return

function emit_movzx_rax_al
	; 48 0f b6 c0
	*4code_output = 0xc0b60f48
	code_output += 4
	return

function emit_movzx_rax_ax
	; 48 0f b7 c0
	*4code_output = 0xc0b70f48
	code_output += 4
	return

function emit_mov_eax_eax
	; 89 c0
	*2code_output = 0xc089
	code_output += 2
	return

function emit_mov_al_byte_rbx
	; 8a 03
	*2code_output = 0x038a
	code_output += 2
	return

function emit_mov_byte_rbx_al
	; 88 03
	*2code_output = 0x0388
	code_output += 2
	return

function emit_mov_ax_word_rbx
	; 66 8b 03
	*2code_output = 0x8b66
	code_output += 2
	*1code_output = 0x03
	code_output += 1
	return

function emit_mov_word_rbx_ax
	; 66 89 03
	*2code_output = 0x8966
	code_output += 2
	*1code_output = 0x03
	code_output += 1
	return

function emit_mov_eax_dword_rbx
	; 8b 03
	*2code_output = 0x038b
	code_output += 2
	return

function emit_mov_dword_rbx_eax
	; 89 03
	*2code_output = 0x0389
	code_output += 2
	return

function emit_mov_rax_qword_rbx
	; 48 8b 03
	*2code_output = 0x8b48
	code_output += 2
	*1code_output = 0x03
	code_output += 1
	return

function emit_mov_qword_rbx_rax
	; 48 89 03
	*2code_output = 0x8948
	code_output += 2
	*1code_output = 0x03
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

function emit_mov_rax_qword_rsp
	emit_mov_rax_qword_rsp_plus_imm32(0)
	return

function emit_mov_qword_rsp_rax
	emit_mov_qword_rsp_plus_imm32_rax(0)
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

function emit_pop_rax
	; 58
	*1code_output = 0x58
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

function emit_lea_rsp_rbp_plus_imm32
	; 48 8d a5 IMM32
	argument imm32
	*2code_output = 0x8d48
	code_output += 2
	*1code_output = 0xa5
	code_output += 1
	*4code_output = imm32
	code_output += 4
	return

function emit_mov_rax_qword_rbp_plus_imm32
	; 48 8b 85 IMM32
	argument imm32
	*2code_output = 0x8b48
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

function emit_movq_rax_xmm0
	; 66 48 0f 7e c0
	*4code_output = 0x7e0f4866
	code_output += 4
	*1code_output = 0xc0
	code_output += 1
	return

function emit_movq_xmm0_rax
	; 66 48 0f 6e c0
	*4code_output = 0x6e0f4866
	code_output += 4
	*1code_output = 0xc0
	code_output += 1
	return

function emit_movq_xmm1_rax
	; 66 48 0f 6e c8
	*4code_output = 0x6e0f4866
	code_output += 4
	*1code_output = 0xc8
	code_output += 1
	return

function emit_movq_xmm1_xmm0
	; f3 0f 7e c8
	*4code_output = 0xc87e0ff3
	code_output += 4
	return

function emit_cvtss2sd_xmm0_xmm0
	; f3 0f 5a c0
	*4code_output = 0xc05a0ff3
	code_output += 4
	return

function emit_cvtsd2ss_xmm0_xmm0
	; f2 0f 5a c0
	*4code_output = 0xc05a0ff2
	code_output += 4
	return

function emit_cvttsd2si_rax_xmm0
	; f2 48 0f 2c c0
	*4code_output = 0x2c0f48f2
	code_output += 4
	*1code_output = 0xc0
	code_output += 1
	return

function emit_cvtsi2sd_xmm0_rax
	; f2 48 0f 2a c0
	*4code_output = 0x2a0f48f2
	code_output += 4
	*1code_output = 0xc0
	code_output += 1
	return

function emit_addsd_xmm0_xmm1
	*4code_output = 0xc1580ff2
	code_output += 4
	return

function emit_subsd_xmm0_xmm1
	*4code_output = 0xc15c0ff2
	code_output += 4
	return

function emit_neg_rax
	; 48 f7 d8
	*2code_output = 0xf748
	code_output += 2
	*1code_output = 0xd8
	code_output += 1
	return

function emit_not_rax
	; 48 f7 d0
	*2code_output = 0xf748
	code_output += 2
	*1code_output = 0xd0
	code_output += 1
	return

function emit_add_rax_rbx
	; 48 01 d8
	*2code_output = 0x0148
	code_output += 2
	*1code_output = 0xd8
	code_output += 1
	return

function emit_sub_rax_rbx
	; 48 29 d8
	*2code_output = 0x2948
	code_output += 2
	*1code_output = 0xd8
	code_output += 1
	return

function emit_imul_rbx
	; 48 f7 eb
	*2code_output = 0xf748
	code_output += 2
	*1code_output = 0xeb
	code_output += 1
	return

function emit_idiv_rbx
	; 48 f7 fb
	*2code_output = 0xf748
	code_output += 2
	*1code_output = 0xfb
	code_output += 1
	return

function emit_mul_rbx
	; 48 f7 e3
	*2code_output = 0xf748
	code_output += 2
	*1code_output = 0xe3
	code_output += 1
	return

function emit_div_rbx
	; 48 f7 f3
	*2code_output = 0xf748
	code_output += 2
	*1code_output = 0xf3
	code_output += 1
	return

function emit_cqo
	; 48 99
	*2code_output = 0x9948
	code_output += 2
	return

function emit_xor_rax_rbx
	; 48 31 d8
	*2code_output = 0x3148
	code_output += 2
	*1code_output = 0xd8
	code_output += 1
	return

function emit_test_rax_rax
	; 48 85 c0
	*2code_output = 0x8548
	code_output += 2
	*1code_output = 0xc0
	code_output += 1
	return

function emit_jmp_rel32
	; e9 REL32
	argument rel32
	*1code_output = 0xe9
	code_output += 1
	*4code_output = rel32
	code_output += 4
	return

function emit_je_rel32
	; 0f 84 REL32
	argument rel32
	*2code_output = 0x840f
	code_output += 2
	*4code_output = rel32
	code_output += 4
	return

function emit_jne_rel32
	; 0f 85 REL32
	argument rel32
	*2code_output = 0x850f
	code_output += 2
	*4code_output = rel32
	code_output += 4
	return

function emit_jl_rel32
	; 0f 8c REL32
	argument rel32
	*2code_output = 0x8c0f
	code_output += 2
	*4code_output = rel32
	code_output += 4
	return

function emit_jg_rel32
	; 0f 8f REL32
	argument rel32
	*2code_output = 0x8f0f
	code_output += 2
	*4code_output = rel32
	code_output += 4
	return

function emit_jle_rel32
	; 0f 8e REL32
	argument rel32
	*2code_output = 0x8e0f
	code_output += 2
	*4code_output = rel32
	code_output += 4
	return

function emit_jge_rel32
	; 0f 8d REL32
	argument rel32
	*2code_output = 0x8d0f
	code_output += 2
	*4code_output = rel32
	code_output += 4
	return

function emit_jb_rel32
	; 0f 82 REL32
	argument rel32
	*2code_output = 0x820f
	code_output += 2
	*4code_output = rel32
	code_output += 4
	return

function emit_ja_rel32
	; 0f 87 REL32
	argument rel32
	*2code_output = 0x870f
	code_output += 2
	*4code_output = rel32
	code_output += 4
	return

function emit_jbe_rel32
	; 0f 86 REL32
	argument rel32
	*2code_output = 0x860f
	code_output += 2
	*4code_output = rel32
	code_output += 4
	return

function emit_jae_rel32
	; 0f 83 REL32
	argument rel32
	*2code_output = 0x830f
	code_output += 2
	*4code_output = rel32
	code_output += 4
	return

function emit_comisd_xmm0_xmm1
	; 66 0f 2f c1
	*4code_output = 0xc12f0f66
	code_output += 4
	return

; make sure you put the return value in the proper place before calling this
function generate_return
	emit_mov_reg(REG_RSP, REG_RBP)
	emit_mov_rbp_qword_rsp()
	emit_add_rsp_imm32(8)
	emit_ret()
	return

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

; cast whatever was just pushed onto the stack from from_type to to_type
; `statement` is used for errors
function generate_cast_top_of_stack
	argument statement
	argument from_type
	argument to_type
	local from
	local to
	local c
	local d
	
	from = types + from_type
	to = types + to_type
	
	if *1to == TYPE_VOID goto return_0 ; cast to void my ass
	if *1from == TYPE_VOID goto bad_gen_cast ; cast from void to something - that's bad
	if *1from == TYPE_ARRAY goto bad_gen_cast ; cast array (this probably won't ever happen because of decaying)
	if *1to == TYPE_ARRAY goto bad_gen_cast ; cast to array
	if *1from == TYPE_FUNCTION goto bad_gen_cast ; shouldn't happen
	if *1to == TYPE_FUNCTION goto bad_gen_cast ; shouldn't happen
	if *1to == TYPE_STRUCT goto gen_cast_to_struct
	if *1from == TYPE_STRUCT goto bad_gen_cast ; cast from struct to something else
	if *1to < TYPE_FLOAT goto gen_cast_to_integer
	if *1to == TYPE_POINTER goto gen_cast_to_integer ; pointers are basically integers
	
	; cast to float/double
	if *1from == TYPE_POINTER goto bad_gen_cast ; pointer to float/double
	if *1to == *1from goto return_0
	if *1from == TYPE_DOUBLE goto gen_cast_double_to_float
	if *1from == TYPE_FLOAT goto gen_cast_float_to_double
	; int to float/double
	if *1to == TYPE_FLOAT goto gen_cast_int_to_float
	if *1to == TYPE_DOUBLE goto gen_cast_int_to_double
	
	goto bad_gen_cast ; in theory we shouldn't get here
	
	:gen_cast_to_integer
		if *1from == *1to goto return_0 ; casting from type to same type
		if *1from == TYPE_POINTER goto return_0 ; no need to do anything
		; cast float/double to integer
		if *1from == TYPE_FLOAT goto gen_cast_float_to_int
		if *1from == TYPE_DOUBLE goto gen_cast_double_to_int
		
		c = type_sizeof(*1from)
		d = type_sizeof(*1to)
		if d > c goto return_0 ; casting to bigger type, so we're good
		if d == 8 goto return_0 ; casting from unsigned/signed long to unsigned/signed long/pointer, we're good
		
		; mov rax, [rsp]
		emit_mov_rax_qword_rsp()
		
		; now sign/zero extend the lower part of rax to the whole of rax		
		if *1to == TYPE_CHAR goto gen_cast_integer_to_signed_char
		if *1to == TYPE_UNSIGNED_CHAR goto gen_cast_integer_to_unsigned_char
		if *1to == TYPE_SHORT goto gen_cast_integer_to_signed_short
		if *1to == TYPE_UNSIGNED_SHORT goto gen_cast_integer_to_unsigned_short
		if *1to == TYPE_INT goto gen_cast_integer_to_signed_int
		if *1to == TYPE_UNSIGNED_INT goto gen_cast_integer_to_unsigned_int
		
		goto bad_gen_cast ; in theory we shouldn't get here
		
		:int2int_cast_cont
		; mov [rsp], rax
		emit_mov_qword_rsp_rax()
		return
		
		:gen_cast_integer_to_signed_char
			emit_movsx_rax_al()
			goto int2int_cast_cont
		:gen_cast_integer_to_unsigned_char
			emit_movzx_rax_al()
			goto int2int_cast_cont
		:gen_cast_integer_to_signed_short
			emit_movsx_rax_ax()
			goto int2int_cast_cont
		:gen_cast_integer_to_unsigned_short
			emit_movzx_rax_ax()
			goto int2int_cast_cont
		:gen_cast_integer_to_signed_int
			emit_movsx_rax_eax()
			goto int2int_cast_cont
		:gen_cast_integer_to_unsigned_int
			emit_mov_eax_eax()
			goto int2int_cast_cont
	:gen_cast_to_struct
		; this is necessary because we add an implicit cast for return values
		; so if we didn't have this, we wouldn't be able to return structs.
		if *1from != TYPE_STRUCT goto bad_gen_cast
		from += 1
		to += 1
		if *8from != *8to goto bad_gen_cast
		return ; no casting needed; these are the same type
	:gen_cast_double_to_float
		; mov rax, [rsp]
		emit_mov_rax_qword_rsp()
		; movq xmm0, rax
		emit_movq_xmm0_rax()
		; cvtsd2ss xmm0, xmm0
		emit_cvtsd2ss_xmm0_xmm0()
		; movq rax, xmm0
		emit_movq_rax_xmm0()
		; mov [rsp], rax
		emit_mov_qword_rsp_rax()
		return
	:gen_cast_float_to_double
		; mov rax, [rsp]
		emit_mov_rax_qword_rsp()
		; movq xmm0, rax
		emit_movq_xmm0_rax()
		; cvtss2sd xmm0, xmm0
		emit_cvtss2sd_xmm0_xmm0()
		; movq rax, xmm0
		emit_movq_rax_xmm0()
		; mov [rsp], rax
		emit_mov_qword_rsp_rax()
		return
	:gen_cast_int_to_float
		; to reduce # of instructions, we first convert int to double, then double to float
		; mov rax, [rsp]
		emit_mov_rax_qword_rsp()
		; cvtsi2sd xmm0, rax
		emit_cvtsi2sd_xmm0_rax()
		; cvtsd2ss xmm0, xmm0
		emit_cvtsd2ss_xmm0_xmm0()
		; movq rax, xmm0
		emit_movq_rax_xmm0()
		; mov [rsp], rax
		emit_mov_qword_rsp_rax()
		; it shouldn't matter that there's junk at [rsp+4]
		return
	:gen_cast_int_to_double
		; mov rax, [rsp]
		emit_mov_rax_qword_rsp()
		; cvtsi2sd xmm0, rax
		emit_cvtsi2sd_xmm0_rax()
		; movq rax, xmm0
		emit_movq_rax_xmm0()
		; mov [rsp], rax
		emit_mov_qword_rsp_rax()
		return
	:gen_cast_float_to_int
		; mov rax, [rsp]
		emit_mov_rax_qword_rsp()
		; movq xmm0, rax
		emit_movq_xmm0_rax()
		; convert float to double, then double to int
		; cvtss2sd xmm0, xmm0
		emit_cvtss2sd_xmm0_xmm0()
		; cvttsd2si rax, xmm0
		emit_cvttsd2si_rax_xmm0()
		; mov [rsp], rax
		emit_mov_qword_rsp_rax()
		return
	:gen_cast_double_to_int
		; mov rax, [rsp]
		emit_mov_rax_qword_rsp()
		; movq xmm0, rax
		emit_movq_xmm0_rax()
		; cvttsd2si rax, xmm0
		emit_cvttsd2si_rax_xmm0()
		; mov [rsp], rax
		emit_mov_qword_rsp_rax()
		return
	
	:bad_gen_cast
		print_statement_location(statement)
		puts(.str_bad_gen_cast1)
		print_type(from_type)
		puts(.str_bad_gen_cast2)
		print_type(to_type)
		putc(10)
		exit(1)
	:str_bad_gen_cast1
		string : Error: Cannot convert type
		byte 32
		byte 0
	:str_bad_gen_cast2
		string  to type
		byte 32
		byte 0
	
; push expr, casted to to_type, onto the stack
; returns pointer to end of expr
function generate_push_expression_casted
	argument statement
	argument expr
	argument to_type
	
	local from_type
	
	from_type = expr + 4
	from_type = *4from_type
	
	expr = generate_push_expression(statement, expr)
	generate_cast_top_of_stack(statement, from_type, to_type)
	return expr

; if type is a pointer type, returns the size of the underlying type
; otherwise, returns 1
;   this is so that (int *)p + 5 adds 20 to p, instead of 5
function scale_rax_for_addition_with
	argument type
	local p
	p = types + type
	if *1p != TYPE_POINTER goto return_0
	
	local n
	p = type + 1
	n = type_sizeof(p)
	; now scale rax by n
	emit_mov_rbx_imm64(n)
	emit_mul_rbx()
	return

; pop the top two things off of the stack, and push their sum
; the things should both have type `out_type` on the stack, but their original types are given by type1,2
function generate_stack_add
		argument statement ; for errors (currently unused)
		argument type1 ; type of 1st operand
		argument type2 ; type of 2nd operand
		argument out_type
		
		
		out_type += types
		if *1out_type == TYPE_FLOAT goto generate_add_floats
		if *1out_type == TYPE_DOUBLE goto generate_add_doubles
		
		emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp]   (second operand)
		scale_rax_for_addition_with(type1) ; in case this is a pointer addition
		emit_mov_reg(REG_RSI, REG_RAX)       ; mov rsi, rax
		emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8]  (first operand)
		scale_rax_for_addition_with(type2) ; in case this is a pointer addition
		emit_mov_reg(REG_RBX, REG_RSI)       ; mov rbx, rsi
		emit_add_rax_rbx()                   ; add rax, rbx
		emit_add_rsp_imm32(8)                ; add rsp, 8
		emit_mov_qword_rsp_rax()             ; mov [rsp], rax
		return
		
		:generate_add_floats
			emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp] (second operand)
			emit_movq_xmm0_rax()                 ; movq xmm0, rax
			emit_cvtss2sd_xmm0_xmm0()            ; cvtss2sd xmm0, xmm0
			emit_movq_xmm1_xmm0()                ; movq xmm1, xmm0
			emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8] (first operand)
			emit_movq_xmm0_rax()                 ; movq xmm0, rax
			emit_addsd_xmm0_xmm1()               ; addsd xmm0, xmm1
			emit_cvtsd2ss_xmm0_xmm0()            ; cvtsd2ss xmm0, xmm0
			emit_movq_rax_xmm0()                 ; movq rax, xmm0
			emit_add_rsp_imm32(8)                ; add rsp, 8
			emit_mov_qword_rsp_rax()             ; mov [rsp], rax			
			return
			
		:generate_add_doubles
			emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp] (second operand)
			emit_movq_xmm1_rax()                 ; movq xmm1, rax
			emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8] (first operand)
			emit_movq_xmm0_rax()                 ; movq xmm0, rax
			emit_addsd_xmm0_xmm1()               ; addsd xmm0, xmm1
			emit_movq_rax_xmm0()                 ; movq rax, xmm0
			emit_add_rsp_imm32(8)                ; add rsp, 8
			emit_mov_qword_rsp_rax()             ; mov [rsp], rax			
			return

; pop the top two things off of the stack, and push their difference
; the things should both have type `out_type` on the stack, but their original types are given by type1,2
function generate_stack_sub
		argument statement ; for errors
		argument type1 ; type of 1st operand
		argument type2 ; type of 2nd operand
		argument out_type
		local p
		
		p = types + out_type
		if *1p == TYPE_FLOAT goto generate_sub_floats
		if *1p == TYPE_DOUBLE goto generate_sub_doubles
		p = types + type2
		if *1p == TYPE_POINTER goto generate_sub_pointers
		
		emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp]   (second operand)
		scale_rax_for_addition_with(type1) ; in case this is a pointer - integer subtraction
		emit_mov_reg(REG_RSI, REG_RAX)       ; mov rsi, rax
		emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8]  (first operand)
		emit_mov_reg(REG_RBX, REG_RSI)       ; mov rbx, rsi
		emit_sub_rax_rbx()                   ; sub rax, rbx
		emit_add_rsp_imm32(8)                ; add rsp, 8
		emit_mov_qword_rsp_rax()             ; mov [rsp], rax
		return
		
		:generate_sub_pointers
			; pointer difference - need to divide by object size
			local sz1
			local sz2
			p = types + type1
			if *1p != TYPE_POINTER goto bad_pointer_diff
			p = type1 + 1
			sz1 = type_sizeof(p)
			p = type2 + 1
			sz2 = type_sizeof(p)
			if sz1 != sz2 goto bad_pointer_diff
			
			emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp]   (second operand)
			emit_mov_reg(REG_RSI, REG_RAX)       ; mov rsi, rax
			emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8]  (first operand)
			emit_mov_reg(REG_RBX, REG_RSI)       ; mov rbx, rsi
			emit_sub_rax_rbx()                   ; sub rax, rbx
			emit_add_rsp_imm32(8)                ; add rsp, 8
			emit_mov_rbx_imm64(sz1)              ; mov rbx, (object size)
			emit_zero_rdx()                      ; xor edx, edx
			emit_div_rbx()                       ; div rbx
			emit_mov_qword_rsp_rax()             ; mov [rsp], rax
			return
			
			:bad_pointer_diff
				statement_error(statement, .str_bad_pointer_diff)
			:str_bad_pointer_diff
				string Subtraction of incompatible pointer types.
				byte 0
		:generate_sub_floats
			emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp] (second operand)
			emit_movq_xmm0_rax()                 ; movq xmm0, rax
			emit_cvtss2sd_xmm0_xmm0()            ; cvtss2sd xmm0, xmm0
			emit_movq_xmm1_xmm0()                ; movq xmm1, xmm0
			emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8] (first operand)
			emit_movq_xmm0_rax()                 ; movq xmm0, rax
			emit_subsd_xmm0_xmm1()               ; subsd xmm0, xmm1
			emit_cvtsd2ss_xmm0_xmm0()            ; cvtsd2ss xmm0, xmm0
			emit_movq_rax_xmm0()                 ; movq rax, xmm0
			emit_add_rsp_imm32(8)                ; add rsp, 8
			emit_mov_qword_rsp_rax()             ; mov [rsp], rax			
			return
			
		:generate_sub_doubles
			emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp] (second operand)
			emit_movq_xmm1_rax()                 ; movq xmm1, rax
			emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8] (first operand)
			emit_movq_xmm0_rax()                 ; movq xmm0, rax
			emit_subsd_xmm0_xmm1()               ; subsd xmm0, xmm1
			emit_movq_rax_xmm0()                 ; movq rax, xmm0
			emit_add_rsp_imm32(8)                ; add rsp, 8
			emit_mov_qword_rsp_rax()             ; mov [rsp], rax			
			return

; pop a pointer off of the stack, then push the dereferenced value according to `type`
function generate_stack_dereference
	argument statement ; for errors
	argument type
	local p
	local size
	local c
	
	size = type_sizeof(type)
	emit_mov_rax_qword_rsp()       ; mov rax, [rsp]
	emit_mov_reg(REG_RBX, REG_RAX) ; mov rbx, rax
	if size == 1 goto gen_deref1
	if size == 2 goto gen_deref2
	if size == 4 goto gen_deref4
	if size == 8 goto gen_deref8
	
	emit_pop_rax()                  ; pop rax
	emit_mov_reg(REG_RSI, REG_RAX)  ; mov rsi, rax
	c = round_up_to_8(size)
	emit_sub_rsp_imm32(c)           ; sub rsp, (size)
	emit_mov_reg(REG_RDI, REG_RSP)  ; mov rdi, rsp
	emit_mov_rax_imm64(size)        ; mov rax, (size)
	emit_mov_reg(REG_RCX, REG_RAX)  ; mov rcx, rax
	emit_rep_movsb()                ; rep movsb
	return
	
	:gen_deref_cast
		emit_mov_qword_rsp_rax()
		p = types + type
		if *1p >= TYPE_LONG goto return_0
		generate_cast_top_of_stack(statement, TYPE_UNSIGNED_LONG, type)
		return
	:gen_deref1
		emit_mov_al_byte_rbx()
		goto gen_deref_cast
	:gen_deref2
		emit_mov_ax_word_rbx()
		goto gen_deref_cast
	:gen_deref4
		emit_mov_eax_dword_rbx()
		goto gen_deref_cast
	:gen_deref8
		emit_mov_rax_qword_rbx()
		goto gen_deref_cast

; returns pointer to end of expr
function generate_push_address_of_expression
	argument statement ; for errors
	argument expr
	
	local c
	local d
	
	c = *1expr
	
	if c == EXPRESSION_GLOBAL_VARIABLE goto addrof_global_var
	if c == EXPRESSION_LOCAL_VARIABLE goto addrof_local_var
	if c == EXPRESSION_DEREFERENCE goto addrof_dereference
	if c == EXPRESSION_SUBSCRIPT goto addrof_subscript
	if c == EXPRESSION_DOT goto addrof_dot
	if c == EXPRESSION_ARROW goto addrof_arrow
	
	statement_error(statement, .str_bad_lvalue)
	:str_bad_lvalue
		string Bad l-value.
		byte 0
	:addrof_global_var
		expr += 8
		emit_mov_rax_imm64(*4expr)
		emit_push_rax()
		expr += 8
		return expr
	:addrof_local_var
		expr += 8
		emit_lea_rax_rbp_plus_imm32(*4expr)
		emit_push_rax()
		expr += 8
		return expr
	:addrof_dereference
		expr += 8
		return generate_push_expression(statement, expr)
	:addrof_subscript
		expr += 8
		c = expr + 4 ; type 1
		c = *4c
		expr = generate_push_expression(statement, expr)
		d = expr + 4 ; type 2
		d = *4d
		expr = generate_push_expression(statement, expr)
		generate_stack_add(statement, c, d, c)
		return expr
	:addrof_dot
		expr += 8
		expr = generate_push_address_of_expression(statement, expr)
		goto addrof_dot_cont
	:addrof_arrow
		expr += 8
		expr = generate_push_expression(statement, expr)
		:addrof_dot_cont
		emit_mov_rax_qword_rsp()       ; mov rax, [rsp]
		emit_mov_reg(REG_RBX, REG_RAX) ; mov rbx, rax
		emit_mov_rax_imm64(*8expr)     ; mov rax, (offset to member)
		emit_add_rax_rbx()             ; add rax, rbx
		emit_mov_qword_rsp_rax()       ; mov [rsp], rax
		expr += 8
		return expr

; `statement` is used for errors
; returns pointer to end of expression
function generate_push_expression
	argument statement
	argument expr
	local b
	local c
	local d
	local p
	local type
	type = expr + 4
	type = *4type
	
	c = *1expr
	if c == EXPRESSION_CONSTANT_INT goto generate_int
	if c == EXPRESSION_CONSTANT_FLOAT goto generate_float
	if c == EXPRESSION_CAST goto generate_cast
	if c == EXPRESSION_UNARY_PLUS goto generate_cast ; the unary plus operator just casts to the promoted type
	if c == EXPRESSION_UNARY_MINUS goto generate_unary_minus
	if c == EXPRESSION_BITWISE_NOT goto generate_unary_bitwise_not
	if c == EXPRESSION_LOGICAL_NOT goto generate_unary_logical_not
	if c == EXPRESSION_ADD goto generate_add
	if c == EXPRESSION_SUB goto generate_sub
	if c == EXPRESSION_GLOBAL_VARIABLE goto generate_global_variable
	if c == EXPRESSION_LOCAL_VARIABLE goto generate_local_variable
	if c == EXPRESSION_DEREFERENCE goto generate_dereference
	if c == EXPRESSION_SUBSCRIPT goto generate_subscript
	if c == EXPRESSION_ADDRESS_OF goto generate_address_of
	if c == EXPRESSION_DOT goto generate_dot_or_arrow
	if c == EXPRESSION_ARROW goto generate_dot_or_arrow
	if c == EXPRESSION_COMMA goto generate_comma
	
	die(.str_genpushexprNI)
	:str_genpushexprNI
		string generate_push_expression not implemented.
		byte 0
	:generate_cast
		expr += 8
		expr = generate_push_expression_casted(statement, expr, type)
		return expr
	:generate_unary_minus
		expr += 8
		expr = generate_push_expression_casted(statement, expr, type)
		p = types + type
		if *1p == TYPE_FLOAT goto generate_unary_minus_float
		if *1p == TYPE_DOUBLE goto generate_unary_minus_double
		; it's just an integer
		emit_mov_rax_qword_rsp() ; mov rax, [rsp]
		emit_neg_rax()           ; neg rax
		emit_mov_qword_rsp_rax() ; mov [rsp], rax
		return expr
		; "negate(x) copies a floating-point operand x to a destination in the same format, reversing the sign bit." IEEE 754 § 5.5.1
		:generate_unary_minus_float
			c = 1 < 31 ; sign bit for floats
			goto generate_unary_minus_floating
		:generate_unary_minus_double
			c = 1 < 63 ; sign bit for doubles
			:generate_unary_minus_floating
			emit_mov_rax_qword_rsp()       ; mov rax, [rsp]
			emit_mov_reg(REG_RBX, REG_RAX) ; mov rbx, rax
			emit_mov_rax_imm64(c)          ; mov rax, (sign bit)
			emit_xor_rax_rbx()             ; xor rax, rbx
			emit_mov_qword_rsp_rax()       ; mov [rsp], rax
			return expr
	:generate_unary_bitwise_not
		expr += 8
		expr = generate_push_expression(statement, expr) ; we'll cast after we take the bitwise not.
		emit_mov_rax_qword_rsp()  ; mov rax, [rsp]
		emit_not_rax()            ; not rax
		emit_mov_qword_rsp_rax()  ; mov [rsp], rax
		generate_cast_top_of_stack(statement, TYPE_UNSIGNED_LONG, type)
		return expr
	:generate_address_of
		expr += 8
		expr = generate_push_address_of_expression(statement, expr)
		return expr
	:generate_add
		expr += 8
		c = expr + 4 ; type of 1st operand
		expr = generate_push_expression_casted(statement, expr, type)
		d = expr + 4 ; type of 2nd operand
		expr = generate_push_expression_casted(statement, expr, type)
		generate_stack_add(statement, *4c, *4d, type)
		return expr
	:generate_sub
		expr += 8
		c = expr + 4 ; type of 1st operand
		expr = generate_push_expression_casted(statement, expr, type)
		d = expr + 4 ; type of 2nd operand
		expr = generate_push_expression_casted(statement, expr, type)
		generate_stack_sub(statement, *4c, *4d, type)
		return expr
	:generate_unary_logical_not
		expr += 8
		p = expr + 4
		p = types + *4p
		if *1p == TYPE_FLOAT goto generate_logical_not_floating
		if *1p == TYPE_DOUBLE goto generate_logical_not_floating
		
		expr = generate_push_expression(statement, expr)
		
		emit_mov_rax_qword_rsp()  ; mov rax, [rsp]
		emit_test_rax_rax()       ; test rax, rax
		:generate_logical_not_cont
		emit_je_rel32(7)          ; je +7   (2 bytes for xor eax, eax; 5 bytes for jmp +10)
		emit_zero_rax()           ; xor eax, eax
		emit_jmp_rel32(10)        ; jmp +10 (10 bytes for mov rax, 1)
		emit_mov_rax_imm64(1)     ; mov rax, 1
		emit_mov_qword_rsp_rax()  ; mov [rsp], rax
		return expr
		
		:generate_logical_not_floating
			; we want !-0.0 to be 1, so this needs to be a separate case
			expr = generate_push_expression_casted(statement, expr, TYPE_DOUBLE) ; cast floats to doubles when comparing
			emit_zero_rax()           ; xor eax, eax
			emit_movq_xmm1_rax()      ; movq xmm1, rax
			emit_mov_rax_qword_rsp()  ; mov rax, [rsp]
			emit_movq_xmm0_rax()      ; movq xmm0, rax
			emit_comisd_xmm0_xmm1()   ; comisd xmm0, xmm1
			goto generate_logical_not_cont
	:generate_global_variable
		expr += 8
		d = *4expr ; address
		expr += 4
		b = *4expr ; is array?
		expr += 4
		if b != 0 goto global_var_array
		c = type_sizeof(type)
		if c > 8 goto global_var_large
		emit_mov_rbx_imm64(d)    ; mov rbx, (address)
		emit_mov_rax_qword_rbx() ; mov rax, [rbx]
		emit_push_rax()          ; push rax
		p = types + type
		if *1p < TYPE_LONG goto global_var_needs_cast
		return expr
		:global_var_needs_cast
			; we need to sign extend 8/16/32-bit signed global variables to 64 bits
			generate_cast_top_of_stack(statement, TYPE_UNSIGNED_LONG, type)
			return expr
		:global_var_large
			; @TODO: test this
			c = round_up_to_8(c)
			emit_sub_rsp_imm32(c)          ; sub rsp, (size)
			emit_mov_reg(REG_RDI, REG_RSP) ; mov rdi, rsp
			emit_mov_rax_imm64(d)          ; mov rax, (address)
			emit_mov_reg(REG_RSI, REG_RAX) ; mov rsi, rax
			emit_mov_rax_imm64(c)          ; mov rax, (size)
			emit_mov_reg(REG_RCX, REG_RAX) ; mov rcx, rax
			emit_rep_movsb()               ; rep movsb
			return expr
		:global_var_array
			; just push the address of the array
			emit_mov_rax_imm64(d) ; mov rax, (address)
			emit_push_rax()       ; push rax
			return expr
	:generate_dereference
		expr += 8
		expr = generate_push_expression(statement, expr)
		generate_stack_dereference(statement, type)
		return expr
	:generate_subscript
		expr += 8
		c = expr + 4 ; type 1
		c = *4c
		expr = generate_push_expression(statement, expr)
		d = expr + 4 ; type 2
		d = *4d
		expr = generate_push_expression(statement, expr)
		generate_stack_add(statement, c, d, c)
		generate_stack_dereference(statement, type)
		return expr
	:generate_dot_or_arrow
		; @NONSTANDARD: we require that the 1st operand to . be an lvalue
		;   e.g.   int thing = function_which_returns_struct().x;
		; is not allowed
		expr = generate_push_address_of_expression(statement, expr)
		generate_stack_dereference(statement, type)
		return expr
	:generate_local_variable
		expr += 8
		d = sign_extend_32_to_64(*4expr) ; rbp offset
		expr += 4
		b = *4expr ; is array?
		expr += 4
		if b != 0 goto local_var_array
		c = type_sizeof(type)
		if c > 8 goto local_var_large
		emit_mov_rax_qword_rbp_plus_imm32(d) ; mov rax, [rbp+X]
		emit_push_rax()                      ; push rax
		p = types + type
		if *1p < TYPE_LONG goto local_var_needs_cast
		return expr
		:local_var_needs_cast
			generate_cast_top_of_stack(statement, TYPE_UNSIGNED_LONG, type)
			return expr
		:local_var_large
			; @TODO: test this
			c = round_up_to_8(c)
			emit_sub_rsp_imm32(c)          ; sub rsp, (size)
			emit_mov_reg(REG_RDI, REG_RSP) ; mov rdi, rsp
			emit_lea_rax_rbp_plus_imm32(d) ; lea rax, [rbp+X]
			emit_mov_reg(REG_RSI, REG_RAX) ; mov rsi, rax
			emit_mov_rax_imm64(c)          ; mov rax, (size)
			emit_mov_reg(REG_RCX, REG_RAX) ; mov rcx, rax
			emit_rep_movsb()               ; rep movsb
			return expr
		:local_var_array
			; push address of array instead of array
			emit_lea_rax_rbp_plus_imm32(d) ; lea rax, [rbp+X]
			emit_push_rax()                ; push rax
			return expr
	:generate_float
		expr += 8
		emit_mov_rax_imm64(*8expr)
		emit_push_rax()
		generate_cast_top_of_stack(statement, TYPE_DOUBLE, type)
		expr += 8
		return expr
	:generate_int
		expr += 8
		emit_mov_rax_imm64(*8expr)
		emit_push_rax()
		expr += 8
		return expr
	:generate_comma
		expr += 8
		c = expr + 4 ; type of 1st expression
		c = *4c
		expr = generate_push_expression(statement, expr)
		c = type_sizeof(c)
		c = round_up_to_8(c)
		emit_add_rsp_imm32(c) ; add rsp, (size of expression value on stack)
		expr = generate_push_expression(statement, expr)
		return expr
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
	if c == STATEMENT_LOCAL_DECLARATION goto gen_local_decl
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
		generate_push_expression_casted(statement, dat1, curr_function_return_type)
		; copy sizeof(return expression) rounded up to 8 bytes from [rsp] to [rbp+16]
		emit_mov_reg(REG_RSI, REG_RSP)
		emit_lea_rax_rbp_plus_imm32(16)
		emit_mov_reg(REG_RDI, REG_RAX)
		generate_copy_rsi_to_rdi_qwords(curr_function_return_type)
		
		:gen_return_noexpr
		generate_return()
		return
	:gen_local_decl
		c = type_sizeof(dat2)
		c = round_up_to_8(c)
		if dat3 != 0 goto gen_local_decl_initializer
		; move the stack pointer to the start of the variable
		dat1 += c
		dat1 = 0 - dat1
		emit_lea_rsp_rbp_plus_imm32(dat1)
		if dat4 != 0 goto gen_local_decl_data_initializer
		return
		
		:gen_local_decl_initializer
			dat1 = 0 - dat1
			; move the stack pointer to the end of the variable
			emit_lea_rsp_rbp_plus_imm32(dat1)
			; push the expression
			generate_push_expression_casted(statement, dat3, dat2)
			return
		:gen_local_decl_data_initializer
			emit_mov_rax_imm64(dat4)       ; mov rax, (data address)
			emit_mov_reg(REG_RSI, REG_RAX) ; mov rsi, rax
			emit_mov_reg(REG_RDI, REG_RSP) ; mov rdi, rsp
			emit_mov_rax_imm64(c)          ; mov rax, (size)
			emit_mov_reg(REG_RCX, REG_RAX) ; mov rcx, rax
			emit_rep_movsb()               ; rep movsb
			return
			
		
function generate_function
	argument function_name
	argument function_statement
	local function_type
	local out0
	
	function_type = ident_list_lookup(function_types, function_name)
	
	curr_function_return_type = functype_return_type(function_type)
	
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
		puts(.str_function_addr_mismatch)
		puts(function_name)
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
	emit_mov_rax_qword_rsp()
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
