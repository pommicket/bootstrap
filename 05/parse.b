; is this token the start of a type?
function token_is_type
	argument token
	local c
	c = *1token
	if c == TOKEN_IDENTIFIER goto token_is_ident_type
	if c == KEYWORD_UNSIGNED goto return_1
	if c == KEYWORD_CHAR goto return_1
	if c == KEYWORD_SHORT goto return_1
	if c == KEYWORD_INT goto return_1
	if c == KEYWORD_LONG goto return_1
	if c == KEYWORD_FLOAT goto return_1
	if c == KEYWORD_DOUBLE goto return_1
	if c == KEYWORD_VOID goto return_1
	if c == KEYWORD_STRUCT goto return_1
	if c == KEYWORD_UNION goto return_1
	if c == KEYWORD_ENUM goto return_1
	goto return_0
	:token_is_ident_type
		token += 8
		c = *8token
		local b
		b = ident_list_lookup(typedefs, c)
		if b != 0 goto return_1
		goto return_0

; NB: this takes a pointer to struct data, NOT a type
; Returns 1 if it's a union OR a struct with 1 member (we don't distinguish between these in any way)
function structure_is_union
	argument struct
	local offset
	; calculate offset of 2nd member, or 0 if there is only one member
	offset = ident_list_value_at_index(struct, 1)
	offset &= 0xffffffff
	if offset == 0 goto return_1 ; if that's 0, it's a union or 1-element struct
	goto return_0
	
	
function parse_tokens
	argument tokens
	local token
	local ident
	local type
	local p
	local b
	local c
	local base_type
	local base_type_end
	local name
	local prefix
	local prefix_end
	local suffix
	local suffix_end
	local is_extern
	
	token = tokens
	:parse_tokens_loop
		is_extern = 0
		if *1token == TOKEN_EOF goto parse_tokens_eof
		if *1token == KEYWORD_STATIC goto parse_static_toplevel_decl
		if *1token == KEYWORD_EXTERN goto parse_extern_toplevel_decl
		if *1token == KEYWORD_TYPEDEF goto parse_typedef
		
		b = token_is_type(token)
		if b != 0 goto parse_toplevel_decl
		
		die(.str_bad_statement)
		:str_bad_statement
			string Bad statement.
			byte 0
		:parse_static_toplevel_decl
			token += 16 ; we don't care that this is static
			goto parse_toplevel_decl
		:parse_extern_toplevel_decl
			token += 16
			is_extern = 1
			goto parse_toplevel_decl
		:parse_toplevel_decl
			base_type = token
			base_type_end = type_get_base_end(token)
			token = base_type_end
			:tl_decl_loop
				prefix = token
				prefix_end = type_get_prefix_end(prefix)
				if *1prefix_end != TOKEN_IDENTIFIER goto tl_decl_no_ident
				name = prefix_end + 8
				name = *8name
				suffix = prefix_end + 16
				suffix_end = type_get_suffix_end(prefix)
				type = types_bytes_used
				parse_type_declarators(prefix, prefix_end, suffix, suffix_end)
				parse_base_type(base_type, base_type_end)
				
				; ensure rwdata_end_addr is aligned to 8 bytes
				; otherwise addresses could be screwed up
				rwdata_end_addr += 7
				rwdata_end_addr >= 3
				rwdata_end_addr <= 3
				
				token = suffix_end
				if *1token == SYMBOL_LBRACE goto parse_function_definition
				if is_extern != 0 goto parse_tl_decl_cont  ; ignore external variable declarations
				; deal with the initializer if there is one
				if *1token == SYMBOL_SEMICOLON goto parse_tld_no_initializer
				if *1token == SYMBOL_COMMA goto parse_tld_no_initializer
				if *1token == SYMBOL_EQ goto parse_tld_initializer
				token_error(token, .str_unrecognized_stuff_after_declaration)
				:str_unrecognized_stuff_after_declaration
					string Declaration should be followed by one of: { , =
					byte 32
					byte 59 ; semicolon
					byte 0	
				:parse_tl_decl_cont
				
				
				if *1token == SYMBOL_SEMICOLON goto tl_decl_loop_done
				if *1token != SYMBOL_COMMA goto tld_bad_stuff_after_decl
				token += 16
				goto tl_decl_loop
			:tl_decl_loop_done
			token += 16 ; skip semicolon
			goto parse_tokens_loop
				 				 
			:tl_decl_no_ident
				token_error(prefix_end, .str_tl_decl_no_ident)
			:str_tl_decl_no_ident
				string No identifier in top-level declaration.
				byte 0
			:tld_bad_stuff_after_decl
				token_error(token, .str_tld_bad_stuff_after_decl)
			:str_tld_bad_stuff_after_decl
				string Declarations should be immediately followed by a comma or semicolon.
				byte 0
		:parse_tld_no_initializer
			p = types + type
			if *1p == TYPE_FUNCTION goto parse_tl_decl_cont ; ignore function declarations -- we do two passes anyways
			b = ident_list_lookup(global_variables, name)
			if b != 0 goto global_redefinition
			c = type < 32
			c |= rwdata_end_addr
			ident_list_add(global_variables, name, c)
			; just skip forward by the size of this variable -- it'll automatically be filled with 0s.
			rwdata_end_addr += type_sizeof(type)
			goto parse_tl_decl_cont
		:parse_tld_initializer
			if *1p == TYPE_FUNCTION goto function_initializer
			b = ident_list_lookup(global_variables, name)
			if b != 0 goto global_redefinition
			token += 16 ; skip =
			c = type < 32
			c |= rwdata_end_addr
			ident_list_add(global_variables, name, c)
			parse_constant_initializer(&token, type)
			goto parse_tl_decl_cont
		:global_redefinition
			token_error(token, .str_global_redefinition)
		:str_global_redefinition
			string Redefinition of global variable.
			byte 0
		:function_initializer
			token_error(token, .str_function_initializer)
		:str_function_initializer
			string Functions should not have initializers.
			byte 0
		:parse_function_definition
			p = types + type
			; @NOTE: remember to turn array members into pointers
			if *1p != TYPE_FUNCTION goto lbrace_after_declaration
			die(.str_fdNI) ; @TODO
			:str_fdNI
				string function definitions not implemented.
				byte 10
				byte 0
			:lbrace_after_declaration
				token_error(token, .str_lbrace_after_declaration)
			:str_lbrace_after_declaration
				string Opening { after declaration of non-function.
				byte 0
		:parse_typedef
			base_type = token + 16
			base_type_end = type_get_base_end(base_type)
			
			token = base_type_end
			
			:typedef_loop
				prefix = token
				prefix_end = type_get_prefix_end(prefix)
				if *1prefix_end != TOKEN_IDENTIFIER goto typedef_no_ident
				ident = prefix_end + 8
				ident = *8ident
				suffix = prefix_end + 16
				suffix_end = type_get_suffix_end(prefix)
				
				;putc('B)
				;putc(':)
				;print_tokens(base_type, base_type_end)
				;putc('P)
				;putc(':)
				;print_tokens(prefix, prefix_end)
				;putc('S)
				;putc(':)
				;print_tokens(suffix, suffix_end)
				
				type = types_bytes_used
				parse_type_declarators(prefix, prefix_end, suffix, suffix_end)
				parse_base_type(base_type)
				
				puts(.str_typedef)
				putc(32)
				print_type(type)
				putc(10)
				
				b = ident_list_lookup(typedefs, ident)
				if b != 0 goto typedef_redefinition
				
				ident_list_add(typedefs, ident, type)
				token = suffix_end
				if *1token == SYMBOL_SEMICOLON goto typedef_loop_end
				if *1token != SYMBOL_COMMA goto bad_typedef
				token += 16 ; skip comma
				goto typedef_loop
			:typedef_loop_end
			token += 16 ; skip semicolon
			goto parse_tokens_loop
		:typedef_no_ident
			token_error(token, .str_typedef_no_ident)
		:str_typedef_no_ident
			string No identifier in typedef declaration.
			byte 0
		:bad_typedef
			token_error(token, .str_bad_typedef)
		:str_bad_typedef
			string Bad typedef.
			byte 0
		:typedef_redefinition
			token_error(token, .str_typedef_redefinition)
		:str_typedef_redefinition
			string typedef redefinition.
			byte 0
	:parse_tokens_eof
	return

; parse a global variable's initializer
; e.g.    int x[5] = {1+8, 2, 3, 4, 5};
; advances *p_token to the token right after the initializer
; if `type` refers to a sizeless array type (e.g. int x[] = {1,2,3};), it will be altered to the correct size
; outputs the initializer data to rwdata_end_addr, and advances it accordingly.
;    this aligns rwdata_end_addr before writing data, so if you want the initial value of rwdata_end_addr
;    to correspond to the address, ALIGN IT FIRST.
function parse_constant_initializer
	argument p_token
	argument type
	
	local addr0
	local subtype
	local token
	local depth
	local a
	local b
	local c
	local len
	local p
	local expr
	local value
	
	token = *8p_token
	
	p = types + type
	if *1p == TYPE_STRUCT goto parse_struct_initializer
	if *1p == TYPE_ARRAY goto parse_array_initializer
	if *1token == SYMBOL_LBRACE goto parse_braced_expression_initializer
	
	; an ordinary expression
	; first, find the end of the expression.
	local end
	depth = 0
	end = token
	; find the end of the initializer, i.e. the next comma or semicolon not inside braces,
	; square brackets, or parentheses:
	:find_init_end_loop
		c = *1end
		if c == TOKEN_EOF goto find_init_end_eof
		if c == SYMBOL_LPAREN goto find_init_end_incdepth
		if c == SYMBOL_LSQUARE goto find_init_end_incdepth
		if c == SYMBOL_LBRACE goto find_init_end_incdepth
		if c == SYMBOL_RPAREN goto find_init_end_decdepth
		if c == SYMBOL_RSQUARE goto find_init_end_decdepth
		if c == SYMBOL_RBRACE goto find_init_end_decdepth
		if depth > 0 goto find_init_cont
		if depth < 0 goto init_end_bad_brackets
		if c == SYMBOL_COMMA goto found_init_end
		if c == SYMBOL_SEMICOLON goto found_init_end
		:find_init_cont
		end += 16
		goto find_init_end_loop
		:find_init_end_incdepth
			depth += 1
			goto find_init_cont
		:find_init_end_decdepth
			depth -= 1
			if depth < 0 goto found_init_end
			goto find_init_cont
	:found_init_end
	
	p = types + type
	if *1p > TYPE_POINTER goto expression_initializer_for_nonscalar_type
	
	global 8000 dat_const_initializer
	expr = &dat_const_initializer
	parse_expression(token, end, expr)
	evaluate_constant_expression(token, expr, &value)
	if *1p == TYPE_FLOAT goto init_floating_check
	if *1p == TYPE_DOUBLE goto init_floating_check
	:init_good
	token = end
	c = type_sizeof(type)
	; align rwdata_end_addr to size of type
	rwdata_end_addr += c - 1
	rwdata_end_addr /= c
	rwdata_end_addr *= c
	p = output_file_data + rwdata_end_addr
	rwdata_end_addr += c
	if c == 1 goto write_initializer1
	if c == 2 goto write_initializer2
	if c == 4 goto write_initializer4
	if c == 8 goto write_initializer8
	die(.init_somethings_very_wrong)
	:init_somethings_very_wrong
		string Scalar type with a weird size. This shouldn't happen.
		byte 0
	:write_initializer1
		*1p = value
		goto const_init_ret
	:write_initializer2
		*2p = value
		goto const_init_ret
	:write_initializer4
		*4p = value
		goto const_init_ret
	:write_initializer8
		*8p = value
		goto const_init_ret
	:init_floating_check ; we only support 0 as a floating-point initializer
		if value != 0 goto floating_initializer_other_than_0
		goto init_good
	
	:const_init_ret
	*8p_token = token
	return
	
	:parse_braced_expression_initializer
		; a scalar initializer may optionally be enclosed in braces, e.g.
		;   int x = {3};
		token += 16
		parse_constant_initializer(&token, type)
		if *1token != SYMBOL_RBRACE goto bad_scalar_initializer
		token += 16
		goto const_init_ret
		:bad_scalar_initializer
			token_error(token, .str_bad_scalar_initializer)
		:str_bad_scalar_initializer
			string Bad scalar initializer.
			byte 0
	:parse_array_initializer
		if *1token == TOKEN_STRING_LITERAL goto parse_string_array_initializer ; check for  char x[] = "hello";
		if *1token != SYMBOL_LBRACE goto array_init_no_lbrace ; only happens when recursing
		token += 16
		:array_init_no_lbrace
		addr0 = rwdata_end_addr
		
		len = types + type
		len += 1 ; skip TYPE_ARRAY
		len = *8len
		
		subtype = type + 9 ; skip TYPE_ARRAY and size
		:array_init_loop
			if *1token == TOKEN_EOF goto array_init_eof
			parse_constant_initializer(&token, subtype)
			len -= 1 ; kind of horrible hack.  -len will track the number of elements for sizeless arrays, and len will count down to 0 for sized arrays
			if len == 0 goto array_init_loop_end
			if *1token == SYMBOL_RBRACE goto array_init_loop_end
			if *1token != SYMBOL_COMMA goto bad_array_initializer
			token += 16 ; skip comma
			goto array_init_loop
		:array_init_loop_end
	
		if *1token != SYMBOL_RBRACE goto array_init_noskip
		p = *8p_token
		if *1p != SYMBOL_LBRACE goto array_init_noskip ; we don't want to skip the closing } because it doesn't belong to us.
		:array_init_skip
			token += 16 ; skip } or ,
		:array_init_noskip
		p = types + type
		p += 1 ; skip TYPE_ARRAY
		if *8p == 0 goto sizeless_array_initializer
			; sized array
			rwdata_end_addr = addr0
			c = type_sizeof(subtype)
			rwdata_end_addr += *8p * c ; e.g. int x[50] = {1,2};  advance rwdata_end_addr by 50*sizeof(int)
			goto const_init_ret
		:sizeless_array_initializer
			; sizeless array
			*8p = 0 - len
			goto const_init_ret
	:array_init_eof
		token_error(token, .str_array_init_eof)
	:str_array_init_eof
		string Array initializer does not end.
		byte 0
	:bad_array_initializer
		token_error(token, .str_bad_array_initializer)
	:str_bad_array_initializer
		string Bad array initializer.
		byte 0
	:parse_struct_initializer
		addr0 = rwdata_end_addr
		
		if *1token != SYMBOL_LBRACE goto struct_init_no_lbrace ; only happens when recursing
		token += 16
		:struct_init_no_lbrace
		
		a = type_alignof(type)
		; align rwdata_end_addr properly
		rwdata_end_addr += a - 1
		rwdata_end_addr /= a
		rwdata_end_addr *= a
		
		p = types + type
		p += 1
		b = structure_is_union(*8p)
		if b != 0 goto parse_union_initializer
		
		; struct initializer
		a = *8p
		:struct_init_loop
			if *1token == TOKEN_EOF goto struct_init_eof
			
			; skip name of member
			a = memchr(a, 0)
			a += 5 ; skip null terminator, offset
			subtype = *4a
			a += 4
			
			parse_constant_initializer(&token, subtype)
			if *1token == SYMBOL_RBRACE goto struct_init_loop_end
			if *1a == 0 goto struct_init_loop_end ; finished reading all the members of the struct
			if *1token != SYMBOL_COMMA goto bad_struct_initializer
			token += 16 ; skip comma
			goto struct_init_loop
		:struct_init_loop_end
		
		:struct_init_ret
		c = type_sizeof(type)
		rwdata_end_addr = addr0 + c ; add full size of struct/union to rwdata_end_addr, even if initialized member is smaller than that
		
		if *1token != SYMBOL_RBRACE goto struct_init_noskip
		p = *8p_token
		if *1p != SYMBOL_LBRACE goto struct_init_noskip ; we don't want to skip the closing } because it doesn't belong to us.
		token += 16 ; skip }
		:struct_init_noskip
		
		goto const_init_ret
		
	:parse_union_initializer
		a = ident_list_value_at_index(*8p, 0)
		subtype = a > 32 ; extract type
		parse_constant_initializer(&token, subtype)
		goto struct_init_ret
	
	:struct_init_eof
		token_error(token, .str_struct_init_eof)
	:str_struct_init_eof
		string struct initializer does not end.
		byte 0
	:bad_struct_initializer
		token_error(token, .str_bad_struct_initializer)
	:str_bad_struct_initializer
		string Bad struct initializer.
		byte 0
	
	:parse_string_array_initializer
		p = types + type
		p += 9
		if *1p != TYPE_CHAR goto string_literal_bad_type
		p -= 8
		c = *8p ; array size
		token += 8
		a = output_file_data + rwdata_end_addr ; destination (where to put the string data)
		b = output_file_data + *8token ; source (where the string data is now)
		token += 8
		if c == 0 goto string_literal_sizeless_initializer
		value = strlen(b)
		if c < value goto string_literal_init_too_long ; e.g. char x[3] = "hello";
		strcpy(a, b)
		rwdata_end_addr += c ; advance by c, which is possibly more than the length of the string--the remaining bytes will be 0s
		goto const_init_ret
	:string_literal_sizeless_initializer ; e.g. char x[] = "hello";
		c = strlen(b)
		c += 1 ; null terminator
		*8p = c ; set array size
		strcpy(a, b)
		rwdata_end_addr += c
		goto const_init_ret
	:string_literal_init_too_long
		token_error(token, .str_string_literal_init_too_long)
	:str_string_literal_init_too_long
		string String literal is too long to fit in array.
		byte 0 
	:stuff_after_string_literal
		token_error(token, .str_stuff_after_string_literal)
	:str_stuff_after_string_literal
		string Stuff after string literal in initializer.
		byte 0
	:string_literal_bad_type
		token_error(token, .str_string_literal_bad_type)
	:str_string_literal_bad_type
		string Bad type for string literal initializer (i.e. not char* or char[]).
		byte 0
	:find_init_end_eof
		token_error(token, .str_find_init_end_eof)
	:str_find_init_end_eof
		string Can't find end of initializer.
		byte 0
	:init_end_bad_brackets
		token_error(end, .str_init_end_bad_brackets)
	:str_init_end_bad_brackets
		string Too many closing brackets.
		byte 0
	:expression_initializer_for_nonscalar_type
		token_error(token, .str_expression_initializer_for_nonscalar_type)
	:str_expression_initializer_for_nonscalar_type
		string Expression initializer for non-scalar type.
		byte 0
	:floating_initializer_other_than_0
		token_error(token, .str_floating_initializer_other_than_0)
	:str_floating_initializer_other_than_0
		string Only 0 is supported as a floating-point initializer.
		byte 0
; *p_token should be pointing to a {, this will advance it to point to the matching }
function token_skip_to_matching_rbrace
	argument p_token
	local token
	local depth
	token = *8p_token
	depth = 0
	:skip_rbrace_loop
		if *1token == SYMBOL_LBRACE goto skip_rbrace_incdepth
		if *1token == SYMBOL_RBRACE goto skip_rbrace_decdepth
		if *1token == TOKEN_EOF goto skip_rbrace_eof
		:skip_rbrace_next
		token += 16
		goto skip_rbrace_loop
		:skip_rbrace_incdepth
			depth += 1
			goto skip_rbrace_next
		:skip_rbrace_decdepth
			depth -= 1
			if depth == 0 goto skip_rbrace_ret
			goto skip_rbrace_next
	:skip_rbrace_ret
	*8p_token = token
	return
	
	:skip_rbrace_eof
		token_error(*8p_token, .str_skip_rbrace_eof)
	:str_skip_rbrace_eof
		string Unmatched {
		byte 0

; *p_token should be pointing to a [, this will advance it to point to the matching ]
function token_skip_to_matching_rsquare
	argument p_token
	local token
	local depth
	token = *8p_token
	depth = 0
	:skip_square_loop
		if *1token == SYMBOL_LSQUARE goto skip_square_incdepth
		if *1token == SYMBOL_RSQUARE goto skip_square_decdepth
		if *1token == TOKEN_EOF goto skip_square_eof
		:skip_square_next
		token += 16
		goto skip_square_loop
		:skip_square_incdepth
			depth += 1
			goto skip_square_next
		:skip_square_decdepth
			depth -= 1
			if depth == 0 goto skip_square_ret
			goto skip_square_next
	:skip_square_ret
	*8p_token = token
	return
	
	:skip_square_eof
		token_error(*8p_token, .str_skip_square_eof)
	:str_skip_square_eof
		string Unmatched [
		byte 0


; *p_token should be on a ); this goes back to the corresponding (
;  THERE MUST ACTUALLY BE A MATCHING BRACKET, OTHERWISE THIS WILL DO BAD THINGS
function token_reverse_to_matching_lparen
	argument p_token
	local token
	local depth
	token = *8p_token
	depth = 0
	:reverse_paren_loop
		if *1token == SYMBOL_LPAREN goto reverse_paren_incdepth
		if *1token == SYMBOL_RPAREN goto reverse_paren_decdepth
		:reverse_paren_next
		token -= 16
		goto reverse_paren_loop
		:reverse_paren_incdepth
			depth += 1
			if depth == 0 goto reverse_paren_ret
			goto reverse_paren_next
		:reverse_paren_decdepth
			depth -= 1
			goto reverse_paren_next
	:reverse_paren_ret
	*8p_token = token
	return


; we split types into base (B), prefix (P) and suffix (S)
;     struct Thing (*things[5])(void), *something_else[3];
;     BBBBBBBBBBBB PP      SSSSSSSSSS  P              SSS
; the following functions deal with figuring out where these parts are.

; return the end of the base for this type.
function type_get_base_end
	argument token
	local c
	c = *1token
	if c == KEYWORD_STRUCT goto skip_struct_union_enum
	if c == KEYWORD_UNION goto skip_struct_union_enum
	if c == KEYWORD_ENUM goto skip_struct_union_enum
	; skip the "base type"
	token += 16 ; importantly, this skips the typedef'd name if there is one (e.g. typedef int Foo; Foo x;)
	:skip_base_type_loop
		c = *1token
		if c == KEYWORD_UNSIGNED goto skip_base_type_loop_cont ;e.g. int unsigned x;
		if c == KEYWORD_CHAR goto skip_base_type_loop_cont ;e.g. unsigned char x;
		if c == KEYWORD_SHORT goto skip_base_type_loop_cont ;e.g. unsigned short x;
		if c == KEYWORD_INT goto skip_base_type_loop_cont ;e.g. unsigned int x;
		if c == KEYWORD_LONG goto skip_base_type_loop_cont ;e.g. unsigned long x;
		if c == KEYWORD_DOUBLE goto skip_base_type_loop_cont ;e.g. long double x;
		goto skip_base_type_loop_end
		:skip_base_type_loop_cont
			token += 16
			goto skip_base_type_loop
	
	:skip_base_type_loop_end
	return token
	
	:skip_struct_union_enum
		token += 16
		if *1token != TOKEN_IDENTIFIER goto skip_sue_no_name
			token += 16 ; struct *blah*
		:skip_sue_no_name
		if *1token != SYMBOL_LBRACE goto skip_base_type_loop_end ; e.g. struct Something x[5];
		; okay we have something like
		;   struct {
		;       int x, y;
		;   } test;
		token_skip_to_matching_rbrace(&token)
		token += 16
		goto skip_base_type_loop_end


; return the end of this type prefix
function type_get_prefix_end
	argument token
	local c
	:find_prefix_end_loop
		c = *1token
		if c == TOKEN_IDENTIFIER goto found_prefix_end
		if c == KEYWORD_UNSIGNED goto prefix_end_cont
		if c == KEYWORD_CHAR goto prefix_end_cont
		if c == KEYWORD_SHORT goto prefix_end_cont
		if c == KEYWORD_INT goto prefix_end_cont
		if c == KEYWORD_LONG goto prefix_end_cont
		if c == KEYWORD_FLOAT goto prefix_end_cont
		if c == KEYWORD_DOUBLE goto prefix_end_cont
		if c == SYMBOL_LPAREN goto prefix_end_cont
		if c == SYMBOL_TIMES goto prefix_end_cont
		if c == SYMBOL_LSQUARE goto found_prefix_end
		if c == SYMBOL_RPAREN goto found_prefix_end
		goto found_prefix_end
		
		:prefix_end_cont
			token += 16
			goto find_prefix_end_loop
	:found_prefix_end
	return token

; return the end of this type suffix
; NOTE: you must pass in the PREFIX.
; (In general, we can't find the end of the suffix without knowing the prefix.)
;    int (*x);
;            ^ suffix ends here
;    (int *)
;          ^ suffix ends here
function type_get_suffix_end
	argument prefix
	local depth
	local token
	local c
	
	; find end of suffix
	token = prefix
	depth = 0 ; parenthesis/square bracket depth
	:suffix_end_loop
		c = *1token
		if c == TOKEN_IDENTIFIER goto suffix_end_cont
		if c == SYMBOL_LSQUARE goto suffix_end_incdepth
		if c == SYMBOL_RSQUARE goto suffix_end_decdepth
		if c == SYMBOL_LPAREN goto suffix_end_incdepth
		if c == SYMBOL_RPAREN goto suffix_end_decdepth
		if c == SYMBOL_TIMES goto suffix_end_cont
		if depth == 0 goto suffix_end_found
		if c == TOKEN_EOF goto type_get_suffix_bad_type
		goto suffix_end_cont
		
		:suffix_end_incdepth
			depth += 1
			goto suffix_end_cont
		:suffix_end_decdepth
			depth -= 1
			if depth < 0 goto suffix_end_found
			goto suffix_end_cont
		:suffix_end_cont
			token += 16
			goto suffix_end_loop
	:suffix_end_found
	
	return token
	:type_get_suffix_bad_type
		token_error(prefix, .str_bad_type_suffix)
	:str_bad_type_suffix
		string Bad type suffix.
		byte 0


; writes to *(types + types_bytes_used), and updates types_bytes_used
function parse_type_declarators
	argument prefix
	argument prefix_end
	argument suffix
	argument suffix_end
	local p
	local expr
	local n
	local c
	local depth
	local out
	
	; main loop for parsing types
	:type_declarators_loop
		p = prefix_end - 16
		if *1suffix == SYMBOL_LSQUARE goto parse_array_type
		if *1suffix == SYMBOL_LPAREN goto parse_function_type
		if *1p == SYMBOL_TIMES goto parse_pointer_type
		if suffix == suffix_end goto type_declarators_loop_end
		if *1suffix == SYMBOL_RPAREN goto parse_type_remove_parentheses
		goto parse_typedecls_bad_type
		
		:parse_pointer_type
			out = types + types_bytes_used
			*1out = TYPE_POINTER
			types_bytes_used += 1
			prefix_end = p
			goto type_declarators_loop
		:parse_array_type
			out = types + types_bytes_used
			*1out = TYPE_ARRAY
			types_bytes_used += 1
			
			p = suffix
			token_skip_to_matching_rsquare(&p)
			suffix += 16 ; skip [
			if *1suffix == SYMBOL_RSQUARE goto array_no_size
	
			; little hack to avoid screwing up types like  double[sizeof(int)]
			;   temporarily pretend we're using a lot more of types
			local prev_types_bytes_used
			prev_types_bytes_used = types_bytes_used
			types_bytes_used += 4000
			
			expr = malloc(4000)
			parse_expression(suffix, p, expr)
			evaluate_constant_expression(prefix, expr, &n)
			if n < 0 goto bad_array_size
			free(expr)
			
			types_bytes_used = prev_types_bytes_used
			
			out = types + types_bytes_used
			*8out = n
			types_bytes_used += 8
			
			suffix = p + 16
			goto type_declarators_loop
			:bad_array_size
				token_error(suffix, .str_bad_array_size)
			:str_bad_array_size
				string Very large or negative array size.
				byte 0
			:array_no_size
				; e.g. int x[] = {1,2,3};
				out = types + types_bytes_used
				*8out = 0
				types_bytes_used += 8
				suffix += 16
				goto type_declarators_loop
		:parse_function_type
			local param_base_type
			local param_prefix
			local param_prefix_end
			local param_suffix
			local param_suffix_end
			
			p = suffix + 16
			out = types + types_bytes_used
			*1out = TYPE_FUNCTION
			types_bytes_used += 1
			:function_type_loop
				param_base_type = p
				param_prefix = type_get_base_end(param_base_type)
				param_prefix_end = type_get_prefix_end(param_prefix)
				param_suffix = param_prefix_end
				if *1param_suffix != TOKEN_IDENTIFIER goto functype_no_ident
				param_suffix += 16
				:functype_no_ident
				param_suffix_end = type_get_suffix_end(param_prefix)
				parse_type_declarators(param_prefix, param_prefix_end, param_suffix, param_suffix_end)
				parse_base_type(param_base_type)
				p = param_suffix_end
				if *1p == SYMBOL_RPAREN goto function_type_loop_end
				if *1p != SYMBOL_COMMA goto parse_typedecls_bad_type
				p += 16
				goto function_type_loop
			:function_type_loop_end
			out = types + types_bytes_used
			*1out = 0
			types_bytes_used += 1
			suffix = p + 16
			goto type_declarators_loop
		:parse_type_remove_parentheses
			if *1p != SYMBOL_LPAREN goto parse_typedecls_bad_type
			prefix_end = p
			suffix += 16
			goto type_declarators_loop
	:type_declarators_loop_end
	return 0
	:parse_typedecls_bad_type
		token_error(prefix, .str_bad_type_declarators)
	:str_bad_type_declarators
		string Bad type declarators.
		byte 0
	
; writes to *(types + types_bytes_used), and updates types_bytes_used (no return value)
function parse_base_type
	argument base_type
	local out
	local flags
	local p
	local c
	local depth
	local is_struct
	is_struct = 0
	
	out = types + types_bytes_used
	
	c = *1base_type
	if c == TOKEN_IDENTIFIER goto base_type_typedef
	if c == KEYWORD_STRUCT goto base_type_struct
	if c == KEYWORD_UNION goto base_type_union
	if c == KEYWORD_ENUM goto base_type_enum
	if c == KEYWORD_FLOAT goto base_type_float
	if c == KEYWORD_VOID goto base_type_void
	
	; "normal" type like int, unsigned char, etc.
	; annoyingly, all of these are equivalent to `unsigned long`:
	;    unsigned long int
	;    long unsigned int
	;    int long unsigned
	;    etc.
	; so we represent these as  PARSETYPE_FLAG_UNSIGNED|PARSETYPE_FLAG_LONG|PARSETYPE_FLAG_INT.
#define PARSETYPE_FLAG_UNSIGNED 1
#define PARSETYPE_FLAG_CHAR 2
#define PARSETYPE_FLAG_SHORT 4
#define PARSETYPE_FLAG_INT 8
#define PARSETYPE_FLAG_LONG 16
#define PARSETYPE_FLAG_DOUBLE 32
	flags = 0
	p = base_type
	:base_type_normal_loop
		c = *1p
		p += 16
		if c == KEYWORD_CHAR goto base_type_flag_char
		if c == KEYWORD_SHORT goto base_type_flag_short
		if c == KEYWORD_INT goto base_type_flag_int
		if c == KEYWORD_LONG goto base_type_flag_long
		if c == KEYWORD_UNSIGNED goto base_type_flag_unsigned
		if c == KEYWORD_DOUBLE goto base_type_flag_double
		goto base_type_normal_loop_end
		:base_type_flag_char
			c = flags & PARSETYPE_FLAG_CHAR
			if c != 0 goto repeated_base_type
			flags |= PARSETYPE_FLAG_CHAR
			goto base_type_normal_loop
		:base_type_flag_short
			c = flags & PARSETYPE_FLAG_SHORT
			if c != 0 goto repeated_base_type
			flags |= PARSETYPE_FLAG_SHORT
			goto base_type_normal_loop
		:base_type_flag_int
			c = flags & PARSETYPE_FLAG_INT
			if c != 0 goto repeated_base_type
			flags |= PARSETYPE_FLAG_INT
			goto base_type_normal_loop
		:base_type_flag_long
			c = flags & PARSETYPE_FLAG_LONG
			if c != 0 goto repeated_base_type
			flags |= PARSETYPE_FLAG_LONG
			goto base_type_normal_loop
		:base_type_flag_unsigned
			c = flags & PARSETYPE_FLAG_UNSIGNED
			if c != 0 goto repeated_base_type
			flags |= PARSETYPE_FLAG_UNSIGNED
			goto base_type_normal_loop
		:base_type_flag_double
			c = flags & PARSETYPE_FLAG_DOUBLE
			if c != 0 goto repeated_base_type
			flags |= PARSETYPE_FLAG_DOUBLE
			goto base_type_normal_loop
		:repeated_base_type
			token_error(p, .str_repeated_base_type)
		:str_repeated_base_type
			string Arithmetic type repeated (e.g. unsigned unsigned int).
			byte 0
	:base_type_normal_loop_end
	if flags == 8 goto base_type_int ; `int`
	if flags == 1 goto base_type_uint ; `unsigned`
	if flags == 9 goto base_type_uint ; `unsigned int` etc.
	if flags == 2 goto base_type_char ; `char`
	if flags == 3 goto base_type_uchar ; `unsigned char` etc.
	if flags == 4 goto base_type_short ; `short`
	if flags == 12 goto base_type_short `short int` etc.
	if flags == 5 goto base_type_ushort ; `unsigned short` etc.
	if flags == 13 goto base_type_ushort ; `unsigned short int` etc. 
	if flags == 16 goto base_type_long ; `long`
	if flags == 24 goto base_type_long ; `long int` etc.
	if flags == 17 goto base_type_ulong ; `unsigned long` etc.
	if flags == 25 goto base_type_ulong ; `unsigned long int` etc.
	if flags == 32 goto base_type_double ; `double`
	if flags == 48 goto base_type_double ; `long double` (we use the same type for double and long double)
	
	goto bad_base_type
	
	:base_type_char
		*1out = TYPE_CHAR
		out += 1
		goto base_type_done
	:base_type_uchar
		*1out = TYPE_UNSIGNED_CHAR
		out += 1
		goto base_type_done
	:base_type_short
		*1out = TYPE_SHORT
		out += 1
		goto base_type_done
	:base_type_ushort
		*1out = TYPE_UNSIGNED_SHORT
		out += 1
		goto base_type_done
	:base_type_int
		*1out = TYPE_INT
		out += 1
		goto base_type_done
	:base_type_uint
		*1out = TYPE_UNSIGNED_INT
		out += 1
		goto base_type_done
	:base_type_long
		*1out = TYPE_LONG
		out += 1
		goto base_type_done
	:base_type_ulong
		*1out = TYPE_UNSIGNED_LONG
		out += 1
		goto base_type_done
	:base_type_double
		*1out = TYPE_DOUBLE
		out += 1
		goto base_type_done
	
	:base_type_done
	types_bytes_used = out - types
	return 0
	
	:base_type_struct
		is_struct = 1
		; fallthrough
	:base_type_union
		local struct_name
		local struct
		struct_name = .empty_string
		p = base_type + 16
		if *1p != TOKEN_IDENTIFIER goto base_type_have_name
		p += 8
		struct_name = *8p
		p += 8
		:base_type_have_name
		c = ident_list_lookup(structures, struct_name)
		if *1p == SYMBOL_LBRACE goto base_type_struct_definition
		
		if c == 0 goto base_type_incomplete_struct
			; e.g. struct Foo x;  where struct Foo has been defined
			*1out = TYPE_STRUCT
			out += 1
			*8out = c
			out += 8
			goto base_type_done
		:base_type_incomplete_struct
			; e.g. struct Foo *x;  where struct Foo hasn't been defined
			*1out = TYPE_VOID
			out += 1
			goto base_type_done
		:base_type_struct_definition
			;  @NONSTANDARD: we don't handle bit-fields.
			
			local member_base_type
			local member_prefix
			local member_prefix_end
			local member_suffix
			local member_suffix_end
			local member_name
			local member_type
			local member_align
			local member_size
			
			if c != 0 goto struct_redefinition
			struct = ident_list_create(8000) ; note: maximum "* 127 members in a single structure or union" C89 § 2.2.4.1
			*1out = TYPE_STRUCT
			out += 1
			*8out = struct
			out += 8
			types_bytes_used = out - types
			p += 16 ; skip opening {
			
			local offset
			offset = 0
			
			if *1struct_name == 0 goto struct_unnamed
			ident_list_add(structures, struct_name, struct)
			:struct_unnamed
			
			:struct_defn_loop
				if *1p == SYMBOL_RBRACE goto struct_defn_loop_end
				member_base_type = p
				p = type_get_base_end(member_base_type)
				:struct_defn_decl_loop ; handle each element of  int x, y[5], *z;
					member_prefix = p
					member_prefix_end = type_get_prefix_end(member_prefix)
					if *1member_prefix_end != TOKEN_IDENTIFIER goto member_no_identifier
					member_name = member_prefix_end + 8
					member_name = *8member_name
					
					c = ident_list_lookup_check(struct, member_name, 0)
					if c == 1 goto duplicate_member
					
					member_suffix = member_prefix_end + 16
					member_suffix_end = type_get_suffix_end(member_prefix)
					member_type = types_bytes_used
					
					
					parse_type_declarators(member_prefix, member_prefix_end, member_suffix, member_suffix_end)
					parse_base_type(member_base_type)
					
					; make sure struct member is aligned
					member_align = type_alignof(member_type)
					; offset = ceil(offset / align) * align
					offset += member_align - 1
					offset /= member_align
					offset *= member_align
					
					if offset ] 0xffffffff goto struct_too_large
					;putnln(offset)
					; data = (type << 32) | offset
					c = member_type < 32
					c |= offset
					ident_list_add(struct, member_name, c)
					
					member_size = type_sizeof(member_type)
					offset += member_size * is_struct ; keep offset as 0 if this is a union
					p = member_suffix_end
					if *1p == SYMBOL_SEMICOLON goto struct_defn_decl_loop_end
					if *1p != SYMBOL_COMMA goto struct_bad_declaration
					p += 16 ; skip comma
					goto struct_defn_decl_loop
					:duplicate_member
						token_error(p, .str_duplicate_member)
					:str_duplicate_member
						string Duplicate member in struct/union.
						byte 0
				:struct_defn_decl_loop_end
				p += 16 ; skip semicolon
				goto struct_defn_loop
			:struct_defn_loop_end
			out = types + types_bytes_used
			goto base_type_done
		:struct_redefinition
			token_error(p, .str_struct_redefinition)
		:str_struct_redefinition
			string struct redefinition.
			byte 0
		:struct_bad_declaration
			token_error(p, .str_struct_bad_declaration)
		:str_struct_bad_declaration
			string Bad declaration in struct.
			byte 0
		:struct_too_large
			token_error(p, .str_struct_too_large)
		:str_struct_too_large
			string struct too large (maximum is 4GB).
			byte 0
		:member_no_identifier
			; e.g. struct { int; };
			token_error(p, .str_member_no_identifier)
		:str_member_no_identifier
			string No identifier in struct member.
			byte 0
	:base_type_enum
		local q
		local expr
		
		*1out = TYPE_INT ; treat any enum as int
		out += 1
		types_bytes_used = out - types
		
		p = base_type + 16
		if *1p == SYMBOL_LBRACE goto enum_definition
		if *1p != TOKEN_IDENTIFIER goto bad_base_type ; e.g. enum int x;
		p += 16
		if *1p == SYMBOL_LBRACE goto enum_definition
		goto base_type_done ; just using an enum type, not defining it.
		:enum_definition
		local name
		local value
		value = -1 ; consider initial previous value as -1, because -1 + 1 = 0
		p += 16 ; skip opening {
		:enum_defn_loop
			if *1p == SYMBOL_RBRACE goto enum_defn_loop_end
			if *1p != TOKEN_IDENTIFIER goto bad_enum_definition
			p += 8
			name = *8p
			p += 8
			if *1p == SYMBOL_COMMA goto enum_defn_no_equals
			if *1p == SYMBOL_RBRACE goto enum_defn_no_equals
			if *1p != SYMBOL_EQ goto bad_enum_definition ; e.g. enum { X ! };
				; value provided, e.g. X = 5,
				p += 16
				depth = 0 ; parenthesis depth
				q = p
				; find matching comma/right brace 
				;  -- yes, a comma can appear in an enumerator expression, e.g.
				;     enum { X = sizeof(struct{int x, y;}) };
				; or  enum { X = (enum {A,B})3 };
				
				; find associated comma or right-brace
				:enum_comma_loop
					if depth > 0 goto enum_comma_deep
					if *1q == SYMBOL_COMMA goto enum_comma_loop_end
					if *1q == SYMBOL_RBRACE goto enum_comma_loop_end
					:enum_comma_deep
					if *1q == TOKEN_EOF goto bad_base_type
					c = *1q
					q += 16
					if c == SYMBOL_LPAREN goto enum_comma_incdepth
					if c == SYMBOL_RPAREN goto enum_comma_decdepth
					goto enum_comma_loop
					:enum_comma_incdepth
						depth += 1
						goto enum_comma_loop
					:enum_comma_decdepth
						depth -= 1
						goto enum_comma_loop
				:enum_comma_loop_end
				expr = malloc(4000)
				parse_expression(p, q, expr)
				evaluate_constant_expression(p, expr, &value)
				free(expr)
				if value < -0x80000000 goto bad_enumerator
				if value > 0x7fffffff goto bad_enumerator
				ident_list_add(enumerators, name, value)
				p = q
				if *1p == SYMBOL_RBRACE goto enum_defn_loop_end
				p += 16 ; skip ,
				goto enum_defn_loop
				:bad_enumerator
					token_error(p, .str_bad_enumerator)
				:str_bad_enumerator
					string Enumerators too large for int.
					byte 0
			:enum_defn_no_equals
				; no value provided, e.g. X,
				; the value of this enumerator is one more than the value of the last one
				value += 1
				ident_list_add(enumerators, name, value)
				if *1p == SYMBOL_RBRACE goto enum_defn_loop_end
				p += 16 ; skip ,
				goto enum_defn_loop
		:enum_defn_loop_end
		out = types + types_bytes_used ; fix stuff in case there were any types in the enumerator expressions
		goto base_type_done
		:bad_enum_definition
			token_error(base_type, .str_bad_enum_defn)
		:str_bad_enum_defn
			string Bad enum definition.
			byte 0
	:base_type_float
		*1out = TYPE_FLOAT
		out += 1
		goto base_type_done
	:base_type_void
		*1out = TYPE_VOID
		out += 1
		goto base_type_done	
	:base_type_typedef
		p = base_type + 8
		c = ident_list_lookup(typedefs, *8p)
		if c == 0 goto bad_base_type
		local len
		len = type_length(c)
		c += types
		memcpy(out, c, len)
		out += len
		goto base_type_done
	
	:bad_base_type
		token_error(base_type, .str_bad_base_type)
	:str_bad_base_type
		string Bad base type.
		byte 0

; how many bytes does it take to encode this type?
function type_length
	argument type
	local p
	local n
	p = types + type
	if *1p <= TYPE_DOUBLE goto return_1
	if *1p != TYPE_POINTER goto type_length_not_pointer
		type += 1
		n = type_length(type)
		return n + 1
	:type_length_not_pointer
	if *1p != TYPE_ARRAY goto type_length_not_array
		type += 9
		n = type_length(type)
		return n + 9
	:type_length_not_array
	if *1p == TYPE_STRUCT goto return_9
	if *1p != TYPE_FUNCTION goto type_length_not_function
		local start
		start = type
		type += 1
		:type_length_function_loop
			p = types + type
			if *1p == 0 goto type_length_function_loop_end
			type += type_length(type)
			goto type_length_function_loop
		:type_length_function_loop_end
		type += 1
		type += type_length(type)
		return type - start
	:type_length_not_function
	fputs(2, .str_type_length_bad_type)
	exit(1)
	:str_type_length_bad_type
		string Bad type passed to type_length. This shouldn't happen.
		byte 10
		byte 0
	

; returns length of type	
function type_copy_ids
	argument dest
	argument src
	local n
	n = type_length(src)
	dest += types
	src += types
	memcpy(dest, src, n)
	return n

function type_create_pointer
	argument type
	local id
	local p
	id = types_bytes_used
	p = types + id
	*1p = TYPE_POINTER
	types_bytes_used += 1
	p = id + 1
	types_bytes_used += type_copy_ids(p, type)
	return id
	
function parse_expression
	argument tokens
	argument tokens_end
	argument out
	local in
	local a
	local b
	local c
	local p
	local n
	local type
	local best
	local best_precedence
	local depth
	local value
	local first_token
	:parse_expression_top
	
	;print_tokens(tokens, tokens_end)
	
	type = out + 4
	
	if tokens == tokens_end goto empty_expression
	p = tokens + 16
	if p == tokens_end goto single_token_expression
	if *1tokens != SYMBOL_LPAREN goto parse_expression_not_entirely_in_parens
	p = tokens_end - 16
	if *1p != SYMBOL_RPAREN goto parse_expression_not_entirely_in_parens
	
	depth = 1 ; bracket depth
	p = tokens + 16
	a = tokens_end - 16 ; stop point
	:expr_paren_check_loop
		if p >= a goto expr_paren_check_loop_end
		c = *1p
		p += 16
		if c == SYMBOL_LPAREN goto expr_paren_check_loop_incdepth
		if c == SYMBOL_RPAREN goto expr_paren_check_loop_decdepth
		goto expr_paren_check_loop
		:expr_paren_check_loop_incdepth
			depth += 1
			goto expr_paren_check_loop
		:expr_paren_check_loop_decdepth
			depth -= 1
			if depth == 0 goto parse_expression_not_entirely_in_parens
			goto expr_paren_check_loop
	:expr_paren_check_loop_end
	
	; if we made it this far, the expression is entirely in parenthesis, e.g. (x+2)
	tokens += 16
	tokens_end -= 16
	goto parse_expression_top
	
	:parse_expression_not_entirely_in_parens
	
	; look for the operator with the lowest precedence not in brackets
	depth = 0 ; paren/square bracket depth
	first_token = 1
	p = tokens
	best = 0
	best_precedence = 1000
	goto expr_find_operator_loop_first
	:expr_find_operator_loop
		first_token = 0
		:expr_find_operator_loop_first
		if p >= tokens_end goto expr_find_operator_loop_end
		n = p
		c = *1p
		p += 16
		if depth > 0 goto expr_findop_not_new_best
		if depth < 0 goto expr_too_many_closing_brackets
		a = operator_precedence(n, first_token)
		n = a
		if a == 0xe0 goto select_leftmost ; ensure that the leftmost unary operator is processed first
		b = operator_right_associative(c)
		if b != 0 goto select_leftmost ; ensure that the leftmost += / -= / etc. is processed first
		goto select_rightmost
		:select_leftmost
		n += 1
		; fallthrough
		:select_rightmost
		if n > best_precedence goto expr_findop_not_new_best
		; new best!
		best = p - 16
		;putc('O)
		;putc(':)
		;putn(*1best)
		;putc(32)
		;putc('P)
		;putc(':)
		;putnln(a)
		best_precedence = a
		:expr_findop_not_new_best
		if c == SYMBOL_LPAREN goto expr_findop_incdepth
		if c == SYMBOL_RPAREN goto expr_findop_decdepth
		if c == SYMBOL_LSQUARE goto expr_findop_incdepth
		if c == SYMBOL_RSQUARE goto expr_findop_decdepth
		goto expr_find_operator_loop
		
		:expr_findop_incdepth
			depth += 1
			goto expr_find_operator_loop
		:expr_findop_decdepth
			depth -= 1
			goto expr_find_operator_loop
	:expr_find_operator_loop_end
	
	
	if best == 0 goto unrecognized_expression
	
	n = best - tokens
	
	c = *1best
		
	if best == tokens goto parse_expr_unary
	
	; it's a binary expression.
	if c == SYMBOL_PLUS_PLUS goto parse_postincrement
	if c == SYMBOL_MINUS_MINUS goto parse_postdecrement
	if c == SYMBOL_QUESTION goto parse_conditional
	*1out = binop_symbol_to_expression_type(c)
	c = *1out
	out += 8
	if c == EXPRESSION_DOT goto parse_expr_member
	if c == EXPRESSION_ARROW goto parse_expr_member
	a = out + 4 ; type of first operand
	out = parse_expression(tokens, best, out) ; first operand
	p = best + 16
	b = out + 4 ; type of second operand
	if c != EXPRESSION_SUBSCRIPT goto binary_not_subscript
	tokens_end -= 16
	if *1tokens_end != SYMBOL_RSQUARE goto unrecognized_expression
	:binary_not_subscript
	
	out = parse_expression(p, tokens_end, out) ; second operand
	
	if c == EXPRESSION_LSHIFT goto type_shift
	if c == EXPRESSION_RSHIFT goto type_shift
	if c == EXPRESSION_SUBSCRIPT goto type_subscript
	if c == EXPRESSION_EQ goto type_int
	if c == EXPRESSION_NEQ goto type_int
	if c == EXPRESSION_LEQ goto type_int
	if c == EXPRESSION_GEQ goto type_int
	if c == EXPRESSION_LT goto type_int
	if c == EXPRESSION_GT goto type_int
	if c == EXPRESSION_COMMA goto type_binary_right
	if c == EXPRESSION_EQ goto type_binary_left
	if c == EXPRESSION_ASSIGN_ADD goto type_binary_left
	if c == EXPRESSION_ASSIGN_SUB goto type_binary_left
	if c == EXPRESSION_ASSIGN_MUL goto type_binary_left
	if c == EXPRESSION_ASSIGN_DIV goto type_binary_left
	if c == EXPRESSION_ASSIGN_REMAINDER goto type_binary_left
	if c == EXPRESSION_ASSIGN_AND goto type_binary_left_integer
	if c == EXPRESSION_ASSIGN_XOR goto type_binary_left_integer
	if c == EXPRESSION_ASSIGN_OR goto type_binary_left_integer
	if c == EXPRESSION_ASSIGN_LSHIFT goto type_binary_left_integer
	if c == EXPRESSION_ASSIGN_RSHIFT goto type_binary_left_integer
	if c == EXPRESSION_LOGICAL_OR goto type_int
	if c == EXPRESSION_LOGICAL_AND goto type_int
	if c == EXPRESSION_BITWISE_AND goto type_binary_usual_integer
	if c == EXPRESSION_BITWISE_XOR goto type_binary_usual_integer
	if c == EXPRESSION_BITWISE_OR goto type_binary_usual_integer
	if c == EXPRESSION_ADD goto type_plus
	if c == EXPRESSION_SUB goto type_minus
	if c == EXPRESSION_MUL goto type_binary_usual
	if c == EXPRESSION_DIV goto type_binary_usual
	if c == EXPRESSION_REMAINDER goto type_binary_usual_integer
	
	fputs(2, .str_binop_this_shouldnt_happen)
	exit(1)
	:str_binop_this_shouldnt_happen
		string Bad binop symbol (this shouldn't happen).
		byte 10
		byte 0	
	
	:type_plus
		p = types + *4a
		if *1p == TYPE_POINTER goto type_binary_left ; pointer plus integer
		p = types + *4b
		if *1p == TYPE_POINTER goto type_binary_right ; integer plus pointer
		goto type_binary_usual
	:type_minus
		p = types + *4a
		if *1p == TYPE_POINTER goto type_minus_left_ptr
		goto type_binary_usual
		:type_minus_left_ptr
		p = types + *4b
		if *1p == TYPE_POINTER goto type_long ; pointer difference
		goto type_binary_left ; pointer minus integer
	:type_subscript
		p = types + *4a
		if *1p == TYPE_POINTER goto type_subscript_pointer
		if *1p == TYPE_ARRAY goto type_subscript_array
		goto subscript_bad_type
		:type_subscript_pointer
			*4type = *4a + 1
			return out
		:type_subscript_array
			*4type = *4a + 9
			return out
		:subscript_bad_type
			token_error(tokens, .str_subscript_bad_type)
		:str_subscript_bad_type
			string Subscript of non-pointer type.
			byte 0
	; apply the "usual conversions"
	:type_binary_usual
		*4type = expr_binary_type_usual_conversions(tokens, *4a, *4b)
		return out
	; like type_binary_usual, but the operands must be integers
	:type_binary_usual_integer
		*4type = expr_binary_type_usual_conversions(tokens, *4a, *4b)
		p = types + *4type
		if *1p >= TYPE_FLOAT goto expr_binary_bad_types
		return out
	:type_binary_left_integer
		p = types + *4a
		if *1p >= TYPE_FLOAT goto expr_binary_bad_types
		p = types + *4b
		if *1p >= TYPE_FLOAT goto expr_binary_bad_types
		goto type_binary_left
	:type_binary_left
		*4type = *4a
		return out
	:type_binary_right
		*4type = *4b
		return out
	:type_shift
		p = types + *4a
		if *1p >= TYPE_FLOAT goto expr_binary_bad_types
		p = types + *4b
		if *1p >= TYPE_FLOAT goto expr_binary_bad_types
		*4type = type_promotion(*4a)
		return out
	; the type here is just int
	:type_int
		*4type = TYPE_INT
		return out
	:type_long
		*4type = TYPE_LONG
		return out
	:expr_binary_bad_types
		bad_types_to_operator(tokens, *4a, *4b)
	
	
	:parse_expr_unary
		if c == KEYWORD_SIZEOF goto parse_sizeof
		*1out = unary_op_to_expression_type(c)
		c = *1out
		if c == EXPRESSION_CAST goto parse_cast
		out += 8
		a = out + 4 ; type of operand
		p = tokens + 16
		out = parse_expression(p, tokens_end, out)
		p = types + *4a
		if c == EXPRESSION_BITWISE_NOT goto unary_type_integral
		if c == EXPRESSION_UNARY_PLUS goto unary_type_promote
		if c == EXPRESSION_UNARY_MINUS goto unary_type_promote
		if c == EXPRESSION_LOGICAL_NOT goto unary_type_logical_not
		if c == EXPRESSION_ADDRESS_OF goto unary_address_of
		if c == EXPRESSION_DEREFERENCE goto unary_dereference
		if c == EXPRESSION_PRE_INCREMENT goto unary_type_arithmetic_nopromote
		if c == EXPRESSION_PRE_DECREMENT goto unary_type_arithmetic_nopromote
		fputs(2, .str_unop_this_shouldnt_happen)
		exit(1)
		:str_unop_this_shouldnt_happen
			string Bad unary symbol (this shouldn't happen).
			byte 10
			byte 0
	:parse_cast
		local cast_base_type
		local cast_prefix
		local cast_suffix
		local cast_suffix_end
		
		cast_base_type = best + 16
		cast_prefix = type_get_base_end(cast_base_type)
		cast_suffix = type_get_prefix_end(cast_prefix)
		cast_suffix_end = type_get_suffix_end(cast_prefix)
		
		a = types_bytes_used
		
		parse_type_declarators(cast_prefix, cast_suffix, cast_suffix, cast_suffix_end)
		parse_base_type(cast_base_type)
		
		p = cast_suffix_end
		
		if *1p != SYMBOL_RPAREN goto bad_cast ; e.g. (int ,)5
		out += 4
		*4out = a
		out += 4
		p += 16
		out = parse_expression(p, tokens_end, out)
		return out
		:bad_cast
			token_error(tokens, .str_bad_cast)
		:str_bad_cast
			string Bad cast.
			byte 0		
	:unary_address_of
		*4type = type_create_pointer(*4a)
		return out
	:unary_dereference
		if *1p != TYPE_POINTER goto unary_bad_type
		*4type = *4a + 1
		return out
	:unary_type_logical_not
		if *1p > TYPE_POINTER goto unary_bad_type
		*4type = TYPE_INT
		return out
	:unary_type_integral
		if *1p >= TYPE_FLOAT goto unary_bad_type
		goto unary_type_promote
	:unary_type_promote
		if *1p > TYPE_DOUBLE goto unary_bad_type
		*4type = type_promotion(*4a)
		return out
	:unary_type_arithmetic_nopromote
		if *1p > TYPE_DOUBLE goto unary_bad_type
		*4type = *4a
		return out
	:unary_bad_type
		fprint_token_location(1, tokens)
		puts(.str_unary_bad_type)
		print_type(*4a)
		putc(10)
		exit(1)
	:str_unary_bad_type
		string : Bad type for unary operator:
		byte 32
		byte 0
	
	:parse_sizeof
		local sizeof_base_type
		local sizeof_prefix
		local sizeof_suffix
		local sizeof_suffix_end
		
		*1out = EXPRESSION_CONSTANT_INT
		out += 4
		*1out = TYPE_UNSIGNED_LONG
		out += 4
		p = best + 16
		if *1p != SYMBOL_LPAREN goto parse_sizeof_expr
		p += 16
		b = token_is_type(p)
		if b == 0 goto parse_sizeof_expr
			; it's a type, e.g. sizeof(int)
			sizeof_base_type = p
			sizeof_prefix = type_get_base_end(sizeof_base_type)
			sizeof_suffix = type_get_prefix_end(sizeof_prefix)
			sizeof_suffix_end = type_get_suffix_end(sizeof_prefix)
			p = sizeof_suffix_end
			a = types_bytes_used
			parse_type_declarators(sizeof_prefix, sizeof_suffix, sizeof_suffix, sizeof_suffix_end)
			parse_base_type(sizeof_base_type)
			if *1p != SYMBOL_RPAREN goto bad_expression ; e.g. sizeof(int ,)
			*8out = type_sizeof(a)
			goto parse_sizeof_finish
		:parse_sizeof_expr
			; it's an expression, e.g. sizeof(x+3)
			local temp
			temp = malloc(4000)
			p = best + 16
			parse_expression(p, tokens_end, temp)
			p = temp + 4
			*8out = type_sizeof(*4p)
			free(temp)
		:parse_sizeof_finish
		out += 8
		return out
		
	:parse_expr_member ; -> or .
		p = best + 16
		if *1p != TOKEN_IDENTIFIER goto bad_expression
		
		a = out + 4 ; pointer to type ID
		out = parse_expression(tokens, best, out)
		a = types + *4a
		if c == EXPRESSION_DOT goto type_dot
			if *1a != TYPE_POINTER goto arrow_non_pointer
			a += 1
		:type_dot
		if *1a != TYPE_STRUCT goto member_non_struct
		a += 1
		a = *8a ; pointer to struct data
		p += 8
		c = ident_list_lookup(a, *8p)
		if c == 0 goto member_not_in_struct
		*8out = c & 0xffffffff ; offset
		*4type = c > 32 ; type
		out += 8
		p += 8
		if p != tokens_end goto bad_expression ; e.g. foo->bar hello
		return out
		:arrow_non_pointer
			token_error(p, .str_arrow_non_pointer)
		:str_arrow_non_pointer
			string Trying to use -> operator on a non-pointer type.
			byte 0
		:member_non_struct
			token_error(p, .str_member_non_struct)
		:str_member_non_struct
			string Trying to access member of something other than a (complete) structure/union.
			byte 0
		:member_not_in_struct
			token_error(p, .str_member_not_in_struct)
		:str_member_not_in_struct
			string Trying to access non-existent member of structure or union.
			byte 0
	:parse_conditional
		depth = 0 ; bracket depth
		n = 0 ; ? : depth
		; find : associated with this ?
		p = best + 16
		:parse_conditional_loop
			if p >= tokens_end goto bad_expression
			if *1p == SYMBOL_QUESTION goto parse_cond_incn
			if *1p == SYMBOL_COLON goto parse_cond_decn
			if *1p == SYMBOL_LPAREN goto parse_cond_incdepth
			if *1p == SYMBOL_RPAREN goto parse_cond_decdepth
			if *1p == SYMBOL_LSQUARE goto parse_cond_incdepth
			if *1p == SYMBOL_RSQUARE goto parse_cond_decdepth
			:parse_cond_cont
			p += 16
			goto parse_conditional_loop
			
			:parse_cond_incdepth
				depth += 1
				goto parse_cond_cont
			:parse_cond_decdepth
				depth -= 1
				goto parse_cond_cont
			:parse_cond_incn
				n += 1
				goto parse_cond_cont
			:parse_cond_decn
				n -= 1
				if n >= 0 goto parse_cond_cont
				if depth > 0 goto parse_cond_cont
		; okay, q now points to the :
		*1out = EXPRESSION_CONDITIONAL
		out += 8
		out = parse_expression(tokens, best, out)
		a = out + 4 ; type of left branch of conditional
		best += 16
		out = parse_expression(best, p, out)
		b = out + 4 ; type of right branch of conditional
		p += 16
		out = parse_expression(p, tokens_end, out)
		p = types + *4a
		if *1p == TYPE_STRUCT goto parse_cond_ltype
		if *1p == TYPE_VOID goto parse_cond_ltype
		if *1p == TYPE_POINTER goto parse_cond_ltype ; @NONSTANDARD: we don't handle  sizeof *(0 ? (void*)0 : "hello")  correctly--it should be 1 (a standard-compliant implementation is annoyingly complicated)
		*4type = expr_binary_type_usual_conversions(tokens, *4a, *4b)
		return out
		:parse_cond_ltype
		; no conversions
		*4type = *4a
		return out
	:parse_postincrement
		*1out = EXPRESSION_POST_INCREMENT
		p = tokens_end - 16
		if *1p != SYMBOL_PLUS_PLUS goto bad_expression ; e.g. a ++ b
		out += 8
		a = out + 4 ; type of operand 
		out = parse_expression(tokens, p, out)
		*4type = *4a ; this expression's type is the operand's type (yes even for types smaller than int)
		return out
		
	:parse_postdecrement
		*1out = EXPRESSION_POST_DECREMENT
		p = tokens_end - 16
		if *1p != SYMBOL_MINUS_MINUS goto bad_expression ; e.g. a -- b
		out += 8
		a = out + 4 ; type of operand 
		out = parse_expression(tokens, p, out)
		*4type = *4a ; type of this = type of operand
		return out
	
	:single_token_expression
		in = tokens
		c = *1in
		if c == TOKEN_CONSTANT_INT goto expression_integer
		if c == TOKEN_CONSTANT_CHAR goto expression_integer ; character constants are basically the same as integer constants
		if c == TOKEN_CONSTANT_FLOAT goto expression_float
		if c == TOKEN_STRING_LITERAL goto expression_string_literal
		if c == TOKEN_IDENTIFIER goto expression_identifier
		goto unrecognized_expression
		
	:expression_identifier
		in += 8
		a = *8in
		in += 8
		; check if it's an enumerator
		c = ident_list_lookup_check(enumerators, a, &n)
		if c == 0 goto not_enumerator
			; it is an enumerator
			*1out = EXPRESSION_CONSTANT_INT
			out += 4
			*4out = TYPE_INT
			out += 4
			*8out = n
			out += 8
			return out
		:not_enumerator
		; @TODO: check if it's a local variable
		
		; check if it's a global
		c = ident_list_lookup(global_variables, a)
		if c == 0 goto not_global
			; it is a global variable
			*1out = EXPRESSION_GLOBAL_VARIABLE
			out += 4
			*4out = c > 32 ; extract type
			out += 4
			*8out = c & 0xffffffff ; extract address
			out += 8
			return out
		:not_global
		
		in -= 16
		token_error(in, .str_undeclared_variable)
		:str_undeclared_variable
			string Undeclared variable.
			byte 0
	:expression_integer
		*1out = EXPRESSION_CONSTANT_INT
		p = in + 8
		value = *8p
		p = out + 8
		*8p = value
		
		p = in + 1
		a = int_suffix_to_type(*1p) ; what the suffix says the type should be
		b = int_value_to_type(value) ; what the value says the type should be (if the value is too large to fit in int)
		a = max_signed(a, b) ; take the maximum of the two types
		; make sure that if the integer has a u suffix, the type will be unsigned
		a &= b | 0xfe
		p = out + 4
		*4p = a
		in += 16
		out += 16
		return out
	
	:expression_float
		*1out = EXPRESSION_CONSTANT_FLOAT
		p = in + 8
		value = *8p
		p = out + 8
		*8p = value
		
		p = in + 1
		a = float_suffix_to_type(*1p)
		
		p = out + 4
		*4p = a
		
		in += 16
		out += 16
		return out
		
	:expression_string_literal
		*1out = EXPRESSION_CONSTANT_INT
		p = in + 8
		value = *8p
		p = out + 8
		*8p = value
		
		; must be char*
		p = out + 4
		*4p = TYPE_POINTER_TO_CHAR
		
		in += 16
		out += 16
		return out
	
	
	:empty_expression
		token_error(tokens, .str_empty_expression)
	:str_empty_expression
		string Empty expression.
		byte 0
	:bad_expression
		token_error(tokens, .str_bad_expression)
	:str_bad_expression
		string Bad expression.
		byte 0
	:unrecognized_expression
		token_error(tokens, .str_unrecognized_expression)
	:str_unrecognized_expression
		string Unrecognized expression.
		byte 0
	:expr_too_many_closing_brackets
		token_error(tokens, .str_too_many_closing_brackets)
	:str_too_many_closing_brackets
		string Too many closing brackets.
		byte 0
:return_type_int
	return TYPE_INT
:return_type_long
	return TYPE_LONG
:return_type_unsigned_int
	return TYPE_UNSIGNED_INT
:return_type_unsigned_long
	return TYPE_UNSIGNED_LONG
:return_type_float
	return TYPE_FLOAT
:return_type_double
	return TYPE_DOUBLE

function type_sizeof
	argument type
	local p
	local c
	p = types + type
	c = *1p
	if c == TYPE_CHAR goto return_1
	if c == TYPE_UNSIGNED_CHAR goto return_1
	if c == TYPE_SHORT goto return_2
	if c == TYPE_UNSIGNED_SHORT goto return_2
	if c == TYPE_INT goto return_4
	if c == TYPE_UNSIGNED_INT goto return_4
	if c == TYPE_LONG goto return_8
	if c == TYPE_UNSIGNED_LONG goto return_8
	if c == TYPE_FLOAT goto return_4
	if c == TYPE_DOUBLE goto return_8
	if c == TYPE_VOID goto return_1
	if c == TYPE_POINTER goto return_8
	if c == TYPE_FUNCTION goto return_8
	if c == TYPE_ARRAY goto sizeof_array
	if c == TYPE_STRUCT goto sizeof_struct
	
	fputs(2, .str_sizeof_bad)
	exit(1)
	:str_sizeof_bad
		string type_sizeof bad type.
		byte 10
		byte 0
	
	:sizeof_array
		local n
		p += 1
		n = *8p
		p += 8
		p -= types
		c = type_sizeof(p)
		return n * c

	:sizeof_struct
		; size of struct is  offset of last member + size of last member,
		;  rounded up to fit alignment
		local align
		local offset
		local member
		align = type_alignof(type)
		p += 1
		member = *8p
		:sizeof_struct_loop
			if *1member == 0 goto sizeof_struct_loop_end
			member = memchr(member, 0) ; don't care about name
			member += 1 ; skip null terminator
			c = *8member
			member += 8
			offset = c & 0xffffffff
			c >= 32 ; extract type
			offset += type_sizeof(c)
			goto sizeof_struct_loop
		:sizeof_struct_loop_end
		
		offset += align - 1
		offset /= align
		offset *= align
		
		return offset

function type_alignof
	argument type
	local p
	local c
	p = types + type
	c = *1p
	if c == TYPE_CHAR goto return_1
	if c == TYPE_UNSIGNED_CHAR goto return_1
	if c == TYPE_SHORT goto return_2
	if c == TYPE_UNSIGNED_SHORT goto return_2
	if c == TYPE_INT goto return_4
	if c == TYPE_UNSIGNED_INT goto return_4
	if c == TYPE_LONG goto return_8
	if c == TYPE_UNSIGNED_LONG goto return_8
	if c == TYPE_FLOAT goto return_4
	if c == TYPE_DOUBLE goto return_8
	if c == TYPE_VOID goto return_1
	if c == TYPE_POINTER goto return_8
	if c == TYPE_FUNCTION goto return_8
	if c == TYPE_ARRAY goto alignof_array
	if c == TYPE_STRUCT goto alignof_struct
	
	fputs(2, .str_alignof_bad)
	exit(1)
	:str_alignof_bad
		string type_alignof bad type.
		byte 10
		byte 0
	:alignof_struct
		; alignment of struct is max alignment of members
		local align
		local member
		local a
		align = 1
		p += 1
		member = *8p
		:alignof_struct_loop
			if *1member == 0 goto alignof_struct_loop_end
			member = memchr(member, 0) ; don't care about name
			member += 1 ; skip null terminator
			c = *8member
			member += 8
			c >= 32 ; ignore offset
			a = type_alignof(c)
			if a <= align goto alignof_struct_loop
			align = a
			goto alignof_struct_loop
		:alignof_struct_loop_end
		return align
	:alignof_array
		p = type + 9 ; skip TYPE_ARRAY and size
		return type_alignof(p)

; evaluate an expression which can be the size of an array, e.g.
;    enum { A, B, C };
;    int x[A * sizeof(float) + 3 << 5];
; @NONSTANDARD: doesn't handle floats, but really why would you use floats in an array size
;                 e.g.   SomeType x[(int)3.3];
; this is also used for #if evaluation
; token is used for error messages (e.g. if this "constant" expression is *x or something)
; NOTE: this returns the end of the expression, not the value (which is stored in *8p_value)
function evaluate_constant_expression
	argument token
	argument expr
	argument p_value
	local a
	local b
	local c
	local p
	local mask
	local type
	
	type = expr + 4
	type = *4type
	
	c = *1expr
	
	if c == EXPRESSION_CONSTANT_INT goto eval_constant_int
	if c == EXPRESSION_UNARY_PLUS goto eval_unary_plus
	if c == EXPRESSION_UNARY_MINUS goto eval_unary_minus
	if c == EXPRESSION_BITWISE_NOT goto eval_bitwise_not
	if c == EXPRESSION_LOGICAL_NOT goto eval_logical_not
	if c == EXPRESSION_CAST goto eval_cast
	if c == EXPRESSION_ADD goto eval_add
	if c == EXPRESSION_SUB goto eval_sub
	if c == EXPRESSION_MUL goto eval_mul
	if c == EXPRESSION_DIV goto eval_div
	if c == EXPRESSION_REMAINDER goto eval_remainder
	if c == EXPRESSION_LSHIFT goto eval_lshift
	if c == EXPRESSION_RSHIFT goto eval_rshift
	if c == EXPRESSION_EQ goto eval_eq
	if c == EXPRESSION_NEQ goto eval_neq
	if c == EXPRESSION_LT goto eval_lt
	if c == EXPRESSION_GT goto eval_gt
	if c == EXPRESSION_LEQ goto eval_leq
	if c == EXPRESSION_GEQ goto eval_geq
	if c == EXPRESSION_BITWISE_AND goto eval_bitwise_and
	if c == EXPRESSION_BITWISE_OR goto eval_bitwise_or
	if c == EXPRESSION_BITWISE_XOR goto eval_bitwise_xor
	if c == EXPRESSION_LOGICAL_AND goto eval_logical_and
	if c == EXPRESSION_LOGICAL_OR goto eval_logical_or
	if c == EXPRESSION_CONDITIONAL goto eval_conditional
	
	
	token_error(token, .str_eval_bad_exprtype)
	
	:str_eval_bad_exprtype
		string Can't evaluate constant expression.
		byte 0
	:eval_cast
		p = types + type
		c = *1p
		if c == TYPE_VOID goto eval_cast_bad_type
		; @NONSTANDARD: we don't support, for example,  int x[(int)(float)5];
		if c == TYPE_FLOAT goto eval_cast_bad_type
		if c == TYPE_DOUBLE goto eval_cast_bad_type
		if c > TYPE_POINTER goto eval_cast_bad_type
		expr += 8
		expr = evaluate_constant_expression(token, expr, p_value)
		goto eval_fit_to_type
		:eval_cast_bad_type
			token_error(token, .str_eval_cast_bad_type)
		:str_eval_cast_bad_type
			string Bad type for constant cast (note: floating-point casts are not supported even though they are standard).
			byte 0
	:eval_constant_int
		expr += 8
		*8p_value = *8expr
		expr += 8
		return expr
	:eval_unary_plus
		expr += 8
		expr = evaluate_constant_expression(token, expr, p_value)
		return expr
	:eval_unary_minus
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		*8p_value = 0 - a
		goto eval_fit_to_type
	:eval_bitwise_not
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		*8p_value = ~a
		goto eval_fit_to_type
	:eval_logical_not
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		if a == 0 goto eval_value_1
		goto eval_value_0
	:eval_add
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		expr = evaluate_constant_expression(token, expr, &b)
		*8p_value = a + b
		goto eval_fit_to_type
	:eval_sub
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		expr = evaluate_constant_expression(token, expr, &b)
		*8p_value = a - b
		goto eval_fit_to_type
	:eval_mul
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		expr = evaluate_constant_expression(token, expr, &b)
		*8p_value = a * b
		goto eval_fit_to_type
	:eval_div
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		expr = evaluate_constant_expression(token, expr, &b)
		p = types + type
		if *1p == TYPE_UNSIGNED_LONG goto eval_div_unsigned
			; division is signed or uses a small type, so we can use 64-bit signed division
			*8p_value = a / b
			goto eval_fit_to_type
		:eval_div_unsigned
			; must use unsigned division
			divmod_unsigned(a, b, p_value, &a)
			goto eval_fit_to_type
	:eval_remainder
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		expr = evaluate_constant_expression(token, expr, &b)
		p = types + type
		if *1p == TYPE_UNSIGNED_LONG goto eval_rem_unsigned
			*8p_value = a % b
			goto eval_fit_to_type
		:eval_rem_unsigned
			divmod_unsigned(a, b, &a, p_value)
			goto eval_fit_to_type
	:eval_lshift
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		expr = evaluate_constant_expression(token, expr, &b)
		*8p_value = a < b
		goto eval_fit_to_type
	:eval_rshift
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		expr = evaluate_constant_expression(token, expr, &b)
		p = types + type
		p = *1p
		p &= 1 ; signed types are odd
		if p == 1 goto eval_signed_rshift
			*8p_value = a > b
			goto eval_fit_to_type
		:eval_signed_rshift
			local v
			mask = a > 63 ; sign bit
			
			; sign extension
			mask <= b
			mask -= 1
			mask <= 64 - b
			
			v = a > b
			v += mask
			*8p_value = v
			goto eval_fit_to_type
	
	; comparison masks:
	;   1 = less than
	;   2 = equal to
	;   4 = greater than
	; e.g. not-equal is 1|4 = 5 because not equal = less than or greater than
	:eval_eq
		mask = 2
		goto eval_comparison
	:eval_neq
		mask = 5
		goto eval_comparison
	:eval_lt
		mask = 1
		goto eval_comparison
	:eval_gt
		mask = 4
		goto eval_comparison
	:eval_leq
		mask = 3
		goto eval_comparison
	:eval_geq
		mask = 6
		goto eval_comparison
	:eval_comparison
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		expr = evaluate_constant_expression(token, expr, &b)
		
		p = types + type
		p = *1p
		p &= 1
		
		if a == b goto eval_comparison_eq
		
		; for checking < and >, we care about whether a and b are signed
		if p == 1 goto eval_signed_comparison
			if a ] b goto eval_comparison_gt
			goto eval_comparison_lt
		:eval_signed_comparison
			if a > b goto eval_comparison_gt
			goto eval_comparison_lt
		
		:eval_comparison_eq
			; a == b
			mask &= 2
			goto eval_comparison_done
		:eval_comparison_lt
			; a < b
			mask &= 1
			goto eval_comparison_done
		:eval_comparison_gt
			; a > b
			mask &= 4
			goto eval_comparison_done
		:eval_comparison_done
			if mask != 0 goto eval_value_1
			goto eval_value_0
	:eval_bitwise_and
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		expr = evaluate_constant_expression(token, expr, &b)
		*8p_value = a & b
		goto eval_fit_to_type
	:eval_bitwise_or
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		expr = evaluate_constant_expression(token, expr, &b)
		*8p_value = a | b
		goto eval_fit_to_type
	:eval_bitwise_xor
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		expr = evaluate_constant_expression(token, expr, &b)
		*8p_value = a ^ b
		goto eval_fit_to_type
	:eval_logical_and
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		if a == 0 goto eval_value_0
		expr = evaluate_constant_expression(token, expr, &b)
		if b == 0 goto eval_value_0
		goto eval_value_1
	:eval_logical_or
		expr += 8
		expr = evaluate_constant_expression(token, expr, &a)
		if a != 0 goto eval_value_1
		expr = evaluate_constant_expression(token, expr, &b)
		if b != 0 goto eval_value_1
		goto eval_value_0
	:eval_conditional
		expr += 8
		expr = evaluate_constant_expression(token, expr, &mask)
		expr = evaluate_constant_expression(token, expr, &a)
		expr = evaluate_constant_expression(token, expr, &b)
		if mask == 0 goto eval_conditional_b
			*8p_value = a
			goto eval_fit_to_type
		:eval_conditional_b
			*8p_value = b
			goto eval_fit_to_type
		
	:eval_fit_to_type
	*8p_value = fit_to_type(*8p_value, type)
	return expr
	:eval_value_0
	*8p_value = 0
	return expr
	:eval_value_1
	*8p_value = 1
	return expr
	

; value is the output of some arithmetic expression; correct it to be within the range of type.
function fit_to_type
	argument value
	argument type
	local c
	local s
	c = types + type
	c = *1c
	if c == TYPE_CHAR goto fit_to_type_char
	if c == TYPE_UNSIGNED_CHAR goto fit_to_type_uchar
	if c == TYPE_SHORT goto fit_to_type_short
	if c == TYPE_UNSIGNED_SHORT goto fit_to_type_ushort
	if c == TYPE_INT goto fit_to_type_int
	if c == TYPE_UNSIGNED_INT goto fit_to_type_uint
	if c == TYPE_LONG goto fit_to_type_long
	if c == TYPE_UNSIGNED_LONG goto fit_to_type_ulong
	if c == TYPE_POINTER goto fit_to_type_ulong
	fputs(2, .str_bad_fit_to_type)
	exit(1)
	:str_bad_fit_to_type
		string Bad type passed to fit_to_type.
		byte 10
		byte 0
	; yes, signed integer overflow is undefined behavior and
	; casting to a signed integer is implementation-defined;
	;   i'm going to play it safe and implement it properly
	:fit_to_type_char
		value &= 0xff
		s = value > 7 ; sign bit
		value += s * 0xffffffffffffff00 ; sign-extend
		return value
	:fit_to_type_uchar
		value &= 0xff
		return value
	:fit_to_type_short
		value &= 0xffff
		s = value > 15 ; sign bit
		value += s * 0xffffffffffff0000 ; sign-extend
		return value
	:fit_to_type_ushort
		value &= 0xffff
		return value
	:fit_to_type_int
		value &= 0xffffffff
		s = value > 31 ; sign bit
		value += s * 0xffffffff00000000 ; sign-extend
		return value
	:fit_to_type_uint
		value &= 0xffffffff
		return value
	:fit_to_type_long
	:fit_to_type_ulong
		return value
; the "usual conversions" for binary operators, as the C standard calls it
function expr_binary_type_usual_conversions
	argument token ; for errors
	argument type1
	argument type2
	
	local ptype1
	local ptype2
	local kind1
	local kind2
	
	if type1 == 0 goto return_0
	if type2 == 0 goto return_0
	
	ptype1 = types + type1
	ptype2 = types + type2
	
	kind1 = *1ptype1
	kind2 = *1ptype2
	
	if kind1 > TYPE_DOUBLE goto usual_bad_types_to_operator
	if kind2 > TYPE_DOUBLE goto usual_bad_types_to_operator
	
	; "if either operand has type double, the other operand is converted to double"
	if kind1 == TYPE_DOUBLE goto return_type_double
	if kind2 == TYPE_DOUBLE goto return_type_double
	; "if either operand has type float, the other operand is converted to float"
	if kind1 == TYPE_FLOAT goto return_type_float
	if kind2 == TYPE_FLOAT goto return_type_float
	; "If either operand has type unsigned long int, the other operand is converted to unsigned long int"
	if kind1 == TYPE_UNSIGNED_LONG goto return_type_unsigned_long
	if kind2 == TYPE_UNSIGNED_LONG goto return_type_unsigned_long
	; "if either operand has type long int, the other operand is converted to long int"
	if kind1 == TYPE_LONG goto return_type_long
	if kind2 == TYPE_LONG goto return_type_long
	; "if either operand has type unsigned int, the other operand is converted to unsigned int."
	if kind1 == TYPE_UNSIGNED_INT goto return_type_unsigned_int
	if kind2 == TYPE_UNSIGNED_INT goto return_type_unsigned_int
	; "Otherwise, both operands have type int."
	goto return_type_int
	
	:str_space_and_space
		string  and
		byte 32
		byte 0
	:usual_bad_types_to_operator
		bad_types_to_operator(token, type1, type2)

function bad_types_to_operator
	argument token
	argument type1
	argument type2
	
	fprint_token_location(1, token)
	puts(.str_bad_types_to_operator)
	print_type(type1)
	puts(.str_space_and_space)
	print_type(type2)
	putc(10)
	exit(1)
	:str_bad_types_to_operator
		string : Bad types to operator:
		byte 32
		byte 0

function type_promotion
	argument type
	local p
	p = types + type
	if *1p < TYPE_INT goto return_type_int
	return type

; return precedence of given operator token, or 0xffff if not an operator
function operator_precedence
	argument token
	argument is_first
	local op
	local b
	
	if is_first != 0 goto operator_precedence_unary
	
	; if an operator is preceded by another, it must be a unary operator, e.g.
	;   in 5 + *x, * is a unary operator
	op = token - 16
	op = *1op
	if op == SYMBOL_RPAREN goto figre_out_rparen_arity
	op = is_operator(op)
	
	; if an operator is immediately followed by another (including lparen), the second must be 
	; unary.
	if op != 0 goto operator_precedence_unary
	
	:operator_precedence_binary
	op = *1token
	
	; see "C OPERATOR PRECEDENCE" in constants.b
	if op == SYMBOL_COMMA goto return_0x10
	if op == SYMBOL_EQ goto return_0x20
	if op == SYMBOL_PLUS_EQ goto return_0x20
	if op == SYMBOL_MINUS_EQ goto return_0x20
	if op == SYMBOL_TIMES_EQ goto return_0x20
	if op == SYMBOL_DIV_EQ goto return_0x20
	if op == SYMBOL_PERCENT_EQ goto return_0x20
	if op == SYMBOL_LSHIFT_EQ goto return_0x20
	if op == SYMBOL_RSHIFT_EQ goto return_0x20
	if op == SYMBOL_AND_EQ goto return_0x20
	if op == SYMBOL_OR_EQ goto return_0x20
	if op == SYMBOL_XOR_EQ goto return_0x20
	if op == SYMBOL_QUESTION goto return_0x30
	if op == SYMBOL_OR_OR goto return_0x40
	if op == SYMBOL_AND_AND goto return_0x50
	if op == SYMBOL_OR goto return_0x60
	if op == SYMBOL_XOR goto return_0x70
	if op == SYMBOL_AND goto return_0x80
	if op == SYMBOL_EQ_EQ goto return_0x90
	if op == SYMBOL_NOT_EQ goto return_0x90
	if op == SYMBOL_LT goto return_0xa0
	if op == SYMBOL_GT goto return_0xa0
	if op == SYMBOL_LT_EQ goto return_0xa0
	if op == SYMBOL_GT_EQ goto return_0xa0
	if op == SYMBOL_LSHIFT goto return_0xb0
	if op == SYMBOL_RSHIFT goto return_0xb0
	if op == SYMBOL_PLUS goto return_0xc0
	if op == SYMBOL_MINUS goto return_0xc0
	if op == SYMBOL_TIMES goto return_0xd0
	if op == SYMBOL_DIV goto return_0xd0
	if op == SYMBOL_PERCENT goto return_0xd0
	if op == SYMBOL_ARROW goto return_0xf0
	if op == SYMBOL_DOT goto return_0xf0
	if op == SYMBOL_LPAREN goto return_0xf0 ; function call
	if op == SYMBOL_LSQUARE goto return_0xf0 ; subscript
	if op == SYMBOL_PLUS_PLUS goto return_0xf0
	if op == SYMBOL_MINUS_MINUS goto return_0xf0
	
	return 0xffff
	
	:operator_precedence_unary
	op = *1token
	
	if op == KEYWORD_SIZEOF goto return_0xe0
	if op == SYMBOL_PLUS_PLUS goto return_0xe0
	if op == SYMBOL_MINUS_MINUS goto return_0xe0
	if op == SYMBOL_AND goto return_0xe0
	if op == SYMBOL_TIMES goto return_0xe0
	if op == SYMBOL_PLUS goto return_0xe0
	if op == SYMBOL_MINUS goto return_0xe0
	if op == SYMBOL_TILDE goto return_0xe0
	if op == SYMBOL_NOT goto return_0xe0
	if op == SYMBOL_LPAREN goto cast_precedence
	
	return 0xffff
	:cast_precedence
	; make sure this actually is a cast
	;   this is necessary to handle both
	;         - (x)->something
	;     and - (int)x->something
	;   correctly (in the first case, the arrow is the top-level operator, but in the second, the cast is)
	token += 16
	b = token_is_type(token)
	if b == 0 goto return_0xffff
	goto return_0xd8 ; it's a cast
	
	:figre_out_rparen_arity
	; given that the token before this one is a right-parenthesis, figure out if
	; this is a unary or binary operator. this is (annoyingly) necessary, because:
	;  (int)-x;   /* cast processed first */
	;  (y)-x;     /* subtraction processed first */
	local p
	p = token - 16
	token_reverse_to_matching_lparen(&p)
	p += 16
	b = token_is_type(p)
	if b != 0 goto operator_precedence_unary ; e.g. (int)-x;	
	goto operator_precedence_binary ; e.g. (y)-x;
	
function unary_op_to_expression_type
	argument op
	if op == SYMBOL_PLUS_PLUS goto return_EXPRESSION_PRE_INCREMENT
	if op == SYMBOL_MINUS_MINUS goto return_EXPRESSION_PRE_DECREMENT
	if op == SYMBOL_AND goto return_EXPRESSION_ADDRESS_OF
	if op == SYMBOL_TIMES goto return_EXPRESSION_DEREFERENCE
	if op == SYMBOL_PLUS goto return_EXPRESSION_UNARY_PLUS
	if op == SYMBOL_MINUS goto return_EXPRESSION_UNARY_MINUS
	if op == SYMBOL_TILDE goto return_EXPRESSION_BITWISE_NOT
	if op == SYMBOL_NOT goto return_EXPRESSION_LOGICAL_NOT
	if op == SYMBOL_LPAREN goto return_EXPRESSION_CAST
	return 0

:return_EXPRESSION_PRE_INCREMENT
	return EXPRESSION_PRE_INCREMENT
:return_EXPRESSION_PRE_DECREMENT
	return EXPRESSION_PRE_INCREMENT
:return_EXPRESSION_ADDRESS_OF
	return EXPRESSION_ADDRESS_OF
:return_EXPRESSION_DEREFERENCE
	return EXPRESSION_DEREFERENCE
:return_EXPRESSION_UNARY_PLUS
	return EXPRESSION_UNARY_PLUS
:return_EXPRESSION_UNARY_MINUS
	return EXPRESSION_UNARY_MINUS
:return_EXPRESSION_BITWISE_NOT
	return EXPRESSION_BITWISE_NOT
:return_EXPRESSION_LOGICAL_NOT
	return EXPRESSION_LOGICAL_NOT
:return_EXPRESSION_CAST
	return EXPRESSION_CAST

; is this operator right-associative? most C operators are left associative,
; but += / -= / etc. are not
function operator_right_associative
	argument op
	if op == SYMBOL_QUESTION goto return_1
	if op < SYMBOL_EQ goto return_0
	if op > SYMBOL_OR_EQ goto return_0
	goto return_1

:binop_table
	byte SYMBOL_COMMA
	byte EXPRESSION_COMMA
	byte SYMBOL_EQ
	byte EXPRESSION_ASSIGN
	byte SYMBOL_PLUS_EQ
	byte EXPRESSION_ASSIGN_ADD
	byte SYMBOL_MINUS_EQ
	byte EXPRESSION_ASSIGN_SUB
	byte SYMBOL_TIMES_EQ
	byte EXPRESSION_ASSIGN_MUL
	byte SYMBOL_DIV_EQ
	byte EXPRESSION_ASSIGN_DIV
	byte SYMBOL_PERCENT_EQ
	byte EXPRESSION_ASSIGN_REMAINDER
	byte SYMBOL_LSHIFT_EQ
	byte EXPRESSION_ASSIGN_LSHIFT
	byte SYMBOL_RSHIFT_EQ
	byte EXPRESSION_ASSIGN_RSHIFT
	byte SYMBOL_AND_EQ
	byte EXPRESSION_ASSIGN_AND
	byte SYMBOL_OR_EQ
	byte EXPRESSION_ASSIGN_OR
	byte SYMBOL_XOR_EQ
	byte EXPRESSION_ASSIGN_XOR
	byte SYMBOL_OR_OR
	byte EXPRESSION_LOGICAL_OR
	byte SYMBOL_AND_AND
	byte EXPRESSION_LOGICAL_AND
	byte SYMBOL_OR
	byte EXPRESSION_BITWISE_OR
	byte SYMBOL_XOR
	byte EXPRESSION_BITWISE_XOR
	byte SYMBOL_AND
	byte EXPRESSION_BITWISE_AND
	byte SYMBOL_EQ_EQ
	byte EXPRESSION_EQ
	byte SYMBOL_NOT_EQ
	byte EXPRESSION_NEQ
	byte SYMBOL_LT
	byte EXPRESSION_LT
	byte SYMBOL_GT
	byte EXPRESSION_GT
	byte SYMBOL_LT_EQ
	byte EXPRESSION_LEQ
	byte SYMBOL_GT_EQ
	byte EXPRESSION_GEQ
	byte SYMBOL_LSHIFT
	byte EXPRESSION_LSHIFT
	byte SYMBOL_RSHIFT
	byte EXPRESSION_RSHIFT
	byte SYMBOL_PLUS
	byte EXPRESSION_ADD
	byte SYMBOL_MINUS
	byte EXPRESSION_SUB
	byte SYMBOL_TIMES
	byte EXPRESSION_MUL
	byte SYMBOL_DIV
	byte EXPRESSION_DIV
	byte SYMBOL_PERCENT
	byte EXPRESSION_REMAINDER
	byte SYMBOL_ARROW
	byte EXPRESSION_ARROW
	byte SYMBOL_DOT
	byte EXPRESSION_DOT
	byte SYMBOL_LSQUARE
	byte EXPRESSION_SUBSCRIPT
	byte 0
	byte 0

function binop_symbol_to_expression_type
	argument op
	local p
	p = .binop_table
	:binop_symbol_to_expression_type_loop
		if *1p == op goto binop_symbol_to_expression_type_found
		p += 2
		if *1p != 0 goto binop_symbol_to_expression_type_loop
	return 0
	:binop_symbol_to_expression_type_found
		p += 1
		return *1p

function is_operator
	argument symbol
	local b
	b = binop_symbol_to_expression_type(symbol)
	if b != 0 goto return_1
	b = unary_op_to_expression_type(symbol)
	if b != 0 goto return_1
	goto return_0

function binop_expression_type_to_symbol
	argument exprtype
	local p
	p = .binop_table
	:binop_expr2symb_type_loop
		p += 1
		if *1p == exprtype goto binop_expr2symb_type_found
		p += 1
		if *1p != 0 goto binop_expr2symb_type_loop
	return 0
	:binop_expr2symb_type_found
		p -= 1
		return *1p



function int_suffix_to_type
	argument suffix
	if suffix == NUMBER_SUFFIX_L goto return_type_long
	if suffix == NUMBER_SUFFIX_U goto return_type_unsigned_int
	if suffix == NUMBER_SUFFIX_UL goto return_type_unsigned_long
	goto return_type_int

function float_suffix_to_type
	argument suffix
	if suffix == NUMBER_SUFFIX_F goto return_type_float
	goto return_type_double

; smallest integer type which can fit this value, only using unsigned if necessary
function int_value_to_type
	argument value
	if value [ 0x80000000 goto return_type_int
	if value [ 0x8000000000000000 goto return_type_long
	goto return_type_unsigned_long

; returns pointer to end of expression
function print_expression
	argument expression
	local c
	local b
	local p
	p = expression + 4
	if *4p == 0 goto print_expr_skip_type
	putc(40)
	print_type(*4p)
	putc(41)
	:print_expr_skip_type
	c = *1expression
	
	if c == EXPRESSION_CONSTANT_INT goto print_expr_int
	if c == EXPRESSION_CONSTANT_FLOAT goto print_expr_float
	if c == EXPRESSION_POST_INCREMENT goto print_post_increment
	if c == EXPRESSION_POST_DECREMENT goto print_post_decrement
	if c == EXPRESSION_DOT goto print_expr_dot
	if c == EXPRESSION_ARROW goto print_expr_arrow
	if c == EXPRESSION_PRE_INCREMENT goto print_pre_increment
	if c == EXPRESSION_PRE_DECREMENT goto print_pre_decrement
	if c == EXPRESSION_ADDRESS_OF goto print_address_of
	if c == EXPRESSION_DEREFERENCE goto print_dereference
	if c == EXPRESSION_UNARY_PLUS goto print_unary_plus
	if c == EXPRESSION_UNARY_MINUS goto print_unary_minus
	if c == EXPRESSION_BITWISE_NOT goto print_bitwise_not
	if c == EXPRESSION_LOGICAL_NOT goto print_logical_not
	if c == EXPRESSION_CAST goto print_cast

	b = binop_expression_type_to_symbol(c)
	if b != 0 goto print_expr_binop
	
	puts(.str_print_bad_expr)
	exit(1)
	
	:str_print_bad_expr
		string Bad expression passed to print_expression.
		byte 10
		byte 0
	:print_cast
		; we've already printed the type
		expression += 8
		expression = print_expression(expression)
		return expression
	:print_expr_int
		expression += 8
		putn_signed(*8expression)
		expression += 8
		return expression
	:print_expr_float
		expression += 8
		putx64(*8expression)
		expression += 8
		return expression
	:print_expr_binop
		putc(40)
		expression += 8
		expression = print_expression(expression) ; 1st operand
		b = get_keyword_str(b)
		puts(b)
		expression = print_expression(expression) ; 2nd operand
		putc(41)
		return expression
	:print_expr_dot
		putc(40)
		expression += 8
		expression = print_expression(expression)
		puts(.str_dot)
		putn(*8expression)
		expression += 8
		putc(41)
		return expression
	:print_expr_arrow
		putc(40)
		expression += 8
		expression = print_expression(expression)
		puts(.str_arrow)
		putn(*8expression)
		expression += 8
		putc(41)
		return expression
	:print_post_increment
		putc(40)
		expression += 8
		expression = print_expression(expression)
		putc('+)
		putc('+)
		putc(41)
		return expression
	:print_post_decrement
		putc(40)
		expression += 8
		expression = print_expression(expression)
		putc('-)
		putc('-)
		putc(41)
		return expression
	:print_pre_increment
		putc(40)
		putc('+)
		putc('+)
		expression += 8
		expression = print_expression(expression)
		putc(41)
		return expression
	:print_pre_decrement
		putc(40)
		putc('-)
		putc('-)
		expression += 8
		expression = print_expression(expression)
		putc(41)
		return expression
	:print_address_of
		putc(40)
		putc('&)
		expression += 8
		expression = print_expression(expression)
		putc(41)
		return expression
	:print_dereference
		putc(40)
		putc('*)
		expression += 8
		expression = print_expression(expression)
		putc(41)
		return expression
	:print_unary_plus
		putc(40)
		putc('+)
		expression += 8
		expression = print_expression(expression)
		putc(41)
		return expression
	:print_unary_minus
		putc(40)
		putc('-)
		expression += 8
		expression = print_expression(expression)
		putc(41)
		return expression
	:print_bitwise_not
		putc(40)
		putc('~)
		expression += 8
		expression = print_expression(expression)
		putc(41)
		return expression
	:print_logical_not
		putc(40)
		putc('!)
		expression += 8
		expression = print_expression(expression)
		putc(41)
		return expression

; NOTE: to make things easier, the format which this outputs isn't the same as C's, specifically we have
;    *int for pointer to int and [5]int for array of 5 ints
function print_type
	argument type
	local c
	:print_type_top
	c = types + type
	c = *1c
	if c == TYPE_VOID goto print_type_void
	if c == TYPE_CHAR goto print_type_char
	if c == TYPE_UNSIGNED_CHAR goto print_type_unsigned_char
	if c == TYPE_SHORT goto print_type_short
	if c == TYPE_UNSIGNED_SHORT goto print_type_unsigned_short
	if c == TYPE_INT goto print_type_int
	if c == TYPE_UNSIGNED_INT goto print_type_unsigned_int
	if c == TYPE_LONG goto print_type_long
	if c == TYPE_UNSIGNED_LONG goto print_type_unsigned_long
	if c == TYPE_FLOAT goto print_type_float
	if c == TYPE_DOUBLE goto print_type_double
	if c == TYPE_POINTER goto print_type_pointer
	if c == TYPE_ARRAY goto print_type_array
	if c == TYPE_STRUCT goto print_type_struct
	if c == TYPE_FUNCTION goto print_type_function
	fputs(2, .str_bad_print_type)
	exit(1)
	:str_bad_print_type
		string Bad type passed to print_type.
		byte 10
		byte 0
	:print_type_void
		return puts(.str_void)
	:print_type_char
		return puts(.str_char)
	:print_type_unsigned_char
		return puts(.str_unsigned_char)
	:print_type_short
		return puts(.str_short)
	:print_type_unsigned_short
		return puts(.str_unsigned_short)
	:print_type_int
		return puts(.str_int)
	:print_type_unsigned_int
		return puts(.str_unsigned_int)
	:print_type_long
		return puts(.str_long)
	:print_type_unsigned_long
		return puts(.str_unsigned_long)
	:print_type_float
		return puts(.str_float)
	:print_type_double
		return puts(.str_double)
	:print_type_pointer
		putc('*)
		type += 1
		goto print_type_top
	:print_type_array
		putc('[)
		type += 1
		c = types + type
		putn(*8c) ; UNALIGNED
		putc('])
		type += 8
		goto print_type_top
	:print_type_struct
		return puts(.str_struct)
	:print_type_function
		type += 1
		putc(40)
		putc(40)
		:print_type_function_loop
			c = types + type
			if *1c == 0 goto print_type_function_loop_end
			print_type(type)
			putc(44)
			type += type_length(type)
			goto print_type_function_loop
		:print_type_function_loop_end
		type += 1 ; 0 terminator
		putc(41)
		putc(32)
		putc('-)
		putc('>)
		putc(32)
		print_type(type)
		putc(41)
		return
