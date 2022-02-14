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

global break_refs ; 0-terminated array of pointers to be filled in with the break offset
global continue_refs

; address of previous "case" label
global prev_case_addr


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
	
	if src ] 7 goto bad_reg
	if dest ] 7 goto bad_reg
	
	;48 89 (DEST|SRC<<3|0xc0)
	*2code_output = 0x8948
	code_output += 2
	n = 0xc0 | dest
	n |= src < 3
	*1code_output = n
	code_output += 1
	return
	:bad_reg
		die(.str_bad_reg)
	:str_bad_reg
		string Internal compiler error: bad register passed to emit_mov_reg.
		byte 0

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

function emit_add_rax_imm32
	; 48 05 IMM32
	argument imm32
	*2code_output = 0x0548
	code_output += 2
	*4code_output = imm32
	code_output += 4
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

function emit_mulsd_xmm0_xmm1
	*4code_output = 0xc1590ff2
	code_output += 4
	return

function emit_divsd_xmm0_xmm1
	*4code_output = 0xc15e0ff2
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

function emit_and_rax_rbx
	; 48 21 d8
	*2code_output = 0x2148
	code_output += 2
	*1code_output = 0xd8
	code_output += 1
	return

function emit_or_rax_rbx
	; 48 09 d8
	*2code_output = 0x0948
	code_output += 2
	*1code_output = 0xd8
	code_output += 1
	return

function emit_xor_rax_rbx
	; 48 31 d8
	*2code_output = 0x3148
	code_output += 2
	*1code_output = 0xd8
	code_output += 1
	return

function emit_shl_rax_cl
	; 48 d3 e0
	*2code_output = 0xd348
	code_output += 2
	*1code_output = 0xe0
	code_output += 1
	return

function emit_shr_rax_cl
	; 48 d3 e8
	*2code_output = 0xd348
	code_output += 2
	*1code_output = 0xe8
	code_output += 1
	return

function emit_sar_rax_cl
	; 48 d3 f8
	*2code_output = 0xd348
	code_output += 2
	*1code_output = 0xf8
	code_output += 1
	return

function emit_cqo
	; 48 99
	*2code_output = 0x9948
	code_output += 2
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

function emit_cmp_rax_rbx
	; 48 39 d8
	*2code_output = 0x3948
	code_output += 2
	*1code_output = 0xd8
	code_output += 1
	return

function emit_comisd_xmm0_xmm1
	; 66 0f 2f c1
	*4code_output = 0xc12f0f66
	code_output += 4
	return

#define COMPARISON_E 0x4
#define COMPARISON_NE 0x5
#define COMPARISON_L 0xc
#define COMPARISON_G 0xf
#define COMPARISON_LE 0xe
#define COMPARISON_GE 0xd
#define COMPARISON_B 0x2
#define COMPARISON_A 0x7
#define COMPARISON_BE 0x6
#define COMPARISON_AE 0x3

; emits two instructions:
;    setC al
;    movzx rax, al
function emit_setC_rax
	; 0f 9C c0 48 0f b6 c0
	argument comparison
	local a
	a = 0xc0b60f48c0900f
	a |= comparison < 8
	*8code_output = a
	code_output += 7
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
	
	if *1to == TYPE_VOID goto gen_cast_to_void
	if *1from == TYPE_VOID goto bad_gen_cast ; cast from void to something - that's bad
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
	
	:gen_cast_to_void
		; we need to handle rsp properly for stuff like:
		;  SomeLargeStruct s;
		;  (void)s;
		c = type_sizeof(from_type)
		c = round_up_to_8(c)
		c -= 8
		if c == 0 goto return_0 ; int to void cast or something; we don't care
		emit_add_rsp_imm32(c)
		return
	:gen_cast_to_integer
		if *1from == TYPE_ARRAY goto return_0 ;  e.g. (void *)"hello"
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
	local p
	
	p = types + out_type
	if *1p == TYPE_FLOAT goto generate_add_floats
	if *1p == TYPE_DOUBLE goto generate_add_doubles
	
	emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp]   (second operand)
	scale_rax_for_addition_with(type1) ; in case this is a pointer addition
	emit_mov_reg(REG_RSI, REG_RAX)       ; mov rsi, rax
	emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8]  (first operand)
	scale_rax_for_addition_with(type2) ; in case this is a pointer addition
	emit_mov_reg(REG_RBX, REG_RSI)       ; mov rbx, rsi
	emit_add_rax_rbx()                   ; add rax, rbx
	emit_add_rsp_imm32(8)                ; add rsp, 8
	emit_mov_qword_rsp_rax()             ; mov [rsp], rax
	generate_cast_top_of_stack(statement, TYPE_UNSIGNED_LONG, out_type)
	return
	
	:generate_add_floats
		emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp] (second operand)
		emit_movq_xmm0_rax()                 ; movq xmm0, rax
		emit_cvtss2sd_xmm0_xmm0()            ; cvtss2sd xmm0, xmm0
		emit_movq_xmm1_xmm0()                ; movq xmm1, xmm0
		emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8] (first operand)
		emit_movq_xmm0_rax()                 ; movq xmm0, rax
		emit_cvtss2sd_xmm0_xmm0()            ; cvtss2sd xmm0, xmm0
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
	generate_cast_top_of_stack(statement, TYPE_UNSIGNED_LONG, out_type)
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
		emit_cvtss2sd_xmm0_xmm0()            ; cvtss2sd xmm0, xmm0
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

; pop the top two things off of the stack, and push their product
function generate_stack_mul
	argument statement ; for errors
	argument type
	local p
	p = types + type
	if *1p == TYPE_FLOAT goto generate_mul_floats
	if *1p == TYPE_DOUBLE goto generate_mul_doubles

	emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp]   (second operand)
	emit_mov_reg(REG_RBX, REG_RAX)       ; mov rbx, rax
	emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8]  (first operand)
	emit_mul_rbx()                       ; mul rbx
	emit_add_rsp_imm32(8)                ; add rsp, 8
	emit_mov_qword_rsp_rax()             ; mov [rsp], rax
	generate_cast_top_of_stack(statement, TYPE_UNSIGNED_LONG, type)
	return
	
	:generate_mul_floats
		emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp] (second operand)
		emit_movq_xmm0_rax()                 ; movq xmm0, rax
		emit_cvtss2sd_xmm0_xmm0()            ; cvtss2sd xmm0, xmm0
		emit_movq_xmm1_xmm0()                ; movq xmm1, xmm0
		emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8] (first operand)
		emit_movq_xmm0_rax()                 ; movq xmm0, rax
		emit_cvtss2sd_xmm0_xmm0()            ; cvtss2sd xmm0, xmm0
		emit_mulsd_xmm0_xmm1()               ; mulsd xmm0, xmm1
		emit_cvtsd2ss_xmm0_xmm0()            ; cvtsd2ss xmm0, xmm0
		emit_movq_rax_xmm0()                 ; movq rax, xmm0
		emit_add_rsp_imm32(8)                ; add rsp, 8
		emit_mov_qword_rsp_rax()             ; mov [rsp], rax
		return
	
	:generate_mul_doubles
		emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp] (second operand)
		emit_movq_xmm1_rax()                 ; movq xmm1, rax
		emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8] (first operand)
		emit_movq_xmm0_rax()                 ; movq xmm0, rax
		emit_mulsd_xmm0_xmm1()               ; mulsd xmm0, xmm1
		emit_movq_rax_xmm0()                 ; movq rax, xmm0
		emit_add_rsp_imm32(8)                ; add rsp, 8
		emit_mov_qword_rsp_rax()             ; mov [rsp], rax			
		return

; pop the top two things off of the stack, and push their quotient
function generate_stack_div
	argument statement ; for errors
	argument type
	local p
	local c
	p = types + type
	if *1p == TYPE_FLOAT goto generate_div_floats
	if *1p == TYPE_DOUBLE goto generate_div_doubles

	emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp]   (second operand)
	emit_mov_reg(REG_RBX, REG_RAX)       ; mov rbx, rax
	emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8]  (first operand)
	c = *1p & 1
	if c == 1 goto generate_div_signed
		emit_zero_rdx()              ; xor edx, edx
		emit_div_rbx()               ; div rbx
		goto generate_div_cont
	:generate_div_signed
		emit_cqo()                   ; cqo
		emit_idiv_rbx()              ; idiv rbx
	:generate_div_cont
	emit_add_rsp_imm32(8)                ; add rsp, 8
	emit_mov_qword_rsp_rax()             ; mov [rsp], rax
	generate_cast_top_of_stack(statement, TYPE_UNSIGNED_LONG, type)
	return
	
	:generate_div_floats
		emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp] (second operand)
		emit_movq_xmm0_rax()                 ; movq xmm0, rax
		emit_cvtss2sd_xmm0_xmm0()            ; cvtss2sd xmm0, xmm0
		emit_movq_xmm1_xmm0()                ; movq xmm1, xmm0
		emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8] (first operand)
		emit_movq_xmm0_rax()                 ; movq xmm0, rax
		emit_cvtss2sd_xmm0_xmm0()            ; cvtss2sd xmm0, xmm0
		emit_divsd_xmm0_xmm1()               ; divsd xmm0, xmm1
		emit_cvtsd2ss_xmm0_xmm0()            ; cvtsd2ss xmm0, xmm0
		emit_movq_rax_xmm0()                 ; movq rax, xmm0
		emit_add_rsp_imm32(8)                ; add rsp, 8
		emit_mov_qword_rsp_rax()             ; mov [rsp], rax
		return
	
	:generate_div_doubles
		emit_mov_rax_qword_rsp_plus_imm32(0) ; mov rax, [rsp] (second operand)
		emit_movq_xmm1_rax()                 ; movq xmm1, rax
		emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8] (first operand)
		emit_movq_xmm0_rax()                 ; movq xmm0, rax
		emit_divsd_xmm0_xmm1()               ; divsd xmm0, xmm1
		emit_movq_rax_xmm0()                 ; movq rax, xmm0
		emit_add_rsp_imm32(8)                ; add rsp, 8
		emit_mov_qword_rsp_rax()             ; mov [rsp], rax			
		return

; pop the top two things off of the stack, and push their remainder
function generate_stack_remainder
	argument statement ; for errors
	argument type
	local p
	local c
	p = types + type
	emit_mov_rax_qword_rsp_plus_imm32(0)   ; mov rax, [rsp]   (second operand)
	emit_mov_reg(REG_RBX, REG_RAX)         ; mov rbx, rax
	emit_mov_rax_qword_rsp_plus_imm32(8)   ; mov rax, [rsp+8]  (first operand)
	c = *1p & 1
	if c == 1 goto generate_remainder_signed
		emit_zero_rdx()                ; xor edx, edx
		emit_div_rbx()                 ; div rbx
		emit_mov_reg(REG_RAX, REG_RDX) ; mov rax, rdx
		goto generate_remainder_cont
	:generate_remainder_signed
		emit_cqo()                     ; cqo
		emit_idiv_rbx()                ; idiv rbx
		emit_mov_reg(REG_RAX, REG_RDX) ; mov rax, rdx
	:generate_remainder_cont
	emit_add_rsp_imm32(8)                  ; add rsp, 8
	emit_mov_qword_rsp_rax()               ; mov [rsp], rax
	generate_cast_top_of_stack(statement, TYPE_UNSIGNED_LONG, type)
	return
	
; pop the top two things off of the stack, and push their bitwise and
function generate_stack_bitwise_and
	argument statement ; for errors
	argument type
	emit_mov_rax_qword_rsp_plus_imm32(0)   ; mov rax, [rsp]   (second operand)
	emit_mov_reg(REG_RBX, REG_RAX)         ; mov rbx, rax
	emit_mov_rax_qword_rsp_plus_imm32(8)   ; mov rax, [rsp+8]  (first operand)
	emit_and_rax_rbx()                     ; and rax, rbx
	emit_add_rsp_imm32(8)                  ; add rsp, 8
	emit_mov_qword_rsp_rax()               ; mov [rsp], rax
	generate_cast_top_of_stack(statement, TYPE_UNSIGNED_LONG, type)
	return

; pop the top two things off of the stack, and push their bitwise or
function generate_stack_bitwise_or
	argument statement ; for errors
	argument type
	emit_mov_rax_qword_rsp_plus_imm32(0)   ; mov rax, [rsp]   (second operand)
	emit_mov_reg(REG_RBX, REG_RAX)         ; mov rbx, rax
	emit_mov_rax_qword_rsp_plus_imm32(8)   ; mov rax, [rsp+8]  (first operand)
	emit_or_rax_rbx()                     ; or rax, rbx
	emit_add_rsp_imm32(8)                  ; add rsp, 8
	emit_mov_qword_rsp_rax()               ; mov [rsp], rax
	generate_cast_top_of_stack(statement, TYPE_UNSIGNED_LONG, type)
	return

; pop the top two things off of the stack, and push their bitwise xor
function generate_stack_bitwise_xor
	argument statement ; for errors
	argument type
	emit_mov_rax_qword_rsp_plus_imm32(0)   ; mov rax, [rsp]   (second operand)
	emit_mov_reg(REG_RBX, REG_RAX)         ; mov rbx, rax
	emit_mov_rax_qword_rsp_plus_imm32(8)   ; mov rax, [rsp+8]  (first operand)
	emit_xor_rax_rbx()                     ; xor rax, rbx
	emit_add_rsp_imm32(8)                  ; add rsp, 8
	emit_mov_qword_rsp_rax()               ; mov [rsp], rax
	generate_cast_top_of_stack(statement, TYPE_UNSIGNED_LONG, type)
	return


function generate_stack_lshift
	argument statement ; for errors
	argument type
	emit_mov_rax_qword_rsp_plus_imm32(0)   ; mov rax, [rsp]   (second operand)
	emit_mov_reg(REG_RCX, REG_RAX)         ; mov rcx, rax
	emit_mov_rax_qword_rsp_plus_imm32(8)   ; mov rax, [rsp+8]  (first operand)
	emit_shl_rax_cl()                      ; shl rax, cl
	emit_add_rsp_imm32(8)                  ; add rsp, 8
	emit_mov_qword_rsp_rax()               ; mov [rsp], rax
	generate_cast_top_of_stack(statement, TYPE_UNSIGNED_LONG, type)
	return


function generate_stack_rshift
	argument statement ; for errors
	argument type
	local p
	local c
	p = types + type
	c = *1p & 1
	
	emit_mov_rax_qword_rsp_plus_imm32(0)   ; mov rax, [rsp]   (second operand)
	emit_mov_reg(REG_RCX, REG_RAX)         ; mov rcx, rax
	emit_mov_rax_qword_rsp_plus_imm32(8)   ; mov rax, [rsp+8]  (first operand)
	if c == 1 goto gen_rshift_signed
		emit_shr_rax_cl()              ; shr rax, cl
		goto gen_rshift_cont
	:gen_rshift_signed
		emit_sar_rax_cl()              ; sar rax, cl
	:gen_rshift_cont
	emit_add_rsp_imm32(8)                  ; add rsp, 8
	emit_mov_qword_rsp_rax()               ; mov [rsp], rax
	generate_cast_top_of_stack(statement, TYPE_UNSIGNED_LONG, type)
	return

; pop a pointer off of the stack, then push the dereferenced value according to `type`
function generate_stack_dereference
	argument statement ; for errors
	argument type
	local p
	local size
	local c
	
	size = type_sizeof(type)
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
		emit_mov_rax_qword_rsp()       ; mov rax, [rsp]
		emit_mov_reg(REG_RBX, REG_RAX) ; mov rbx, rax
		emit_mov_al_byte_rbx()         ; mov al, [rbx]
		goto gen_deref_cast
	:gen_deref2
		emit_mov_rax_qword_rsp()       ; mov rax, [rsp]
		emit_mov_reg(REG_RBX, REG_RAX) ; mov rbx, rax
		emit_mov_ax_word_rbx()         ; mov ax, [rbx]
		goto gen_deref_cast
	:gen_deref4
		emit_mov_rax_qword_rsp()       ; mov rax, [rsp]
		emit_mov_reg(REG_RBX, REG_RAX) ; mov rbx, rax
		emit_mov_eax_dword_rbx()       ; mov eax, [rbx]
		goto gen_deref_cast
	:gen_deref8
		emit_mov_rax_qword_rsp()       ; mov rax, [rsp]
		emit_mov_reg(REG_RBX, REG_RAX) ; mov rbx, rax
		emit_mov_rax_qword_rbx()       ; mov rax, [rbx]
		goto gen_deref_cast

; pop address off of stack, pop value, set *address to value, then push value
function generate_stack_assign
	argument statement
	argument type
	local size
	size = type_sizeof(type)
	
	
	
	if size == 1 goto gen_assign1
	if size == 2 goto gen_assign2
	if size == 4 goto gen_assign4
	if size == 8 goto gen_assign8
	
	emit_mov_rax_qword_rsp()       ; mov rax, [rsp]
	emit_mov_reg(REG_RDI, REG_RAX) ; mov rdi, rax
	emit_add_rsp_imm32(8)          ; add rsp, 8
	emit_mov_reg(REG_RSI, REG_RSP) ; mov rsi, rsp
	emit_mov_rax_imm64(size)       ; mov rax, (size)
	emit_mov_reg(REG_RCX, REG_RAX) ; mov rcx, rax
	emit_rep_movsb()               ; rep movsb
	return
	
	:gen_assign_ret
		emit_add_rsp_imm32(8) ; pop address
		return
	:gen_assign1
		emit_mov_rax_qword_rsp()             ; mov rax, [rsp]
		emit_mov_reg(REG_RBX, REG_RAX)       ; mov rbx, rax
		emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8]
		emit_mov_byte_rbx_al()               ; mov [rbx], al
		goto gen_assign_ret
	:gen_assign2
		emit_mov_rax_qword_rsp()             ; mov rax, [rsp]
		emit_mov_reg(REG_RBX, REG_RAX)       ; mov rbx, rax
		emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8]
		emit_mov_word_rbx_ax()               ; mov [rbx], ax
		goto gen_assign_ret
	:gen_assign4
		emit_mov_rax_qword_rsp()             ; mov rax, [rsp]
		emit_mov_reg(REG_RBX, REG_RAX)       ; mov rbx, rax
		emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8]
		emit_mov_dword_rbx_eax()             ; mov [rbx], eax
		goto gen_assign_ret
	:gen_assign8
		emit_mov_rax_qword_rsp()             ; mov rax, [rsp]
		emit_mov_reg(REG_RBX, REG_RAX)       ; mov rbx, rax
		emit_mov_rax_qword_rsp_plus_imm32(8) ; mov rax, [rsp+8]
		emit_mov_qword_rbx_rax()             ; mov [rbx], rax
		goto gen_assign_ret

; pop from the stack and compare with 0 (setting eflags appropriately)
function generate_stack_compare_against_zero
	argument statement
	argument type
	local p
	p = types + type
	if *1p == TYPE_FLOAT goto cmp_zero_float
	if *1p == TYPE_DOUBLE goto cmp_zero_double
	emit_add_rsp_imm32(8)                 ; add rsp, 8
	emit_mov_rax_qword_rsp_plus_imm32(-8) ; mov rax, [rsp-8]
	emit_test_rax_rax()                   ; test rax, rax
	return
	:cmp_zero_float
		generate_cast_top_of_stack(statement, TYPE_FLOAT, TYPE_DOUBLE) ; cast to double for comparison
	:cmp_zero_double	
		emit_add_rsp_imm32(8)                  ; add rsp, 8
		emit_zero_rax()                        ; xor eax, eax
		emit_movq_xmm1_rax()                   ; movq xmm1, rax
		emit_mov_rax_qword_rsp_plus_imm32(-8)  ; mov rax, [rsp-8]
		emit_movq_xmm0_rax()                   ; movq xmm0, rax
		emit_comisd_xmm0_xmm1()                ; comisd xmm0, xmm1
		return

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
		emit_mov_rax_imm64(*4expr)     ; mov rax, (offset to member)
		emit_add_rax_rbx()             ; add rax, rbx
		emit_mov_qword_rsp_rax()       ; mov [rsp], rax
		expr += 8
		return expr

; pop the top two things off the stack of type `type` and compare them
function generate_stack_compare
	argument statement
	argument type
	local p
	p = types + type
	
	emit_add_rsp_imm32(16)                 ; add rsp, 16
	
	; NB: we do float comparisons as double comparisons (see function comparison_type)
	if *1p == TYPE_DOUBLE goto stack_compare_double
	if *1p > TYPE_UNSIGNED_LONG goto stack_compare_bad
	
	emit_mov_rax_qword_rsp_plus_imm32(-16) ; mov rax, [rsp-16] (second operand)
	emit_mov_reg(REG_RBX, REG_RAX)         ; mov rbx, rax
	emit_mov_rax_qword_rsp_plus_imm32(-8)  ; mov rax, [rsp-8] (first operand)
	emit_cmp_rax_rbx()                     ; cmp rax, rbx
	return
	
	:stack_compare_bad
		die(.str_stack_compare_bad)
		:str_stack_compare_bad
			string Bad types passed to generate_stack_compare()
			byte 0
	:stack_compare_double
		emit_mov_rax_qword_rsp_plus_imm32(-8)  ; mov rax, [rsp-8] (first operand)
		emit_movq_xmm0_rax()                   ; movq xmm0, rax
		emit_mov_rax_qword_rsp_plus_imm32(-16) ; mov rax, [rsp-16] (second operand)
		emit_movq_xmm1_rax()                   ; movq xmm1, rax
		emit_comisd_xmm0_xmm1()                ; comisd xmm0, xmm1
		return
	
; given that expr is a comparison expression, which type should both operands be converted to?
function comparison_type
	argument statement
	argument expr
	local type1
	local type2
	expr += 8
	
	type1 = expr + 4
	type1 = *4type1
	expr = expression_get_end(expr)
	type2 = expr + 4
	type2 = *4type2
	
	type1 += types
	type1 = *1type1
	type2 += types
	type2 = *1type2
	
	; do float comparisons as double comparisons to make things simpler
	if type1 == TYPE_FLOAT goto return_type_double
	if type2 == TYPE_FLOAT goto return_type_double
	
	if type1 == TYPE_POINTER goto return_type_unsigned_long
	if type2 == TYPE_POINTER goto return_type_unsigned_long
	return expr_binary_type_usual_conversions(statement, type1, type2)

; is this comparison expression a comparison between unsigned integers or floats?
function comparison_is_unsigned
	argument statement
	argument expr
	local type
	type = comparison_type(statement, expr)
	type += types
	type = *1type
	if type > TYPE_UNSIGNED_LONG goto return_1 ; double comparisons use setb/seta not setl/setg
	type &= 1
	if type == 0 goto return_1
	return 0
	
; `statement` is used for errors
; returns pointer to end of expression
function generate_push_expression
	argument statement
	argument expr
	local b
	local c
	local d
	local p
	local comparison
	local addr1
	local addr2
	local type
	
	type = expr + 4
	type = *4type
	
	c = *1expr
	
	if c == EXPRESSION_CONSTANT_INT goto generate_int
	if c == EXPRESSION_CONSTANT_FLOAT goto generate_float
	if c == EXPRESSION_GLOBAL_VARIABLE goto generate_global_variable
	if c == EXPRESSION_LOCAL_VARIABLE goto generate_local_variable
	if c == EXPRESSION_FUNCTION goto generate_function_addr
	if c == EXPRESSION_CAST goto generate_cast
	if c == EXPRESSION_UNARY_PLUS goto generate_cast ; the unary plus operator just casts to the promoted type
	if c == EXPRESSION_UNARY_MINUS goto generate_unary_minus
	if c == EXPRESSION_BITWISE_NOT goto generate_unary_bitwise_not
	if c == EXPRESSION_LOGICAL_NOT goto generate_unary_logical_not
	if c == EXPRESSION_ADD goto generate_add
	if c == EXPRESSION_SUB goto generate_sub
	if c == EXPRESSION_MUL goto generate_mul
	if c == EXPRESSION_DIV goto generate_div
	if c == EXPRESSION_REMAINDER goto generate_remainder
	if c == EXPRESSION_BITWISE_AND goto generate_bitwise_and
	if c == EXPRESSION_BITWISE_OR goto generate_bitwise_or
	if c == EXPRESSION_BITWISE_XOR goto generate_bitwise_xor
	if c == EXPRESSION_LSHIFT goto generate_lshift
	if c == EXPRESSION_RSHIFT goto generate_rshift
	if c == EXPRESSION_EQ goto generate_eq
	if c == EXPRESSION_NEQ goto generate_neq
	if c == EXPRESSION_LT goto generate_lt
	if c == EXPRESSION_GT goto generate_gt
	if c == EXPRESSION_LEQ goto generate_leq
	if c == EXPRESSION_GEQ goto generate_geq
	if c == EXPRESSION_ASSIGN goto generate_assign
	if c == EXPRESSION_ASSIGN_ADD goto generate_assign_add
	if c == EXPRESSION_ASSIGN_SUB goto generate_assign_sub
	if c == EXPRESSION_ASSIGN_MUL goto generate_assign_mul
	if c == EXPRESSION_ASSIGN_DIV goto generate_assign_div
	if c == EXPRESSION_ASSIGN_REMAINDER goto generate_assign_remainder
	if c == EXPRESSION_ASSIGN_LSHIFT goto generate_assign_lshift
	if c == EXPRESSION_ASSIGN_RSHIFT goto generate_assign_rshift
	if c == EXPRESSION_ASSIGN_AND goto generate_assign_and
	if c == EXPRESSION_ASSIGN_OR goto generate_assign_or
	if c == EXPRESSION_ASSIGN_XOR goto generate_assign_xor
	if c == EXPRESSION_POST_INCREMENT goto generate_post_increment
	if c == EXPRESSION_POST_DECREMENT goto generate_post_decrement
	if c == EXPRESSION_PRE_INCREMENT goto generate_pre_increment
	if c == EXPRESSION_PRE_DECREMENT goto generate_pre_decrement
	if c == EXPRESSION_DEREFERENCE goto generate_dereference
	if c == EXPRESSION_SUBSCRIPT goto generate_subscript
	if c == EXPRESSION_ADDRESS_OF goto generate_address_of
	if c == EXPRESSION_DOT goto generate_dot_or_arrow
	if c == EXPRESSION_ARROW goto generate_dot_or_arrow
	if c == EXPRESSION_COMMA goto generate_comma
	if c == EXPRESSION_CALL goto generate_call
	if c == EXPRESSION_LOGICAL_AND goto generate_logical_and
	if c == EXPRESSION_LOGICAL_OR goto generate_logical_or
	if c == EXPRESSION_CONDITIONAL goto generate_conditional
	
	putnln(c)	
	die(.str_genpushbadexpr)
	:str_genpushbadexpr
		string Internal compiler error: bad expression passed to generate_push_expression.
		byte 0
	:generate_cast
		expr += 8
		expr = generate_push_expression_casted(statement, expr, type)
		return expr
	:generate_function_addr
		d = 1 ; default to address of 1, not 0 because that will be optimized to xor eax, eax
		expr += 8
		if codegen_second_pass == 0 goto function_noaddr
		d = ident_list_lookup(functions_addresses, *8expr)
		if d == 0 goto no_such_function
		:function_noaddr
		expr += 8
		emit_mov_rax_imm64(d)
		emit_push_rax()
		return expr
		
		:no_such_function
			print_statement_location(statement)
			puts(.str_no_such_function)
			putsln(*8expr)
			exit(1)
			:str_no_such_function
				string : Error: No such function:
				byte 32
				byte 0
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
	:generate_assign
		expr += 8
		b = type_is_array(type)
		if b != 0 goto assign_array
		p = expression_get_end(expr)
		c = p
		; it makes things a lot easier if we push the rhs of the assignment first -- also
		;      *f() = g()
		;   it might be required to call g first? (something something sequence points)
		p = generate_push_expression_casted(statement, p, type)
		d = generate_push_address_of_expression(statement, expr)
		if c != d goto exprend_wrong
		expr = p
		generate_stack_assign(statement, type)
		return expr
		:assign_array
			statement_error(statement, .str_assign_array)
		:str_assign_array
			string Assigning to array.
			byte 0
	
	
	
		:exprend_wrong
			die(.str_exprend_wrong)
		:str_exprend_wrong
			string Internal compiler error: expression_get_end disagrees with generate_push_expression.
			byte 0
	:generate_assign_add
		expr += 8
		p = expression_get_end(expr)
		p = generate_push_expression_casted(statement, p, type)
		generate_push_address_of_expression(statement, expr)
		expr = p
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (address)
		emit_push_rax()                       ; push rax
		generate_stack_dereference(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(16) ; mov rax, [rsp+16] (addend)
		emit_push_rax()                       ; push rax
		generate_stack_add(statement, type, type, type)
		emit_mov_rax_qword_rsp_plus_imm32(8)  ; mov rax, [rsp+8] (address)
		emit_push_rax()                       ; push rax
		generate_stack_assign(statement, type)
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (result)
		emit_add_rsp_imm32(16)                ; add rsp, 16 (pop address, addend)
		emit_mov_qword_rsp_rax()              ; mov [rsp], rax
		return expr
	:generate_assign_sub
		expr += 8
		p = expression_get_end(expr)
		p = generate_push_expression_casted(statement, p, type)
		generate_push_address_of_expression(statement, expr)
		expr = p
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (address)
		emit_push_rax()                       ; push rax
		generate_stack_dereference(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(16) ; mov rax, [rsp+16] (2nd operand)
		emit_push_rax()                       ; push rax
		generate_stack_sub(statement, type, type, type)
		emit_mov_rax_qword_rsp_plus_imm32(8)  ; mov rax, [rsp+8] (address)
		emit_push_rax()                       ; push rax
		generate_stack_assign(statement, type)
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (result)
		emit_add_rsp_imm32(16)                ; add rsp, 16 (pop address, 2nd operand)
		emit_mov_qword_rsp_rax()              ; mov [rsp], rax
		return expr
	:generate_assign_mul
		expr += 8
		p = expression_get_end(expr)
		p = generate_push_expression_casted(statement, p, type)
		generate_push_address_of_expression(statement, expr)
		expr = p
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (address)
		emit_push_rax()                       ; push rax
		generate_stack_dereference(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(16) ; mov rax, [rsp+16] (2nd operand)
		emit_push_rax()                       ; push rax
		generate_stack_mul(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(8)  ; mov rax, [rsp+8] (address)
		emit_push_rax()                       ; push rax
		generate_stack_assign(statement, type)
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (result)
		emit_add_rsp_imm32(16)                ; add rsp, 16 (pop address, 2nd operand)
		emit_mov_qword_rsp_rax()              ; mov [rsp], rax
		return expr
	:generate_assign_div
		expr += 8
		p = expression_get_end(expr)
		p = generate_push_expression_casted(statement, p, type)
		generate_push_address_of_expression(statement, expr)
		expr = p
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (address)
		emit_push_rax()                       ; push rax
		generate_stack_dereference(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(16) ; mov rax, [rsp+16] (2nd operand)
		emit_push_rax()                       ; push rax
		generate_stack_div(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(8)  ; mov rax, [rsp+8] (address)
		emit_push_rax()                       ; push rax
		generate_stack_assign(statement, type)
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (result)
		emit_add_rsp_imm32(16)                ; add rsp, 16 (pop address, 2nd operand)
		emit_mov_qword_rsp_rax()              ; mov [rsp], rax
		return expr
	:generate_assign_remainder
		expr += 8
		p = expression_get_end(expr)
		p = generate_push_expression_casted(statement, p, type)
		generate_push_address_of_expression(statement, expr)
		expr = p
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (address)
		emit_push_rax()                       ; push rax
		generate_stack_dereference(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(16) ; mov rax, [rsp+16] (2nd operand)
		emit_push_rax()                       ; push rax
		generate_stack_remainder(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(8)  ; mov rax, [rsp+8] (address)
		emit_push_rax()                       ; push rax
		generate_stack_assign(statement, type)
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (result)
		emit_add_rsp_imm32(16)                ; add rsp, 16 (pop address, 2nd operand)
		emit_mov_qword_rsp_rax()              ; mov [rsp], rax
		return expr
	:generate_assign_and
		expr += 8
		p = expression_get_end(expr)
		p = generate_push_expression_casted(statement, p, type)
		generate_push_address_of_expression(statement, expr)
		expr = p
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (address)
		emit_push_rax()                       ; push rax
		generate_stack_dereference(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(16) ; mov rax, [rsp+16] (2nd operand)
		emit_push_rax()                       ; push rax
		generate_stack_bitwise_and(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(8)  ; mov rax, [rsp+8] (address)
		emit_push_rax()                       ; push rax
		generate_stack_assign(statement, type)
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (result)
		emit_add_rsp_imm32(16)                ; add rsp, 16 (pop address, 2nd operand)
		emit_mov_qword_rsp_rax()              ; mov [rsp], rax
		return expr
	:generate_assign_or
		expr += 8
		p = expression_get_end(expr)
		p = generate_push_expression_casted(statement, p, type)
		generate_push_address_of_expression(statement, expr)
		expr = p
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (address)
		emit_push_rax()                       ; push rax
		generate_stack_dereference(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(16) ; mov rax, [rsp+16] (2nd operand)
		emit_push_rax()                       ; push rax
		generate_stack_bitwise_or(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(8)  ; mov rax, [rsp+8] (address)
		emit_push_rax()                       ; push rax
		generate_stack_assign(statement, type)
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (result)
		emit_add_rsp_imm32(16)                ; add rsp, 16 (pop address, 2nd operand)
		emit_mov_qword_rsp_rax()              ; mov [rsp], rax
		return expr
	:generate_assign_xor
		expr += 8
		p = expression_get_end(expr)
		p = generate_push_expression_casted(statement, p, type)
		generate_push_address_of_expression(statement, expr)
		expr = p
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (address)
		emit_push_rax()                       ; push rax
		generate_stack_dereference(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(16) ; mov rax, [rsp+16] (2nd operand)
		emit_push_rax()                       ; push rax
		generate_stack_bitwise_xor(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(8)  ; mov rax, [rsp+8] (address)
		emit_push_rax()                       ; push rax
		generate_stack_assign(statement, type)
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (result)
		emit_add_rsp_imm32(16)                ; add rsp, 16 (pop address, 2nd operand)
		emit_mov_qword_rsp_rax()              ; mov [rsp], rax
		return expr
	:generate_assign_lshift
		expr += 8
		p = expression_get_end(expr)
		p = generate_push_expression_casted(statement, p, type)
		generate_push_address_of_expression(statement, expr)
		expr = p
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (address)
		emit_push_rax()                       ; push rax
		generate_stack_dereference(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(16) ; mov rax, [rsp+16] (2nd operand)
		emit_push_rax()                       ; push rax
		generate_stack_lshift(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(8)  ; mov rax, [rsp+8] (address)
		emit_push_rax()                       ; push rax
		generate_stack_assign(statement, type)
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (result)
		emit_add_rsp_imm32(16)                ; add rsp, 16 (pop address, 2nd operand)
		emit_mov_qword_rsp_rax()              ; mov [rsp], rax
		return expr
	:generate_assign_rshift
		expr += 8
		p = expression_get_end(expr)
		p = generate_push_expression_casted(statement, p, type)
		generate_push_address_of_expression(statement, expr)
		expr = p
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (address)
		emit_push_rax()                       ; push rax
		generate_stack_dereference(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(16) ; mov rax, [rsp+16] (2nd operand)
		emit_push_rax()                       ; push rax
		generate_stack_rshift(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(8)  ; mov rax, [rsp+8] (address)
		emit_push_rax()                       ; push rax
		generate_stack_assign(statement, type)
		emit_mov_rax_qword_rsp()              ; mov rax, [rsp] (result)
		emit_add_rsp_imm32(16)                ; add rsp, 16 (pop address, 2nd operand)
		emit_mov_qword_rsp_rax()              ; mov [rsp], rax
		return expr
	:generate_post_increment
		expr += 8
		expr = generate_push_address_of_expression(statement, expr)
		
		p = types + type
		if *1p == TYPE_FLOAT goto post_increment_float
		if *1p == TYPE_DOUBLE goto post_increment_double
		
		emit_mov_rax_qword_rsp()               ; mov rax, [rsp] (address)
		emit_push_rax()                        ; push rax
		generate_stack_dereference(statement, type)
		emit_mov_rax_imm64(1)                  ; mov rax, 1
		scale_rax_for_addition_with(type) ; in case this is a pointer increment
		emit_mov_reg(REG_RBX, REG_RAX)
		emit_mov_rax_qword_rsp()               ; mov rax, [rsp] (value)
		emit_add_rax_rbx()                     ; add rax, rbx
		emit_push_rax()                        ; push rax
		emit_mov_rax_qword_rsp_plus_imm32(16)  ; mov rax, [rsp+16] (address)
		emit_push_rax()
		generate_stack_assign(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(8)   ; mov rax, [rsp+8] (old value)
		emit_mov_qword_rsp_plus_imm32_rax(16)  ; mov [rsp+16], rax
		emit_add_rsp_imm32(16)                 ; add rsp, 16
		return expr
		
		:post_increment_float
			emit_mov_rax_qword_rsp()        ; mov rax, [rsp] (address)
			emit_mov_reg(REG_RBX, REG_RAX)  ; mov rbx, rax
			emit_mov_eax_dword_rbx()        ; mov eax, [rbx]
			emit_mov_reg(REG_RSI, REG_RAX)  ; mov rsi, rax (save old value)
			emit_movq_xmm0_rax()            ; movq xmm0, rax
			emit_cvtss2sd_xmm0_xmm0()       ; cvtss2sd xmm0, xmm0
			emit_mov_rax_imm64(0x3ff0000000000000) ; mov rax, 1.0
			emit_movq_xmm1_rax()            ; movq xmm1, rax
			emit_addsd_xmm0_xmm1()          ; addsd xmm0, xmm1
			emit_cvtsd2ss_xmm0_xmm0()       ; cvtsd2ss xmm0, xmm0
			emit_movq_rax_xmm0()            ; mov rax, xmm0
			emit_mov_dword_rbx_eax()        ; mov [rbx], eax
			emit_mov_reg(REG_RAX, REG_RSI)  ; mov rax, rsi (old value)
			emit_mov_qword_rsp_rax()        ; mov [rsp], rax
			return expr
		:post_increment_double
			emit_mov_rax_qword_rsp()        ; mov rax, [rsp] (address)
			emit_mov_reg(REG_RBX, REG_RAX)  ; mov rbx, rax
			emit_mov_rax_qword_rbx()        ; mov rax, [rbx]
			emit_mov_reg(REG_RSI, REG_RAX)  ; mov rsi, rax (save old value)
			emit_movq_xmm0_rax()            ; movq xmm0, rax
			emit_mov_rax_imm64(0x3ff0000000000000) ; mov rax, 1.0
			emit_movq_xmm1_rax()            ; movq xmm1, rax
			emit_addsd_xmm0_xmm1()          ; addsd xmm0, xmm1
			emit_movq_rax_xmm0()            ; mov rax, xmm0
			emit_mov_qword_rbx_rax()        ; mov [rbx], rax
			emit_mov_reg(REG_RAX, REG_RSI)  ; mov rax, rsi (old value)
			emit_mov_qword_rsp_rax()        ; mov [rsp], rax
			return expr
	:generate_post_decrement
		expr += 8
		expr = generate_push_address_of_expression(statement, expr)
		
		p = types + type
		if *1p == TYPE_FLOAT goto post_decrement_float
		if *1p == TYPE_DOUBLE goto post_decrement_double
		
		emit_mov_rax_qword_rsp()               ; mov rax, [rsp] (address)
		emit_push_rax()                        ; push rax
		generate_stack_dereference(statement, type)
		emit_mov_rax_imm64(1)                  ; mov rax, 1
		scale_rax_for_addition_with(type) ; in case this is a pointer decrement
		emit_mov_reg(REG_RBX, REG_RAX)
		emit_mov_rax_qword_rsp()               ; mov rax, [rsp] (value)
		emit_sub_rax_rbx()                     ; sub rax, rbx
		emit_push_rax()                        ; push rax
		emit_mov_rax_qword_rsp_plus_imm32(16)  ; mov rax, [rsp+16] (address)
		emit_push_rax()
		generate_stack_assign(statement, type)
		emit_mov_rax_qword_rsp_plus_imm32(8)   ; mov rax, [rsp+8] (old value)
		emit_mov_qword_rsp_plus_imm32_rax(16)  ; mov [rsp+16], rax
		emit_add_rsp_imm32(16)                 ; add rsp, 16
		return expr
		
		:post_decrement_float
			emit_mov_rax_qword_rsp()        ; mov rax, [rsp] (address)
			emit_mov_reg(REG_RBX, REG_RAX)  ; mov rbx, rax
			emit_mov_eax_dword_rbx()        ; mov eax, [rbx]
			emit_mov_reg(REG_RSI, REG_RAX)  ; mov rsi, rax (save old value)
			emit_movq_xmm0_rax()            ; movq xmm0, rax
			emit_cvtss2sd_xmm0_xmm0()       ; cvtss2sd xmm0, xmm0
			emit_mov_rax_imm64(0x3ff0000000000000) ; mov rax, 1.0
			emit_movq_xmm1_rax()            ; movq xmm1, rax
			emit_subsd_xmm0_xmm1()          ; subsd xmm0, xmm1
			emit_cvtsd2ss_xmm0_xmm0()       ; cvtsd2ss xmm0, xmm0
			emit_movq_rax_xmm0()            ; mov rax, xmm0
			emit_mov_dword_rbx_eax()        ; mov [rbx], eax
			emit_mov_reg(REG_RAX, REG_RSI)  ; mov rax, rsi (old value)
			emit_mov_qword_rsp_rax()        ; mov [rsp], rax
			return expr
		:post_decrement_double
			emit_mov_rax_qword_rsp()        ; mov rax, [rsp] (address)
			emit_mov_reg(REG_RBX, REG_RAX)  ; mov rbx, rax
			emit_mov_rax_qword_rbx()        ; mov rax, [rbx]
			emit_mov_reg(REG_RSI, REG_RAX)  ; mov rsi, rax (save old value)
			emit_movq_xmm0_rax()            ; movq xmm0, rax
			emit_mov_rax_imm64(0x3ff0000000000000) ; mov rax, 1.0
			emit_movq_xmm1_rax()            ; movq xmm1, rax
			emit_subsd_xmm0_xmm1()          ; subsd xmm0, xmm1
			emit_movq_rax_xmm0()            ; mov rax, xmm0
			emit_mov_qword_rbx_rax()        ; mov [rbx], rax
			emit_mov_reg(REG_RAX, REG_RSI)  ; mov rax, rsi (old value)
			emit_mov_qword_rsp_rax()        ; mov [rsp], rax
			return expr
	:generate_pre_increment
		expr += 8
		expr = generate_push_address_of_expression(statement, expr)
		
		p = types + type
		if *1p == TYPE_FLOAT goto pre_increment_float
		if *1p == TYPE_DOUBLE goto pre_increment_double
		
		emit_mov_rax_qword_rsp()               ; mov rax, [rsp] (address)
		emit_push_rax()                        ; push rax
		generate_stack_dereference(statement, type)
		emit_mov_rax_imm64(1)                  ; mov rax, 1
		scale_rax_for_addition_with(type) ; in case this is a pointer increment
		emit_mov_reg(REG_RBX, REG_RAX)
		emit_mov_rax_qword_rsp()               ; mov rax, [rsp] (value)
		emit_add_rax_rbx()                     ; add rax, rbx
		emit_push_rax()                        ; push rax
		emit_mov_rax_qword_rsp_plus_imm32(16)  ; mov rax, [rsp+16] (address)
		emit_push_rax()
		generate_stack_assign(statement, type)
		emit_mov_rax_qword_rsp()               ; mov rax, [rsp] (value)
		emit_mov_qword_rsp_plus_imm32_rax(16)  ; mov [rsp+16], rax
		emit_add_rsp_imm32(16)                 ; add rsp, 16
		return expr
		
		:pre_increment_float
			emit_mov_rax_qword_rsp()        ; mov rax, [rsp] (address)
			emit_mov_reg(REG_RBX, REG_RAX)  ; mov rbx, rax
			emit_mov_eax_dword_rbx()        ; mov eax, [rbx]
			emit_movq_xmm0_rax()            ; movq xmm0, rax
			emit_cvtss2sd_xmm0_xmm0()       ; cvtss2sd xmm0, xmm0
			emit_mov_rax_imm64(0x3ff0000000000000) ; mov rax, 1.0
			emit_movq_xmm1_rax()            ; movq xmm1, rax
			emit_addsd_xmm0_xmm1()          ; addsd xmm0, xmm1
			emit_cvtsd2ss_xmm0_xmm0()       ; cvtsd2ss xmm0, xmm0
			emit_movq_rax_xmm0()            ; mov rax, xmm0
			emit_mov_dword_rbx_eax()        ; mov [rbx], eax
			emit_mov_qword_rsp_rax()        ; mov [rsp], rax
			return expr
		:pre_increment_double
			emit_mov_rax_qword_rsp()        ; mov rax, [rsp] (address)
			emit_mov_reg(REG_RBX, REG_RAX)  ; mov rbx, rax
			emit_mov_rax_qword_rbx()        ; mov rax, [rbx]
			emit_movq_xmm0_rax()            ; movq xmm0, rax
			emit_mov_rax_imm64(0x3ff0000000000000) ; mov rax, 1.0
			emit_movq_xmm1_rax()            ; movq xmm1, rax
			emit_addsd_xmm0_xmm1()          ; addsd xmm0, xmm1
			emit_movq_rax_xmm0()            ; mov rax, xmm0
			emit_mov_qword_rbx_rax()        ; mov [rbx], rax
			emit_mov_qword_rsp_rax()        ; mov [rsp], rax
			return expr
			
	:generate_pre_decrement
		expr += 8
		expr = generate_push_address_of_expression(statement, expr)
		
		p = types + type
		if *1p == TYPE_FLOAT goto pre_decrement_float
		if *1p == TYPE_DOUBLE goto pre_decrement_double
		
		emit_mov_rax_qword_rsp()               ; mov rax, [rsp] (address)
		emit_push_rax()                        ; push rax
		generate_stack_dereference(statement, type)
		emit_mov_rax_imm64(1)                  ; mov rax, 1
		scale_rax_for_addition_with(type) ; in case this is a pointer decrement
		emit_mov_reg(REG_RBX, REG_RAX)
		emit_mov_rax_qword_rsp()               ; mov rax, [rsp] (value)
		emit_sub_rax_rbx()                     ; sub rax, rbx
		emit_push_rax()                        ; push rax
		emit_mov_rax_qword_rsp_plus_imm32(16)  ; mov rax, [rsp+16] (address)
		emit_push_rax()
		generate_stack_assign(statement, type)
		emit_mov_rax_qword_rsp()               ; mov rax, [rsp] (value)
		emit_mov_qword_rsp_plus_imm32_rax(16)  ; mov [rsp+16], rax
		emit_add_rsp_imm32(16)                 ; add rsp, 16
		return expr
		
		:pre_decrement_float
			emit_mov_rax_qword_rsp()        ; mov rax, [rsp] (address)
			emit_mov_reg(REG_RBX, REG_RAX)  ; mov rbx, rax
			emit_mov_eax_dword_rbx()        ; mov eax, [rbx]
			emit_movq_xmm0_rax()            ; movq xmm0, rax
			emit_cvtss2sd_xmm0_xmm0()       ; cvtss2sd xmm0, xmm0
			emit_mov_rax_imm64(0x3ff0000000000000) ; mov rax, 1.0
			emit_movq_xmm1_rax()            ; movq xmm1, rax
			emit_subsd_xmm0_xmm1()          ; subsd xmm0, xmm1
			emit_cvtsd2ss_xmm0_xmm0()       ; cvtsd2ss xmm0, xmm0
			emit_movq_rax_xmm0()            ; mov rax, xmm0
			emit_mov_dword_rbx_eax()        ; mov [rbx], eax
			emit_mov_qword_rsp_rax()        ; mov [rsp], rax
			return expr
		:pre_decrement_double
			emit_mov_rax_qword_rsp()        ; mov rax, [rsp] (address)
			emit_mov_reg(REG_RBX, REG_RAX)  ; mov rbx, rax
			emit_mov_rax_qword_rbx()        ; mov rax, [rbx]
			emit_movq_xmm0_rax()            ; movq xmm0, rax
			emit_mov_rax_imm64(0x3ff0000000000000) ; mov rax, 1.0
			emit_movq_xmm1_rax()            ; movq xmm1, rax
			emit_subsd_xmm0_xmm1()          ; subsd xmm0, xmm1
			emit_movq_rax_xmm0()            ; mov rax, xmm0
			emit_mov_qword_rbx_rax()        ; mov [rbx], rax
			emit_mov_qword_rsp_rax()        ; mov [rsp], rax
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
	:generate_mul
		expr += 8
		expr = generate_push_expression_casted(statement, expr, type)
		expr = generate_push_expression_casted(statement, expr, type)
		generate_stack_mul(statement, type)
		return expr
	:generate_div
		expr += 8
		expr = generate_push_expression_casted(statement, expr, type)
		expr = generate_push_expression_casted(statement, expr, type)
		generate_stack_div(statement, type)
		return expr
	:generate_remainder
		expr += 8
		expr = generate_push_expression_casted(statement, expr, type)
		expr = generate_push_expression_casted(statement, expr, type)
		generate_stack_remainder(statement, type)
		return expr
	:generate_bitwise_and
		expr += 8
		expr = generate_push_expression_casted(statement, expr, type)
		expr = generate_push_expression_casted(statement, expr, type)
		generate_stack_bitwise_and(statement, type)
		return expr
	:generate_bitwise_or
		expr += 8
		expr = generate_push_expression_casted(statement, expr, type)
		expr = generate_push_expression_casted(statement, expr, type)
		generate_stack_bitwise_or(statement, type)
		return expr
	:generate_bitwise_xor
		expr += 8
		expr = generate_push_expression_casted(statement, expr, type)
		expr = generate_push_expression_casted(statement, expr, type)
		generate_stack_bitwise_xor(statement, type)
		return expr
	:generate_lshift
		expr += 8
		expr = generate_push_expression_casted(statement, expr, type)
		expr = generate_push_expression_casted(statement, expr, type)
		generate_stack_lshift(statement, type)
		return expr
	:generate_rshift
		expr += 8
		expr = generate_push_expression_casted(statement, expr, type)
		expr = generate_push_expression_casted(statement, expr, type)
		generate_stack_rshift(statement, type)
		return expr
	:generate_unary_logical_not
		expr += 8
		p = expr + 4
		expr = generate_push_expression(statement, expr)
		generate_stack_compare_against_zero(statement, *4p)
		emit_setC_rax(COMPARISON_E)   ; sete al ; movzx rax, al
		emit_push_rax()               ; push rax
		return expr
	:generate_eq
		comparison = COMPARISON_E
		goto generate_comparison
	:generate_neq
		comparison = COMPARISON_NE
		goto generate_comparison
	:generate_lt
		b = comparison_is_unsigned(statement, expr)
		if b != 0 goto comparison_b
			comparison = COMPARISON_L
			goto generate_comparison
		:comparison_b
			comparison = COMPARISON_B
			goto generate_comparison
	:generate_leq
		b = comparison_is_unsigned(statement, expr)
		if b != 0 goto comparison_be
			comparison = COMPARISON_LE
			goto generate_comparison
		:comparison_be
			comparison = COMPARISON_BE
			goto generate_comparison
	:generate_gt
		b = comparison_is_unsigned(statement, expr)
		if b != 0 goto comparison_a
			comparison = COMPARISON_G
			goto generate_comparison
		:comparison_a
			comparison = COMPARISON_A
			goto generate_comparison
	:generate_geq
		b = comparison_is_unsigned(statement, expr)
		if b != 0 goto comparison_ae
			comparison = COMPARISON_GE
			goto generate_comparison
		:comparison_ae
			comparison = COMPARISON_AE
			goto generate_comparison
	:generate_comparison
		c = comparison_type(statement, expr)
		expr += 8
		expr = generate_push_expression_casted(statement, expr, c)
		expr = generate_push_expression_casted(statement, expr, c)
		generate_stack_compare(statement, c)
		emit_setC_rax(comparison)
		emit_push_rax()
		return expr
	:generate_conditional
		expr += 8
		p = expr + 4
		expr = generate_push_expression(statement, expr)
		generate_stack_compare_against_zero(statement, *4p)
		emit_je_rel32(0) ; temporary je +0 (correct offset will be filled in)
		addr1 = code_output
		expr = generate_push_expression_casted(statement, expr, type)
		emit_jmp_rel32(0) ; temporary jmp +0 (correct offset will be filled in)
		addr2 = code_output
		; fill in jump offset
		d = addr2 - addr1
		addr1 -= 4
		*4addr1 = d
		
		addr1 = code_output
		expr = generate_push_expression_casted(statement, expr, type)
		addr2 = code_output
		; fill in jump offset
		d = addr2 - addr1
		addr1 -= 4
		*4addr1 = d
		return expr
	
	:generate_logical_and
		expr += 8
		p = expr + 4
		expr = generate_push_expression(statement, expr)
		generate_stack_compare_against_zero(statement, *4p)
		emit_je_rel32(0) ; temporary je +0; offset will be filled in later
		addr1 = code_output
		p = expr + 4
		expr = generate_push_expression(statement, expr)
		generate_stack_compare_against_zero(statement, *4p)
		
		emit_je_rel32(15)         ; je +15 (10 bytes for mov rax, 1; 5 bytes for jmp +2)
		emit_mov_rax_imm64(1)     ; mov rax, 1
		emit_jmp_rel32(2)         ; jmp +2 (skip xor rax, rax)
		addr2 = code_output
		emit_zero_rax()           ; xor rax, rax
		emit_push_rax()           ; push rax
		
		; fill in jump offset
		d = addr2 - addr1
		addr1 -= 4
		*4addr1 = d
		return expr
	
	:generate_logical_or
		expr += 8
		p = expr + 4
		expr = generate_push_expression(statement, expr)
		generate_stack_compare_against_zero(statement, *4p)
		emit_jne_rel32(0) ; temporary jne +0; offset will be filled in later
		addr1 = code_output
		p = expr + 4
		expr = generate_push_expression(statement, expr)
		generate_stack_compare_against_zero(statement, *4p)
		
		emit_jne_rel32(7)         ; jne +7 (2 bytes for xor eax, eax; 5 bytes for jmp +10)
		emit_zero_rax()           ; xor eax, eax
		emit_jmp_rel32(10)        ; jmp +10 (skip mov rax, 1)
		addr2 = code_output
		emit_mov_rax_imm64(1)     ; mov rax, 1
		emit_push_rax()           ; push rax
		
		; fill in jump offset
		d = addr2 - addr1
		addr1 -= 4
		*4addr1 = d
		return expr
	
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
		p = expr + 4
		expr = generate_push_expression(statement, expr)
		p = types + *4p
		if *2p == TYPE2_FUNCTION_POINTER goto deref_function_pointer
		generate_stack_dereference(statement, type)
		:deref_function_pointer  ; dereferencing a function pointer does NOTHING
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
		p = expr + 8
		p = expression_get_end(p)
		p += 4
		expr = generate_push_address_of_expression(statement, expr)
		if *4p == 1 goto member_array
		generate_stack_dereference(statement, type)
		:member_array
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
	:generate_call
		expr += 8
		local expr_arg_ptrs
		expr_arg_ptrs = malloc(4000)
		local arg_idx
		local call_function
		local return_val_size
		local args_size
		
		return_val_size = type_sizeof(type)
		return_val_size = round_up_to_8(return_val_size)
		
		call_function = expr
		expr = expression_get_end(expr)
		
		args_size = 0
		
		; we have to do a bit of work because the arguments are stored
		;  left to right, but pushed right to left
		arg_idx = 0
		p = expr_arg_ptrs
		:find_call_args_loop
			if *1expr == 0 goto find_call_args_loop_end
			*8p = expr
			
			c = expr + 4
			c = type_sizeof(*4c)
			c = round_up_to_8(c)
			args_size += c
			
			expr = expression_get_end(expr)
			p += 8
			arg_idx += 1
			goto find_call_args_loop
		:find_call_args_loop_end
		expr += 8
		
		:push_args_loop
			if arg_idx == 0 goto push_args_loop_end
			p -= 8
			generate_push_expression(statement, *8p)
			arg_idx -= 1
			goto push_args_loop
		:push_args_loop_end
		free(expr_arg_ptrs)
		
		; create space on stack for return value
		emit_sub_rsp_imm32(return_val_size)
		; put function in rax
		generate_push_expression(statement, call_function)
		emit_mov_rax_qword_rsp()
		emit_add_rsp_imm32(8)
		; call
		emit_call_rax()
		
		if return_val_size > 8 goto generate_big_return
		emit_mov_rax_qword_rsp()      ; mov rax, [rsp]
		emit_add_rsp_imm32(args_size) ; add rsp, (size of arguments on stack)
		emit_mov_qword_rsp_rax()      ; mov [rsp], rax
		return expr
		
		:generate_big_return
		; now we need to copy the return value to the proper place in the stack
		; this is kind of annoying because that might overlap with the current position.
		; so, we'll push a copy of the return value, then copy that over to the proper place.
		local copy_offset
		
		; first copy
		copy_offset = 0 - return_val_size
		emit_mov_reg(REG_RSI, REG_RSP)
		emit_mov_reg(REG_RAX, REG_RSP)
		emit_add_rax_imm32(copy_offset)
		emit_mov_reg(REG_RDI, REG_RAX)
		generate_copy_rsi_to_rdi_qwords(type)
		
		; second copy
		emit_mov_reg(REG_RAX, REG_RSP)
		emit_add_rax_imm32(copy_offset)
		emit_mov_reg(REG_RSI, REG_RAX)
		emit_mov_reg(REG_RAX, REG_RSP)
		emit_add_rax_imm32(args_size)
		emit_mov_reg(REG_RDI, REG_RAX)
		generate_copy_rsi_to_rdi_qwords(type)
		
		emit_add_rsp_imm32(args_size)
		return

; fill in break/continue jump addresses
function handle_refs
	argument p_refs
	argument prev_refs
	argument ref_addr
	local refs
	local p
	local addr
	local d
	
	refs = *8p_refs
	p = refs
	:handle_refs_loop
		if *8p == 0 goto handle_refs_loop_end
		addr = *8p
		p += 8
		d = ref_addr - addr
		addr -= 4
		*4addr = d
		goto handle_refs_loop
	:handle_refs_loop_end
	
	free(refs)
	*8p_refs = prev_refs
	return

function add_ref
	argument refs
	argument addr
	:add_ref_loop
		if *8refs == 0 goto add_ref_loop_end
		refs += 8
		goto add_ref_loop
	:add_ref_loop_end
	*8refs = addr
	return

function generate_statement
	argument statement
	local dat1
	local dat2
	local dat3
	local dat4
	local addr0
	local addr1
	local addr2
	local prev_continue_refs
	local prev_break_refs
	local n
	local p
	local c
	local d
	
	prev_continue_refs = continue_refs
	prev_break_refs = break_refs
	
	dat1 = statement + 8
	dat1 = *8dat1
	dat2 = statement + 16
	dat2 = *8dat2
	dat3 = statement + 24
	dat3 = *8dat3
	dat4 = statement + 32
	dat4 = *8dat4
	
	c = *1statement
	
	if c == STATEMENT_NOOP goto return_0
	if c == STATEMENT_BLOCK goto gen_block
	if c == STATEMENT_RETURN goto gen_return
	if c == STATEMENT_LOCAL_DECLARATION goto gen_local_decl
	if c == STATEMENT_EXPRESSION goto gen_stmt_expr
	if c == STATEMENT_IF goto gen_stmt_if
	if c == STATEMENT_WHILE goto gen_stmt_while
	if c == STATEMENT_DO goto gen_stmt_do
	if c == STATEMENT_FOR goto gen_stmt_for
	if c == STATEMENT_CONTINUE goto gen_stmt_continue
	if c == STATEMENT_BREAK goto gen_stmt_break
	if c == STATEMENT_LABEL goto gen_stmt_label
	if c == STATEMENT_GOTO goto gen_stmt_goto
	if c == STATEMENT_SWITCH goto gen_stmt_switch
	if c == STATEMENT_CASE goto gen_stmt_case
	if c == STATEMENT_DEFAULT goto gen_stmt_default
	
	die(.str_badgenstmt)
	:str_badgenstmt
		string Bad statement passed to generate_statement.
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
		dat1 = 0 - dat1
		
		if dat3 != 0 goto gen_local_decl_initializer
		if dat4 != 0 goto gen_local_decl_data_initializer
		return
		
		:gen_local_decl_initializer
			c = type_sizeof(dat2)
			c = round_up_to_8(c)
			
			; push the expression
			generate_push_expression_casted(statement, dat3, dat2)
			; copy it to where the variable's supposed to be
			emit_mov_reg(REG_RSI, REG_RSP)           ; mov rsi, rsp
			emit_lea_rax_rbp_plus_imm32(dat1)        ; lea rax, [rbp+X]
			emit_mov_reg(REG_RDI, REG_RAX)           ; mov rdi, rax
			generate_copy_rsi_to_rdi_qwords(dat2) 
			; pop the expression
			emit_add_rsp_imm32(c)                    ; add rsp, (size)
			return
		:gen_local_decl_data_initializer
			emit_mov_rax_imm64(dat4)          ; mov rax, (data address)
			emit_mov_reg(REG_RSI, REG_RAX)    ; mov rsi, rax
			emit_lea_rax_rbp_plus_imm32(dat1) ; lea rax, [rbp+X]
			emit_mov_reg(REG_RDI, REG_RAX)    ; mov rdi, rax
			generate_copy_rsi_to_rdi_qwords(dat2)
			return
	:gen_stmt_expr
		generate_push_expression_casted(statement, dat1, TYPE_VOID)
		; since we casted to void, it'll always be 8 bytes on the stack
		emit_add_rsp_imm32(8)
		return
	:gen_stmt_if
		p = dat1 + 4
		generate_push_expression(statement, dat1)
		generate_stack_compare_against_zero(statement, *4p)
		emit_je_rel32(0)    ; je +0 (temporary)
		addr1 = code_output
		generate_statement(dat2) ; "if" branch
		emit_jmp_rel32(0)   ; jmp +0 (temporary)
		addr2 = code_output
		; fill in je
		d = addr2 - addr1
		addr1 -= 4
		*4addr1 = d
		addr1 = addr2
		if dat3 == 0 goto gen_if_no_else
			generate_statement(dat3) ; "else" branch
		:gen_if_no_else
		addr2 = code_output
		; fill in jmp
		d = addr2 - addr1
		addr1 -= 4
		*4addr1 = d
		return
	:gen_stmt_while
		continue_refs = malloc(8000)
		break_refs = malloc(8000)
		
		addr0 = code_output
		p = dat1 + 4
		generate_push_expression(statement, dat1)
		generate_stack_compare_against_zero(statement, *4p)
		emit_je_rel32(0)    ; je +0 (temporary)
		addr1 = code_output
		generate_statement(dat2)
		emit_jmp_rel32(0)   ; jmp +0 (temporary)
		addr2 = code_output
		
		handle_refs(&continue_refs, prev_continue_refs, addr0)
		handle_refs(&break_refs, prev_break_refs, addr2)
		
		; fill in je
		d = addr2 - addr1
		p = addr1 - 4
		*4p = d
		; fill in jmp
		d = addr0 - addr2
		p = addr2 - 4
		*4p = d
		return
	:gen_stmt_do
		continue_refs = malloc(8000)
		break_refs = malloc(8000)
		
		addr0 = code_output
		generate_statement(dat1)
		p = dat2 + 4
		generate_push_expression(statement, dat2)
		generate_stack_compare_against_zero(statement, *4p)
		emit_jne_rel32(0) ; jne +0 (temorary)
		addr1 = code_output
		
		handle_refs(&continue_refs, prev_continue_refs, addr0)
		handle_refs(&break_refs, prev_break_refs, addr1)
		
		d = addr0 - addr1
		addr1 -= 4
		*4addr1 = d
		return
	:gen_stmt_for
		continue_refs = malloc(8000)
		break_refs = malloc(8000)
		
		if dat1 == 0 goto gen_for_no_expr1
			generate_push_expression_casted(statement, dat1, TYPE_VOID)
			emit_add_rsp_imm32(8) ; void is stored as 8 bytes
		:gen_for_no_expr1
		
		addr0 = code_output
		p = dat2 + 4
		if dat2 == 0 goto gen_for_no_expr2
			generate_push_expression(statement, dat2)
			generate_stack_compare_against_zero(statement, *4p)
			emit_je_rel32(0) ; je +0 (temporary)
		:gen_for_no_dat2_cont
		addr1 = code_output
		generate_statement(dat4) ; body
		handle_refs(&continue_refs, prev_continue_refs, code_output)
		if dat3 == 0 goto gen_for_no_expr3
			generate_push_expression_casted(statement, dat3, TYPE_VOID)
			emit_add_rsp_imm32(8) ; void is stored as 8 bytes
		:gen_for_no_expr3
		emit_jmp_rel32(0) ; jmp +0 (temporary)
		addr2 = code_output
		handle_refs(&break_refs, prev_break_refs, addr2)
		
		; fill in je
		d = addr2 - addr1
		p = addr1 - 4
		*4p = d
		
		; fill in jmp
		d = addr0 - addr2
		p = addr2 - 4
		*4p = d
		return
		:gen_for_no_expr2
			; we need to have a fake jump to be filled in here
			; so let's make a jump that'll never happen
			emit_zero_rax()     ; xor eax, eax
			emit_test_rax_rax() ; test rax, rax
			emit_jne_rel32(0)   ; jne +0 (temporary)
			goto gen_for_no_dat2_cont
	:gen_stmt_continue
		if continue_refs == 0 goto continue_outside_of_loop
		emit_jmp_rel32(0) ; jmp +0 (temporary)
		add_ref(continue_refs, code_output)
		return
		:continue_outside_of_loop
			statement_error(statement, .str_continue_outside_of_loop)
		:str_continue_outside_of_loop
			string continue statement not inside loop.
			byte 0
	:gen_stmt_break
		if break_refs == 0 goto break_outside_of_loop
		emit_jmp_rel32(0) ; jmp +0 (temporary)
		add_ref(break_refs, code_output)
		return
		:break_outside_of_loop
			statement_error(statement, .str_break_outside_of_loop)
		:str_break_outside_of_loop
			string break statement not inside loop or switch.
			byte 0
	:gen_stmt_label
		if codegen_second_pass != 0 goto gen_label_pass2
			ident_list_add(curr_function_labels, dat1, code_output)
			return
		:gen_label_pass2
			addr1 = ident_list_lookup(curr_function_labels, dat1)
			if addr1 != code_output goto bad_label_addr
			return
		:bad_label_addr
			die(.str_bad_label_addr)
		:str_bad_label_addr
			string Internal compiler error: Label address on 2nd pass doesn't match 1st pass.
			byte 0
	:gen_stmt_goto
		if codegen_second_pass == 0 goto gen_goto_pass1
		addr0 = ident_list_lookup(curr_function_labels, dat1)
		if addr0 == 0 goto bad_label
		d = addr0 - code_output
		d -= 5 ; subtract length of jmp instruction
		emit_jmp_rel32(d)
		return
		:gen_goto_pass1
			emit_jmp_rel32(0) ; we don't know the address of the label; just use 0
			return
		:bad_label
			statement_error(statement, .str_bad_label)
		:str_bad_label
			string Unrecognized label.
			byte 0
	:gen_stmt_switch
		break_refs = malloc(8000)
		
		local old_prev_case_addr
		old_prev_case_addr = prev_case_addr
		
		generate_push_expression_casted(statement, dat1, TYPE_UNSIGNED_LONG)
		emit_pop_rax()                    ; pop rax
		emit_mov_reg(REG_RBX, REG_RAX)    ; mov rbx, rax
		
		emit_jmp_rel32(0)                 ; jmp +0 (temporary)
		prev_case_addr = code_output
		
		generate_statement(dat2)
		
		addr1 = code_output
		handle_refs(&break_refs, prev_break_refs, addr1)
		
		; fill in last jump, if any
		if prev_case_addr == 0 goto switch_had_default
			d = addr1 - prev_case_addr
			p = prev_case_addr - 4
			*4p = d
		:switch_had_default
		prev_case_addr = old_prev_case_addr
		return
	:gen_stmt_case
		if prev_case_addr == 0 goto gen_bad_case
		emit_jmp_rel32(0) ; jump over the part where we deal with this case label
		addr0 = code_output
		
		; fill in previous jump
		d = addr0 - prev_case_addr
		p = prev_case_addr - 4
		*4p = d
		
		emit_mov_rax_imm64(dat1)
		emit_cmp_rax_rbx()
		emit_jne_rel32(0)
		prev_case_addr = code_output
		
		addr1 = code_output
		; fill in jump over comparison
		d = addr1 - addr0
		p = addr0 - 4
		*4p = d
		return
		
		:gen_bad_case
			; @NONSTANDARD: we don't allow `case X:` after `default:`
			; it's very annoying that the C standard allows that
			statement_error(statement, .str_gen_bad_case)
		:str_gen_bad_case
			string Either case outside of switch, or case following default.
			byte 0
	:gen_stmt_default
		addr0 = code_output
		
		; fill in previous jump
		d = addr0 - prev_case_addr
		p = prev_case_addr - 4
		*4p = d
		
		prev_case_addr = 0
		return
	
function generate_function
	argument function_name
	argument function_statement
	local function_type
	local out0
	local n_stack_bytes
	
	debug_putsln(function_name)
	
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
	
	n_stack_bytes = ident_list_lookup(functions_required_stack_space, function_name)
	emit_sub_rsp_imm32(n_stack_bytes)
	
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
		putsln(function_name)
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
	emit_dword(7) ; read/write/execute  (this needs to be executable for `syscall` to be implementable)
	emit_qword(RWDATA_ADDR) ; offset in file
	emit_qword(RWDATA_ADDR) ; virtual address
	emit_qword(0) ; physical address
	emit_qword(RWDATA_SIZE) ; size in executable file
	emit_qword(RWDATA_SIZE) ; size when loaded into memory
	emit_qword(4096) ; alignment
	
	
	
	local p_func
	local end_addr
	code_output = output_file_data + FUNCTIONS_ADDR
	codegen_second_pass = 0
	debug_puts(.str_first_pass)
	generate_functions()
	end_addr = code_output - output_file_data
	if end_addr ] FUNCTIONS_END goto too_much_code
	code_output = output_file_data + FUNCTIONS_ADDR
	codegen_second_pass = 1
	debug_puts(.str_second_pass)
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
	:too_much_code
		die(.str_too_much_code)
	:str_too_much_code
		string Too much code for executable.
		byte 0
	:str_first_pass
		string First codegen pass...
		byte 0xa
		byte 0
	:str_second_pass
		string Second codegen pass...
		byte 0xa
		byte 0
	
