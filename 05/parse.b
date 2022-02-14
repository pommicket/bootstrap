
global curr_function_stack_space

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
	

function type_is_array
	argument type
	local p
	p = types + type
	if *1p == TYPE_ARRAY goto return_1
	return 0

function type_is_function
	argument type
	local p
	p = types + type
	if *1p == TYPE_FUNCTION goto return_1
	return 0

function type_is_floating
	argument type
	local p
	p = types + type
	if *1p == TYPE_FLOAT goto return_1
	if *1p == TYPE_DOUBLE goto return_1
	return 0

function functype_return_type
	argument ftype
	local type
	local p
	
	type = ftype + 1
	:ftype_rettype_loop
		p = types + type
		if *1p == 0 goto ftype_rettype_loop_end
		type += type_length(type)
		goto ftype_rettype_loop
	:ftype_rettype_loop_end
	return type + 1

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
	
; parse a translation unit
function parse_tokens
	argument tokens
	local token
	
	token = tokens
	:parse_tokens_loop
		if *1token == TOKEN_EOF goto parse_tokens_eof
		parse_toplevel_declaration(&token, global_variables)
		goto parse_tokens_loop
	:parse_tokens_eof
	return


; also handles static declarations inside functions
; advances *p_token past semicolon
; static_vars = where to put static variables
function parse_toplevel_declaration
	argument p_token
	argument static_vars
	
	local token
	local ident
	local type
	local list
	local p
	local b
	local c
	local n
	local base_type
	local base_type_end
	local name
	local prefix
	local prefix_end
	local suffix
	local suffix_end
	local is_extern
	local out
	local out0
	
	token = *8p_token
	is_extern = 0

	if *1token == KEYWORD_STATIC goto parse_static_toplevel_decl
	if *1token == KEYWORD_EXTERN goto parse_extern_toplevel_decl
	if *1token == KEYWORD_TYPEDEF goto parse_typedef
	
	b = token_is_type(token)
	if b != 0 goto parse_toplevel_decl
	
	token_error(token, .str_bad_decl)
	:str_bad_decl
		string Bad declaration.
		byte 0
	:parse_tld_ret
		*8p_token = token
		return
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
			*1function_param_names = 0
			parse_type_declarators(prefix, prefix_end, suffix, suffix_end, function_param_names)
			parse_base_type(base_type, base_type_end)
			
			; ensure rwdata_end_addr is aligned to 8 bytes
			; otherwise addresses could be screwed up
			rwdata_end_addr += 7
			rwdata_end_addr >= 3
			rwdata_end_addr <= 3
			
			token = suffix_end
			p = types + type
			if *1p == TYPE_FUNCTION goto parse_function_declaration
			
			; ignore external variable declarations
			;  @NONSTANDARD: this means we don't handle
			;     extern int X;
			;     int main() { printf("%d\n", X); }
			;     int X;
			; correctly. There is no (good) way for us to handle this properly without two passes.
			; Consider:
			;      extern int X[];  /* how many bytes to allocate? */
			;      int Y = 123;           /* where do we put this? */
			;      int main() { printf("%d\n", Y); }
			;      int X[] = {1, 2, 3, 4}; /* 16 bytes (but it's too late) */
			if is_extern != 0 goto parse_tl_decl_cont
			
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
		goto parse_tld_ret
		
		:tl_decl_no_ident
			; this might actually be okay, e.g.
			; struct Something { int x, y; }
			if *1base_type == KEYWORD_STRUCT goto tldni_basetype_ok
			if *1base_type == KEYWORD_UNION goto tldni_basetype_ok
			if *1base_type == KEYWORD_ENUM goto tldni_basetype_ok
			goto tldni_bad
			:tldni_basetype_ok
			if prefix != prefix_end goto tldni_bad ; e.g. struct Something {...} *;
			if *1prefix_end != SYMBOL_SEMICOLON goto tldni_bad ; you can't do struct Something { ...}, struct SomethingElse {...};
			parse_base_type(base_type) ; this will properly define the struct/union/enum and any enumerators
			token = prefix_end
			goto tl_decl_loop_done
			:tldni_bad
				token_error(prefix_end, .str_tl_decl_no_ident)
		:str_tl_decl_no_ident
			string No identifier in top-level declaration.
			byte 0
		:tld_bad_stuff_after_decl
			token_error(token, .str_tld_bad_stuff_after_decl)
		:str_tld_bad_stuff_after_decl
			string Declarations should be immediately followed by a comma or semicolon.
			byte 0
	:parse_function_declaration
		b = ident_list_lookup(function_types, name)
		if b != 0 goto function_decl_have_type ; e.g. function declared then defined
		ident_list_add(function_types, name, type)
		:function_decl_have_type
		if *1token == SYMBOL_LBRACE goto parse_function_definition
		if *1token == SYMBOL_SEMICOLON goto parse_tl_decl_cont
		token_error(token, .str_bad_fdecl_suffix)
		:str_bad_fdecl_suffix
			string Expected semicolon or { after function declaration.
			byte 0
	:parse_tld_no_initializer
		b = ident_list_lookup(static_vars, name)
		if b != 0 goto global_redefinition
		c = type < 32
		c |= rwdata_end_addr
		ident_list_add(static_vars, name, c)
		; just skip forward by the size of this variable -- it'll automatically be filled with 0s.
		rwdata_end_addr += type_sizeof(type)
		goto parse_tl_decl_cont
	:parse_tld_initializer
		p = types + type
		if *1p == TYPE_FUNCTION goto function_initializer
		b = ident_list_lookup(static_vars, name)
		if b != 0 goto global_redefinition
		token += 16 ; skip =
		c = type < 32
		c |= rwdata_end_addr
		ident_list_add(static_vars, name, c)
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
		local ret_type
		local param_offset
		local f_name
		
		f_name = name
		
		if block_depth != 0 goto nested_function
		if function_param_has_no_name != 0 goto function_no_param_name
		p = types + type
		if *1p != TYPE_FUNCTION goto lbrace_after_declaration
		
		c = ident_list_lookup(function_statements, name)
		if c != 0 goto function_redefinition
		
		ret_type = functype_return_type(type)
		
		global function_stmt_data ; initialized in main
		global function_stmt_data_bytes_used
						
		out = function_stmt_data + function_stmt_data_bytes_used
		out0 = out
		ident_list_add(function_statements, name, out)
		
		; deal with function parameters
		; function parameters go above return value on the stack
		n = type_sizeof(ret_type)
		n += 7
		n >= 3
		n <= 3
		param_offset = n + 16  ; + 16 for old rbp and return address
		
		p = type + 1
		name = function_param_names
		list = local_variables
		list += 8
		list = *8list
		:fn_params_loop
			if *1name == 0 goto fn_params_loop_end
			c = p < 32
			c |= param_offset
			ident_list_add(list, name, c)
			param_offset += type_sizeof(p)
			param_offset += 7
			param_offset >= 3
			param_offset <= 3
			p += type_length(p)
			name = memchr(name, 0)
			name += 1
			goto fn_params_loop
		:fn_params_loop_end
		
		local_var_rbp_offset = 0
		
		; NOTE: it's the caller's responsibility to properly set rsp to accomodate all the arguments.
		;       it needs to be this way because of varargs functions (the function doesn't know how many arguments there are).
		parse_statement(&token, &out)
		if block_depth != 0 goto blockdepth_internal_err
		function_stmt_data_bytes_used = out - function_stmt_data
		
		ident_list_add(functions_required_stack_space, f_name, curr_function_stack_space)
		
		; ENABLE/DISABLE PARSING DEBUG OUTPUT:
		if G_DEBUG == 0 goto skip_print_statement
		print_statement(out0)
		:skip_print_statement
		
		goto parse_tld_ret
		
		:function_no_param_name
			token_error(base_type, .str_function_no_param_name)
		:str_function_no_param_name
			string Function definition with unnamed parameters.
			byte 0
		:blockdepth_internal_err
			token_error(token, .str_blockdepth_internal_err)
		:str_blockdepth_internal_err
			string Internal compiler error: block_depth is not 0 after parsing function body.
			byte 0
		:lbrace_after_declaration
			token_error(token, .str_lbrace_after_declaration)
		:str_lbrace_after_declaration
			string Opening { after declaration of non-function.
			byte 0
		:nested_function
			token_error(token, .str_nested_function)
		:str_nested_function
			string Nested function.
			byte 0
		:function_redefinition
			token_error(token, .str_function_redefinition)
		:str_function_redefinition
			string Redefinition of function.
			byte 0
	:parse_typedef
		if block_depth > 0 goto local_typedef
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
			parse_type_declarators(prefix, prefix_end, suffix, suffix_end, 0)
			parse_base_type(base_type)
			
			;puts(.str_typedef)
			;putc(32)
			;print_type(type)
			;putc(10)
			
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
		goto parse_tld_ret
	:local_typedef
		; @NONSTANDARD
		; we could add an extra "typedefs" argument to this function to fix this.
		token_error(token, .str_local_typedef)
	:str_local_typedef
		string typedefs inside functions are not supported.
		byte 0
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

; write type, file, and line info for statement
function write_statement_header
	local out
	local type
	local token
	*1out = type
	out += 2
	token += 2
	*2out = *2token
	out += 2
	token += 2
	*4out = *4token
	return 0


; writes statement data for the statement at *p_token to (*)*p_out
; always advances *p_out by exactly 40 bytes, since that's the length of a statement.
function parse_statement
	argument p_token
	argument p_out
	local out
	local token
	local p
	local c
	local n
	local b
	
	out = *8p_out
	token = *8p_token
	
	c = *1token
	if c == SYMBOL_SEMICOLON goto stmt_empty
	if c == SYMBOL_LBRACE goto stmt_block
	if c == KEYWORD_BREAK goto stmt_break
	if c == KEYWORD_CONTINUE goto stmt_continue
	if c == KEYWORD_RETURN goto stmt_return
	if c == KEYWORD_GOTO goto stmt_goto
	if c == KEYWORD_CASE goto stmt_case
	if c == KEYWORD_DEFAULT goto stmt_default
	if c == KEYWORD_STATIC goto stmt_static_declaration
	if c == KEYWORD_EXTERN goto stmt_extern_declaration
	if c == KEYWORD_WHILE goto stmt_while
	if c == KEYWORD_DO goto stmt_do
	if c == KEYWORD_FOR goto stmt_for
	if c == KEYWORD_SWITCH goto stmt_switch
	if c == KEYWORD_IF goto stmt_if
	
	if *1token != TOKEN_IDENTIFIER goto stmt_not_label
	; if second token in statement is a colon, this must be a label
	p = token + 16
	if *1p == SYMBOL_COLON goto stmt_label
	:stmt_not_label
	
	b = token_is_type(token)
	if b != 0 goto stmt_local_declaration
	
	; it's an expression statement
	write_statement_header(out, STATEMENT_EXPRESSION, token)
	out += 8
	p = token_next_semicolon_not_in_brackets(token)
	*8out = expressions_end
	b = expressions_end + 4 ; type of expression
	expressions_end = parse_expression(token, p, expressions_end)
	type_decay_array_to_pointer_in_place(*4b)
	out += 32
	token = p + 16
	goto parse_statement_ret
	
	:parse_statement_ret
		*8p_token = token
		*8p_out = out
		return
	:stmt_extern_declaration
		token_error(token, .str_stmt_extern_declaration)
	:str_stmt_extern_declaration
		; @NONSTANDARD
		string Local extern declarations are not supported.
		byte 0
	:stmt_label
		write_statement_header(out, STATEMENT_LABEL, token)
		out += 8
		token += 8
		*8out = *8token ; copy label name
		out += 32
		token += 24 ; skip ident name, and colon
		goto parse_statement_ret
	:stmt_switch
		write_statement_header(out, STATEMENT_SWITCH, token)		
		token += 16
		if *1token != SYMBOL_LPAREN goto switch_no_lparen
		p = token_matching_rparen(token)
		token += 16
		out += 8
		*8out = expressions_end
		c = expressions_end + 4
		expressions_end = parse_expression(token, p, expressions_end)
		c = types + *4c
		if *1c > TYPE_UNSIGNED_LONG goto bad_switch_type
		
		token = p + 16
		out += 8
		
		; put the body statement 1 block_depth deeper
		p = statement_datas_ends
		p += block_depth < 3
		block_depth += 1
		if block_depth >= BLOCK_DEPTH_LIMIT goto too_much_nesting
		*8out = *8p
		out += 24
		parse_statement(&token, p) ; the body
		block_depth -= 1
		
		goto parse_statement_ret
		:switch_no_lparen
			token_error(token, .str_switch_no_lparen)
		:str_switch_no_lparen
			string No ( after switch.
			byte 0
		:bad_switch_type
			token_error(token, .str_bad_switch_type)
		:str_bad_switch_type
			string The expression in a switch statement must have an integer type.
			byte 0
	:stmt_while
		write_statement_header(out, STATEMENT_WHILE, token)		
		token += 16
		if *1token != SYMBOL_LPAREN goto while_no_lparen
		p = token_matching_rparen(token)
		token += 16
		out += 8
		*8out = expressions_end
		expressions_end = parse_expression(token, p, expressions_end)
		token = p + 16
		out += 8
		
		; put the body statement 1 block_depth deeper
		p = statement_datas_ends
		p += block_depth < 3
		block_depth += 1
		if block_depth >= BLOCK_DEPTH_LIMIT goto too_much_nesting
		*8out = *8p
		out += 24
		parse_statement(&token, p) ; the body
		block_depth -= 1
		
		goto parse_statement_ret
		:while_no_lparen
			token_error(token, .str_while_no_lparen)
		:str_while_no_lparen
			string No ( after while.
			byte 0
	:stmt_do
		write_statement_header(out, STATEMENT_DO, token)
		out += 8
		token += 16
		
		; put the body statement 1 block_depth deeper
		p = statement_datas_ends
		p += block_depth < 3
		block_depth += 1
		if block_depth >= BLOCK_DEPTH_LIMIT goto too_much_nesting
		*8out = *8p
		out += 8
		parse_statement(&token, p) ; the body
		block_depth -= 1
		
		if *1token != KEYWORD_WHILE goto do_no_while
		token += 16
		if *1token != SYMBOL_LPAREN goto do_no_lparen
		p = token_matching_rparen(token)
		token += 16
		*8out = expressions_end
		expressions_end = parse_expression(token, p, expressions_end)
		token = p + 16
		if *1token != SYMBOL_SEMICOLON goto do_no_semicolon
		token += 16
		
		out += 24
		goto parse_statement_ret
		
		:do_no_while
			token_error(token, .str_do_no_while)
		:str_do_no_while
			string No while after do body.
			byte 0
		:do_no_lparen
			token_error(token, .str_do_no_lparen)
		:str_do_no_lparen
			string No ( after do ... while
			byte 0
		:do_no_semicolon	
			token_error(token, .str_do_no_semicolon)
		:str_do_no_semicolon
			string No semicolon after do ... while (...)
			byte 0
	:stmt_for
		write_statement_header(out, STATEMENT_FOR, token)
		out += 8
		token += 16
		if *1token != SYMBOL_LPAREN goto for_no_lparen
		c = token_matching_rparen(token)
		token += 16
		p = token_next_semicolon_not_in_brackets(token)
		if token == p goto for_no_expr1
		*8out = expressions_end
		expressions_end = parse_expression(token, p, expressions_end)
		:for_no_expr1
		out += 8
		token = p + 16
		p = token_next_semicolon_not_in_brackets(token)
		if token == p goto for_no_expr2
		*8out = expressions_end
		expressions_end = parse_expression(token, p, expressions_end)
		:for_no_expr2
		out += 8
		token = p + 16
		if c < token goto bad_for
		if c == token goto for_no_expr3
		*8out = expressions_end
		expressions_end = parse_expression(token, c, expressions_end)
		:for_no_expr3
		out += 8
		token = c + 16
		
		; put the body statement 1 block_depth deeper
		p = statement_datas_ends
		p += block_depth < 3
		block_depth += 1
		if block_depth >= BLOCK_DEPTH_LIMIT goto too_much_nesting
		*8out = *8p
		out += 8
		parse_statement(&token, p) ; the body
		block_depth -= 1
		
		goto parse_statement_ret
		
		:bad_for
			token_error(c, .str_bad_for)
		:str_bad_for
			string Bad for loop header.
			byte 0
		:for_no_lparen
			token_error(token, .str_for_no_lparen)
		:str_for_no_lparen
			string Missing ( after for.
			byte 0
	:stmt_if
		write_statement_header(out, STATEMENT_IF, token)
		out += 8
		token += 16
		if *1token != SYMBOL_LPAREN goto if_no_lparen
		p = token_matching_rparen(token)
		token += 16
		*8out = expressions_end
		out += 8
		expressions_end = parse_expression(token, p, expressions_end)
		token = p + 16
		
		
		; put the body statement(s) 1 block_depth deeper
		p = statement_datas_ends
		p += block_depth < 3
		block_depth += 1
		if block_depth >= BLOCK_DEPTH_LIMIT goto too_much_nesting
		*8out = *8p
		out += 8
		parse_statement(&token, p) ; if body
		if *1token != KEYWORD_ELSE goto stmt_if_no_else
		token += 16
		*8out = *8p
		parse_statement(&token, p) ; else body
		:stmt_if_no_else
		out += 16
		block_depth -= 1
		goto parse_statement_ret
		:if_no_lparen
			token_error(token, .str_if_no_lparen)
		:str_if_no_lparen
			string No ( after if
			byte 0
	:stmt_local_declaration
		local l_base_type
		local l_prefix
		local l_prefix_end
		local l_suffix
		local l_suffix_end
		local l_type
		local l_offset
		local l_name
		
		l_base_type = token
		token = type_get_base_end(l_base_type)
		:local_decl_loop
			l_prefix = token
			l_prefix_end = type_get_prefix_end(l_prefix)
			if *1l_prefix_end != TOKEN_IDENTIFIER goto local_decl_no_ident
			l_name = l_prefix_end + 8
			l_name = *8l_name
			l_suffix = l_prefix_end + 16
			l_suffix_end = type_get_suffix_end(l_prefix)
			l_type = types_bytes_used
			parse_type_declarators(l_prefix, l_prefix_end, l_suffix, l_suffix_end, 0)
			parse_base_type(l_base_type)
			
			; create pseudo-entry for variable in local variables list.
			;   this allows for  int *x = malloc(sizeof *x);
			; unfortunately, it also allows  int x = x;
			; oh well
			p = local_variables
			p += block_depth < 3
			c = ident_list_lookup(*8p, l_name)
			if c != 0 goto local_redeclaration
			c = l_type < 32
			ident_list_add(*8p, l_name, c)
			
			
			token = l_suffix_end
			if *1token == SYMBOL_EQ goto local_decl_initializer
			:local_decl_continue
			; we need to calculate the size of the type here, because of stuff like
			;    int x[] = {1,2,3};
			n = type_sizeof(l_type)
			
			; advance
			local_var_rbp_offset += n
			; align
			local_var_rbp_offset = round_up_to_8(local_var_rbp_offset)
			
			write_statement_header(out, STATEMENT_LOCAL_DECLARATION, token)
			out += 8
			*8out = local_var_rbp_offset
			out += 8
			*8out = l_type
			out += 24
			
			curr_function_stack_space = local_var_rbp_offset
			
			p = local_variables
			p += block_depth < 3
			; local variables are stored below rbp
			l_offset = 0 - local_var_rbp_offset
			c = l_offset & 0xffffffff
			c |= l_type < 32
			ident_list_set(*8p, l_name, c)
			
			if *1token == SYMBOL_SEMICOLON goto local_decl_loop_end
			if *1token != SYMBOL_COMMA goto local_decl_badsuffix
			
			token += 16 ; skip comma
			goto local_decl_loop
			
			:local_decl_initializer
				token += 16
				if *1token == SYMBOL_LBRACE goto local_init_lbrace
				n = token_next_semicolon_comma_rbracket(token)
				out += 24
				p = expressions_end
				*8out = p
				out -= 24
				expressions_end = parse_expression(token, n, p)
				p += 4
				type_decay_array_to_pointer_in_place(*4p) ; fix typing for `int[] x = {5,6}; int *y = x;`
				token = n
				goto local_decl_continue
			:local_init_lbrace
				rwdata_end_addr += 7
				rwdata_end_addr >= 3
				rwdata_end_addr <= 3
				out += 32
				*8out = rwdata_end_addr
				out -= 32
				parse_constant_initializer(&token, l_type)
				goto local_decl_continue
			:local_decl_badsuffix
				token_error(token, .str_local_decl_badsuffix)
			:str_local_decl_badsuffix
				string Expected equals, comma, or semicolon after variable declaration.
				byte 0
			:local_redeclaration
				token_error(token, .str_local_redeclaration)
			:str_local_redeclaration
				string Redeclaration of local variable.
				byte 0
			:local_decl_no_ident						
				:local_decl_no_ident_bad
					token_error(token, .str_local_decl_no_ident)
				:str_local_decl_no_ident
					string No identifier in declaration.
					byte 0
		:local_decl_loop_end
		token += 16 ; skip semicolon
		goto parse_statement_ret
	:stmt_static_declaration
		p = block_static_variables
		p += block_depth < 3
		parse_toplevel_declaration(&token, *8p)
		goto parse_statement_ret
	:stmt_break
		write_statement_header(out, STATEMENT_BREAK, token)
		token += 16
		if *1token != SYMBOL_SEMICOLON goto break_no_semicolon
		token += 16
		out += 40
		goto parse_statement_ret
		:break_no_semicolon
			token_error(token, .str_break_no_semicolon)
		:str_break_no_semicolon
			string No semicolon after break.
			byte 0
	:stmt_continue
		write_statement_header(out, STATEMENT_CONTINUE, token)
		token += 16
		if *1token != SYMBOL_SEMICOLON goto continue_no_semicolon
		token += 16
		out += 40
		goto parse_statement_ret
		:continue_no_semicolon
			token_error(token, .str_continue_no_semicolon)
		:str_continue_no_semicolon
			string No semicolon after continue.
			byte 0
	:stmt_case
		write_statement_header(out, STATEMENT_CASE, token)
		token += 16
		out += 8
		p = token
		; @NONSTANDARD
		;  technically (horribly), this is legal C:
		;     switch (x) {
		;       case 1 == 7 ? 5 : 6:
		;          ...
		;     }
		; we don't handle it properly, even if the conditional is put in parentheses.
		; at least it will definitely give an error if it encounters something like this.
		:case_find_colon_loop
			if *1p == TOKEN_EOF goto case_no_colon
			if *1p == SYMBOL_COLON goto case_found_colon
			p += 16
			goto case_find_colon_loop
		:case_found_colon
		c = expressions_end
		expressions_end = parse_expression(token, p, expressions_end)
		evaluate_constant_expression(token, c, &n)
		*8out = n
		out += 32
		token = p + 16
		goto parse_statement_ret
		:case_no_colon
			token_error(token, .str_case_no_colon)
		:str_case_no_colon
			string No : after case.
			byte 0
	:stmt_default
		write_statement_header(out, STATEMENT_DEFAULT, token)
		token += 16
		out += 40
		if *1token != SYMBOL_COLON goto default_no_colon
		token += 16
		goto parse_statement_ret
		:default_no_colon
			token_error(token, .str_default_no_colon)
		:str_default_no_colon
			string No : after default.
			byte 0
	:stmt_return
		write_statement_header(out, STATEMENT_RETURN, token)
		out += 8
		token += 16
		if *1token == SYMBOL_SEMICOLON goto return_no_expr
		n = token_next_semicolon_not_in_brackets(token)
		*8out = expressions_end
		p = expressions_end + 4 ; type of expression
		expressions_end = parse_expression(token, n, expressions_end)
		type_decay_array_to_pointer_in_place(*4p)
		token = n + 16
		:return_no_expr
		out += 32
		goto parse_statement_ret
	:stmt_goto
		write_statement_header(out, STATEMENT_GOTO, token)
		out += 8
		token += 16
		if *1token != TOKEN_IDENTIFIER goto goto_not_ident
		token += 8
		*8out = *8token
		out += 32
		token += 8
		if *1token != SYMBOL_SEMICOLON goto goto_no_semicolon
		token += 16
		goto parse_statement_ret
		:goto_not_ident
			token_error(token, .str_goto_not_ident)
		:str_goto_not_ident
			string goto not immediately followed by identifier.
			byte 0
		:goto_no_semicolon
			token_error(token, .str_goto_no_semicolon)
		:str_goto_no_semicolon
			string No semicolon after goto.
			byte 0
	:stmt_block
		local Z
		Z = out
		write_statement_header(out, STATEMENT_BLOCK, token)
		out += 8
		
		local block_p_out
		; find the appropriate statement data to use for this block's body
		block_p_out = statement_datas_ends
		block_p_out += block_depth < 3
		*8out = *8block_p_out
		out += 32
		
		block_depth += 1
		if block_depth >= BLOCK_DEPTH_LIMIT goto too_much_nesting
		
		token += 16 ; skip opening {
		:parse_block_loop
			if *1token == TOKEN_EOF goto parse_block_eof
			if *1token == SYMBOL_RBRACE goto parse_block_loop_end
			parse_statement(&token, block_p_out)
			goto parse_block_loop
		:parse_block_loop_end
		token += 16 ; skip closing }
		p = *8block_p_out
		*1p = 0  ; probably redundant, but whatever
		*8block_p_out += 8 ; add 8 and not 1 because of alignment
		
		; clear block-related stuff for this depth
		p = block_static_variables
		p += block_depth < 3
		ident_list_clear(*8p)
		p = local_variables
		p += block_depth < 3
		ident_list_clear(*8p)
		
		block_depth -= 1
		
		goto parse_statement_ret
		
		:parse_block_eof
			token_error(*8p_token, .str_parse_block_eof)
		:str_parse_block_eof
			string End of file reached while trying to parse block. Are you missing a closing brace?
			byte 0
		:too_much_nesting
			token_error(token, .str_too_much_nesting)
		:str_too_much_nesting
			string Too many levels of nesting blocks.
			byte 0
	:stmt_empty
		; empty statement, e.g. while(something)-> ; <-
		; we do have to output a statement here because otherwise that kind of thing would be screwed up
		write_statement_header(out, STATEMENT_NOOP, token)
		out += 40
		token += 16 ; skip semicolon
		goto parse_statement_ret

function print_statement
	argument statement
	print_statement_with_depth(statement, 0)
	return


function print_indents
	argument count
	:print_indent_loop
		if count == 0 goto return_0
		putc(9)
		count -= 1
		goto print_indent_loop
	
function print_statement_with_depth
	argument statement
	argument depth
	local c
	local dat1
	local dat2
	local dat3
	local dat4
	
	print_indents(depth)
	
	c = *1statement
	dat1 = statement + 8
	dat1 = *8dat1
	dat2 = statement + 16
	dat2 = *8dat2
	dat3 = statement + 24
	dat3 = *8dat3
	dat4 = statement + 32
	dat4 = *8dat4
	
	if c == STATEMENT_NOOP goto print_stmt_noop
	if c == STATEMENT_EXPRESSION goto print_stmt_expr
	if c == STATEMENT_BLOCK goto print_stmt_block
	if c == STATEMENT_CONTINUE goto print_stmt_continue
	if c == STATEMENT_BREAK goto print_stmt_break
	if c == STATEMENT_RETURN goto print_stmt_return
	if c == STATEMENT_GOTO goto print_stmt_goto
	if c == STATEMENT_LABEL goto print_stmt_label
	if c == STATEMENT_CASE goto print_stmt_case
	if c == STATEMENT_DEFAULT goto print_stmt_default
	if c == STATEMENT_WHILE goto print_stmt_while
	if c == STATEMENT_DO goto print_stmt_do
	if c == STATEMENT_IF goto print_stmt_if
	if c == STATEMENT_SWITCH goto print_stmt_switch
	if c == STATEMENT_FOR goto print_stmt_for
	if c == STATEMENT_LOCAL_DECLARATION goto print_stmt_local_decl
	
	die(.str_bad_print_stmt)
	:str_bad_print_stmt
		string Bad statement passed to print_statement.
		byte 0
	:str_semicolon_newline
		byte 59
		byte 10
		byte 0
	:print_stmt_label
		puts(dat1)
		putcln(':)
		return
	:print_stmt_expr
		print_expression(dat1)
		putcln(59)
		return
	:print_stmt_noop
		putcln(59)
		return
	:print_stmt_while
		puts(.str_stmt_while)
		print_expression(dat1)
		putcln(41)
		print_statement_with_depth(dat2, depth)
		return
		:str_stmt_while
			string while (
			byte 0
	:print_stmt_for
		puts(.str_stmt_for)
		if dat1 == 0 goto print_for_noexpr1
		print_expression(dat1)
		:print_for_noexpr1
		puts(.str_for_sep)
		if dat2 == 0 goto print_for_noexpr2
		print_expression(dat2)
		:print_for_noexpr2
		puts(.str_for_sep)
		if dat3 == 0 goto print_for_noexpr3
		print_expression(dat3)
		:print_for_noexpr3
		putcln(41)
		print_statement_with_depth(dat4, depth)
		return
		:str_stmt_for
			string for (
			byte 0
		:str_for_sep
			byte 59
			byte 32
			byte 0
	:print_stmt_switch
		puts(.str_stmt_switch)
		print_expression(dat1)
		putcln(41)
		print_statement_with_depth(dat2, depth)
		return
		:str_stmt_switch
			string switch (
			byte 0
	:print_stmt_do
		puts(.str_stmt_do)
		print_statement_with_depth(dat1, depth)
		print_indents(depth)
		puts(.str_stmt_while)
		print_expression(dat2)
		putc(41)
		putcln(59)
		return
		:str_stmt_do
			string do
			byte 10
			byte 0
	:print_stmt_if
		puts(.str_stmt_if)
		print_expression(dat1)
		putcln(41)
		print_statement_with_depth(dat2, depth)
		if dat3 == 0 goto return_0
		print_indents(depth)
		putsln(.str_else)
		print_statement_with_depth(dat3, depth)
		return
		:str_stmt_if
			string if (
			byte 0
	:print_stmt_break
		puts(.str_stmt_break)
		return
	:str_stmt_break
		string break
		byte 59 ; semicolon
		byte 10
		byte 0
	:print_stmt_continue
		puts(.str_stmt_continue)
		return
	:str_stmt_continue
		string continue
		byte 59 ; semicolon
		byte 10
		byte 0
	:print_stmt_return
		puts(.str_return)
		if dat1 == 0 goto print_ret_noexpr
		putc(32)
		print_expression(dat1)
		:print_ret_noexpr
		puts(.str_semicolon_newline)
		return
	:print_stmt_local_decl
		puts(.str_local_decl)
		putn(dat1)
		puts(.str_local_type)
		print_type(dat2)
		if dat3 != 0 goto print_stmt_local_initializer
		if dat4 != 0 goto print_stmt_local_copy_address
		:stmt_local_decl_finish
		puts(.str_semicolon_newline)
		return
		:print_stmt_local_initializer
			putc(32)
			putc(61) ; =
			putc(32)
			print_expression(dat3)
			goto stmt_local_decl_finish
		:print_stmt_local_copy_address
			puts(.str_local_copyfrom)
			putx32(dat4)
			goto stmt_local_decl_finish
	:str_local_decl
		string local variable at rbp-
		byte 0
	:str_local_type
		string  type
		byte 32
		byte 0
	:str_local_copyfrom
		string  copy from
		byte 32
		byte 0
	:print_stmt_block
		putcln('{)
		depth += 1
		:print_block_loop
			if *1dat1 == 0 goto print_block_loop_end
			print_statement_with_depth(dat1, depth)
			dat1 += 40
			goto print_block_loop
		:print_block_loop_end
		depth -= 1
		print_indents(depth)
		putcln('})
		return
	:print_stmt_goto
		puts(.str_goto)
		putc(32)
		puts(dat1)
		puts(.str_semicolon_newline)
		return
	:print_stmt_case
		puts(.str_case)
		putc(32)
		putn_signed(dat1)
		putcln(':)
		return
	:print_stmt_default
		puts(.str_default)
		putcln(':)
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
	if *1p == TYPE_FLOAT goto init_float_check
	if *1p == TYPE_DOUBLE goto init_double_check
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
	:init_double_check
		; check if someone did    double x[] = {3};
		;  we would screw this up and set x[0] to the binary representation of 3 as an integer
		
		if value == 0 goto init_good ; 0 is fine
		
		; this isn't foolproof, but it should work most of the time
		if value [ 0x10000000000000 goto bad_float_initializer
		if value ] 0xfff0000000000000 goto bad_float_initializer
		
		goto init_good
	:init_float_check
		if value == 0 goto init_good
		goto bad_float_initializer
	:bad_float_initializer
		token_error(token, .str_bad_float_initializer)
	:str_bad_float_initializer
		string Bad floating-point initializer.
		byte 0
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
		string Only 0 is supported as a constant floating-point initializer.
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

; token should be pointing to (, this returns the corresponding )
function token_matching_rparen
	argument token
	local token0
	local depth
	token0 = token
	depth = 0
	:matching_rparen_loop
		if *1token == SYMBOL_LPAREN goto matching_rparen_incdepth
		if *1token == SYMBOL_RPAREN goto matching_rparen_decdepth
		if *1token == TOKEN_EOF goto matching_rparen_eof
		:matching_rparen_next
		token += 16
		goto matching_rparen_loop
		:matching_rparen_incdepth
			depth += 1
			goto matching_rparen_next
		:matching_rparen_decdepth
			depth -= 1
			if depth == 0 goto matching_rparen_ret
			goto matching_rparen_next
	:matching_rparen_ret
	return token
	
	:matching_rparen_eof
		token_error(token0, .str_matching_rparen_eof)
	:str_matching_rparen_eof
		string Unmatched (
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


; return the next semicolon not in parentheses, square brackets, or braces. 
function token_next_semicolon_not_in_brackets
	argument token0
	
	local token
	local depth
	local c
	
	depth = 0
	token = token0
	:next_semicolon_loop
		c = *1token
		if c == TOKEN_EOF goto next_semicolon_eof
		if depth != 0 goto next_semicolon_nocheck
		if c == SYMBOL_SEMICOLON goto next_semicolon_loop_end
		:next_semicolon_nocheck
		token += 16
		if c == SYMBOL_LPAREN goto next_semicolon_incdepth
		if c == SYMBOL_RPAREN goto next_semicolon_decdepth
		if c == SYMBOL_LSQUARE goto next_semicolon_incdepth
		if c == SYMBOL_RSQUARE goto next_semicolon_decdepth
		if c == SYMBOL_LBRACE goto next_semicolon_incdepth
		if c == SYMBOL_RBRACE goto next_semicolon_decdepth
		goto next_semicolon_loop
		:next_semicolon_incdepth
			depth += 1
			goto next_semicolon_loop
		:next_semicolon_decdepth
			depth -= 1
			goto next_semicolon_loop
	:next_semicolon_loop_end
	return token
	:next_semicolon_eof
		token_error(token0, .str_next_semicolon_eof)
		:str_next_semicolon_eof
			string End of file found while searching for semicolon.
			byte 0 


; return the next semicolon or comma not in parentheses, square brackets, or braces;
;   or the next unmatched right bracket (of any type) 
function token_next_semicolon_comma_rbracket
	argument token0
	
	local token
	local depth
	local c
	
	depth = 0
	token = token0
	:next_semicomma_loop
		c = *1token
		if c == TOKEN_EOF goto next_semicomma_eof
		if depth != 0 goto next_semicomma_nocheck
		if c == SYMBOL_SEMICOLON goto next_semicomma_loop_end
		if c == SYMBOL_COMMA goto next_semicomma_loop_end
		:next_semicomma_nocheck
		token += 16
		if c == SYMBOL_LPAREN goto next_semicomma_incdepth
		if c == SYMBOL_RPAREN goto next_semicomma_decdepth
		if c == SYMBOL_LSQUARE goto next_semicomma_incdepth
		if c == SYMBOL_RSQUARE goto next_semicomma_decdepth
		if c == SYMBOL_LBRACE goto next_semicomma_incdepth
		if c == SYMBOL_RBRACE goto next_semicomma_decdepth
		goto next_semicomma_loop
		:next_semicomma_incdepth
			depth += 1
			goto next_semicomma_loop
		:next_semicomma_decdepth
			depth -= 1
			if depth < 0 goto next_semicomma_loop_end_dectoken
			goto next_semicomma_loop
	:next_semicomma_loop_end_dectoken
	token -= 16
	:next_semicomma_loop_end
	return token
	:next_semicomma_eof
		token_error(token0, .str_next_semicomma_eof)
		:str_next_semicomma_eof
			string End of file found while searching for semicolon/comma/closing bracket.
			byte 0 



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
	; function parameters will be stored here (null-byte separated) if not 0
	; make sure you check that it's actually a function type before reading this
	argument parameters
	local p
	local expr
	local n
	local c
	local depth
	local out
	local param_names_out
	param_names_out = parameters
	
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
			param_names_out = 0
			out = types + types_bytes_used
			*1out = TYPE_POINTER
			types_bytes_used += 1
			prefix_end = p
			goto type_declarators_loop
		:parse_array_type
			param_names_out = 0
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
			local d
			
			if param_names_out == 0 goto skip_ftype_reset
			; this gets set to 1 if at least one parameter has no name.
			; we don't just error here, because we need to support declarations like:
			;   int f(int, int);
			function_param_has_no_name = 0
			:skip_ftype_reset
			
			out = types + types_bytes_used
			*1out = TYPE_FUNCTION
			types_bytes_used += 1
			
			p = suffix + 16
			if *1p == SYMBOL_RPAREN goto ftype_no_parameters ; e.g. int f() { return 17; }
			if *1p != KEYWORD_VOID goto ftype_has_parameters
			n = p + 16
			suffix += 16
			if *1n != SYMBOL_RPAREN goto ftype_has_parameters
			:ftype_no_parameters
			; special handling of function type with no parameters
			out = types + types_bytes_used
			*1out = 0
			types_bytes_used += 1
			suffix += 32
			goto type_declarators_loop
			
			
			:ftype_has_parameters
			:function_type_loop
				if *1p == SYMBOL_DOTDOTDOT goto ftype_varargs
				param_base_type = p
				param_prefix = type_get_base_end(param_base_type)
				param_prefix_end = type_get_prefix_end(param_prefix)
				param_suffix = param_prefix_end
				if *1param_suffix != TOKEN_IDENTIFIER goto functype_no_ident
				param_suffix += 16
				if param_names_out == 0 goto functype_had_ident
				param_suffix -= 8
				param_names_out = strcpy(param_names_out, *8param_suffix)
				param_names_out += 1
				param_suffix += 8
				goto functype_had_ident
				:functype_no_ident
				if param_names_out != 0 goto no_param_name
				:functype_had_ident
				param_suffix_end = type_get_suffix_end(param_prefix)
				c = types + types_bytes_used
				parse_type_declarators(param_prefix, param_prefix_end, param_suffix, param_suffix_end, 0)
				parse_base_type(param_base_type)
				if *1c != TYPE_ARRAY goto function_param_not_array
				; decay array into pointer
				*1c = TYPE_POINTER
				c += 1
				c -= types
				d = c + 8
				type_copy_ids(c, d)
				types_bytes_used -= 8
				:function_param_not_array
				p = param_suffix_end
				if *1p == SYMBOL_RPAREN goto function_type_loop_end
				if *1p != SYMBOL_COMMA goto parse_typedecls_bad_type
				p += 16
				goto function_type_loop
				:ftype_varargs
					; ignore varargs
					p += 16
					if *1p != SYMBOL_RPAREN goto stuff_after_ftype_varargs
					goto function_type_loop_end
			:function_type_loop_end
			if param_names_out == 0 goto ftype_skip_zpno
			*1param_names_out = 0
			; prevent lower-level parts of type from writing parameters 
			param_names_out = 0
			:ftype_skip_zpno
			
			out = types + types_bytes_used
			*1out = 0
			types_bytes_used += 1
			suffix = p + 16
			goto type_declarators_loop
			:no_param_name
				function_param_has_no_name = 1
				goto functype_had_ident
			:stuff_after_ftype_varargs
				token_error(p, .str_stuff_after_ftype_varargs)
			:str_stuff_after_ftype_varargs
				string Stuff after ... (varargs) in function type.
				byte 0
		:parse_type_remove_parentheses
			; interestingly:
			;   int (f(int x)) { return x * 2; }
			; seems perfectly legal.
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
		
		if c == 0 goto base_type_new_incomplete_struct
		:base_type_named_struct
			; e.g. struct Foo x;
			*1out = TYPE_STRUCT
			out += 1
			*8out = c
			out += 8
			goto base_type_done
		:base_type_new_incomplete_struct
			; create an ident list for the incomplete struct, with nothing in it yet
			struct = ident_list_create(8000)
			; add it to the table
			ident_list_add(structures, struct_name, struct)
			c = struct
			goto base_type_named_struct
		:base_type_struct_definition
			;  @NONSTANDARD: we don't handle bit-fields.
			local struct_location
			local member_base_type
			local member_prefix
			local member_prefix_end
			local member_suffix
			local member_suffix_end
			local member_name
			local member_type
			local member_align
			local member_size
			
			struct_location = token_get_location(p)
			
			if c == 0 goto completely_new_struct
			if *1c != 0 goto struct_maybe_redefinition
				; ok we're filling in an incomplete struct
				struct = c
				goto struct_definition_fill_in
			
			:completely_new_struct
				; a completely new struct; hasn't been used as an incomplete struct
				struct = ident_list_create(8000) ; note: maximum "* 127 members in a single structure or union" C89 § 2.2.4.1
				ident_list_add(structures, struct_name, struct)
			
			:struct_definition_fill_in
			
			*1out = TYPE_STRUCT
			out += 1
			*8out = struct
			out += 8
			types_bytes_used = out - types
			p += 16 ; skip opening {
			
			local offset
			offset = 0
			
			if *1struct_name == 0 goto struct_unnamed
			ident_list_add(structure_locations, struct_name, struct_location)
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
					
					
					parse_type_declarators(member_prefix, member_prefix_end, member_suffix, member_suffix_end, 0)
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
		:struct_maybe_redefinition
			local other_location
			other_location = ident_list_lookup(structure_locations, struct_name)
			if other_location != struct_location goto struct_redefinition ; actual struct redefinition
			; we don't want lines like this to cause problems:   struct A { int x,y; } a,b;
			*1out = TYPE_STRUCT
			out += 1
			*8out = c
			out += 8
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
	puts(.str_type_length_bad_type)
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

function type_create_copy
	argument type
	local copy
	copy = types_bytes_used
	types_bytes_used += type_copy_ids(types_bytes_used, type)
	return copy
	
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

function expression_get_end
	argument expr
	local c
	c = *1expr
	if c == EXPRESSION_CONSTANT_INT goto exprend_8data
	if c == EXPRESSION_CONSTANT_FLOAT goto exprend_8data
	if c == EXPRESSION_LOCAL_VARIABLE goto exprend_8data
	if c == EXPRESSION_GLOBAL_VARIABLE goto exprend_8data
	if c == EXPRESSION_FUNCTION goto exprend_8data
	if c == EXPRESSION_SUBSCRIPT goto exprend_binary
	if c == EXPRESSION_CALL goto exprend_call
	if c == EXPRESSION_DOT goto exprend_member
	if c == EXPRESSION_ARROW goto exprend_member
	if c == EXPRESSION_POST_INCREMENT goto exprend_unary
	if c == EXPRESSION_POST_DECREMENT goto exprend_unary
	if c == EXPRESSION_PRE_INCREMENT goto exprend_unary
	if c == EXPRESSION_PRE_DECREMENT goto exprend_unary
	if c == EXPRESSION_ADDRESS_OF goto exprend_unary
	if c == EXPRESSION_DEREFERENCE goto exprend_unary
	if c == EXPRESSION_UNARY_PLUS goto exprend_unary
	if c == EXPRESSION_UNARY_MINUS goto exprend_unary
	if c == EXPRESSION_BITWISE_NOT goto exprend_unary
	if c == EXPRESSION_LOGICAL_NOT goto exprend_unary
	if c == EXPRESSION_CAST goto exprend_unary
	if c == EXPRESSION_MUL goto exprend_binary
	if c == EXPRESSION_DIV goto exprend_binary
	if c == EXPRESSION_REMAINDER goto exprend_binary
	if c == EXPRESSION_ADD goto exprend_binary
	if c == EXPRESSION_SUB goto exprend_binary
	if c == EXPRESSION_LSHIFT goto exprend_binary
	if c == EXPRESSION_RSHIFT goto exprend_binary
	if c == EXPRESSION_LT goto exprend_binary
	if c == EXPRESSION_GT goto exprend_binary
	if c == EXPRESSION_LEQ goto exprend_binary
	if c == EXPRESSION_GEQ goto exprend_binary
	if c == EXPRESSION_EQ goto exprend_binary
	if c == EXPRESSION_NEQ goto exprend_binary
	if c == EXPRESSION_BITWISE_AND goto exprend_binary
	if c == EXPRESSION_BITWISE_XOR goto exprend_binary
	if c == EXPRESSION_BITWISE_OR goto exprend_binary
	if c == EXPRESSION_LOGICAL_AND goto exprend_binary
	if c == EXPRESSION_LOGICAL_OR goto exprend_binary
	if c == EXPRESSION_CONDITIONAL goto exprend_conditional
	if c == EXPRESSION_ASSIGN goto exprend_binary
	if c == EXPRESSION_ASSIGN_ADD goto exprend_binary
	if c == EXPRESSION_ASSIGN_SUB goto exprend_binary
	if c == EXPRESSION_ASSIGN_MUL goto exprend_binary
	if c == EXPRESSION_ASSIGN_DIV goto exprend_binary
	if c == EXPRESSION_ASSIGN_REMAINDER goto exprend_binary
	if c == EXPRESSION_ASSIGN_LSHIFT goto exprend_binary
	if c == EXPRESSION_ASSIGN_RSHIFT goto exprend_binary
	if c == EXPRESSION_ASSIGN_AND goto exprend_binary
	if c == EXPRESSION_ASSIGN_XOR goto exprend_binary
	if c == EXPRESSION_ASSIGN_OR goto exprend_binary
	if c == EXPRESSION_COMMA goto exprend_binary
	
	:exprend_8data
		return expr + 16
	:exprend_unary
		expr += 8
		return expression_get_end(expr)
	:exprend_binary
		expr += 8
		expr = expression_get_end(expr)
		return expression_get_end(expr)
	:exprend_conditional
		expr += 8
		expr = expression_get_end(expr)
		expr = expression_get_end(expr)
		return expression_get_end(expr)
	:exprend_call
		expr += 8
		expr = expression_get_end(expr)
		:exprend_call_loop
			if *1expr == 0 goto exprend_call_loop_end
			expr = expression_get_end(expr)
			goto exprend_call_loop
		:exprend_call_loop_end
		return expr + 8
	:exprend_member
		expr += 8
		expr = expression_get_end(expr)
		return expr + 8
	
; returns pointer to end of expression data	
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
	p = tokens
	best = 0
	best_precedence = 1000
	:expr_find_operator_loop
		if p >= tokens_end goto expr_find_operator_loop_end
		n = p
		c = *1p
		p += 16
		if depth > 0 goto expr_findop_not_new_best
		if depth < 0 goto expr_too_many_closing_brackets
		a = operator_precedence(n, tokens)
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
	a = *4a
	p = best + 16
	if c == EXPRESSION_CALL goto parse_call
	if c != EXPRESSION_SUBSCRIPT goto binary_not_subscript
	tokens_end -= 16
	if *1tokens_end != SYMBOL_RSQUARE goto unrecognized_expression
	:binary_not_subscript
	
	b = out + 4 ; type of second operand
	out = parse_expression(p, tokens_end, out) ; second operand
	b = *4b
	
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
	if c == EXPRESSION_ASSIGN goto type_binary_left
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
	
	puts(.str_binop_this_shouldnt_happen)
	exit(1)
	:str_binop_this_shouldnt_happen
		string Bad binop symbol (this shouldn't happen).
		byte 10
		byte 0	
	
	:type_plus
		type_decay_array_to_pointer_in_place(a)
		type_decay_array_to_pointer_in_place(b)
		p = types + a
		if *1p == TYPE_POINTER goto type_binary_left ; pointer plus integer
		p = types + b
		if *1p == TYPE_POINTER goto type_binary_right ; integer plus pointer
		goto type_binary_usual
	:type_minus
		type_decay_array_to_pointer_in_place(a)
		type_decay_array_to_pointer_in_place(b)
		p = types + a
		if *1p == TYPE_POINTER goto type_minus_left_ptr
		goto type_binary_usual
		:type_minus_left_ptr
		p = types + b
		if *1p == TYPE_POINTER goto type_long ; pointer difference
		goto type_binary_left ; pointer minus integer
	:type_subscript
		; @NONSTANDARD: technically 1["hello"] is legal. but why
		type_decay_array_to_pointer_in_place(a)
		p = types + b
		if *1p > TYPE_UNSIGNED_LONG goto subscript_non_integer
		p = types + a
		if *1p == TYPE_POINTER goto type_subscript_pointer
		goto subscript_bad_type
		:type_subscript_pointer
			b = a + 1
			*4type = type_create_copy(b)
			return out
		:subscript_bad_type
			token_error(tokens, .str_subscript_bad_type)
		:str_subscript_bad_type
			string Subscript of non-pointer type.
			byte 0
		:subscript_non_integer
			token_error(tokens, .str_subscript_non_integer)
		:str_subscript_non_integer
			string Subscript index is not an integer.
			byte 0
	; apply the "usual conversions"
	:type_binary_usual
		*4type = expr_binary_type_usual_conversions(tokens, a, b)
		return out
	; like type_binary_usual, but the operands must be integers
	:type_binary_usual_integer
		*4type = expr_binary_type_usual_conversions(tokens, a, b)
		p = types + *4type
		if *1p >= TYPE_FLOAT goto expr_binary_bad_types
		return out
	:type_binary_left_integer
		p = types + a
		if *1p >= TYPE_FLOAT goto expr_binary_bad_types
		p = types + b
		if *1p >= TYPE_FLOAT goto expr_binary_bad_types
		goto type_binary_left
	:type_binary_left
		*4type = a
		return out
	:type_binary_right
		*4type = b
		return out
	:type_shift
		p = types + a
		if *1p >= TYPE_FLOAT goto expr_binary_bad_types
		p = types + b
		if *1p >= TYPE_FLOAT goto expr_binary_bad_types
		*4type = type_promotion(a)
		return out
	; the type here is just int
	:type_int
		*4type = TYPE_INT
		return out
	:type_long
		*4type = TYPE_LONG
		return out
	:expr_binary_bad_types
		bad_types_to_operator(tokens, a, b)
	
	:parse_call
		local arg_type
		local param_type
		; type call
		b = types + a
		if *1b == TYPE_FUNCTION goto type_call_cont
		if *1b != TYPE_POINTER goto calling_nonfunction
		b += 1 ; handle calling function pointer
		if *1b != TYPE_FUNCTION goto calling_nonfunction
		:type_call_cont
		b -= types
		*4type = functype_return_type(b)
		param_type = b + 1
		
		:call_args_loop
			if *1p == SYMBOL_RPAREN goto call_args_loop_end
			n = token_next_semicolon_comma_rbracket(p)
			*1out = EXPRESSION_CAST ; generate cast to proper argument type
			arg_type = out + 4
			out += 8
			b = out + 4
			out = parse_expression(p, n, out)
			*4arg_type = type_create_copy(*4b)
			b = types + param_type
			if *1b == 0 goto arg_is_varargs ; reached the end of arguments (so presumably this function has varargs)
			; set argument type to parameter type. this is necessary because:
			;  float f(float t) { return 2*t; } 
			;  float g(int x) { return f(x); } <- x passed as a float
			*4arg_type = param_type
			param_type += type_length(param_type)
			goto call_arg_type_cont
			:arg_is_varargs
			type_promote_float_to_double(*4arg_type)
			type_decay_array_to_pointer_in_place(*4arg_type)
			:call_arg_type_cont
			
			p = n
			if *1p == SYMBOL_RPAREN goto call_args_loop_end
			if *1p != SYMBOL_COMMA goto bad_call
			p += 16
			goto call_args_loop
		:call_args_loop_end
		p += 16
		if p != tokens_end goto stuff_after_call
		
		
		*8out = 0
		out += 8
		return out
		:calling_nonfunction
			token_error(p, .str_calling_nonfunction)
		:str_calling_nonfunction
			string Calling non-function.
			byte 0
		:bad_call
			token_error(p, .str_bad_call)
		:str_bad_call
			string Bad function call.
			byte 0
		:stuff_after_call
			token_error(p, .str_stuff_after_call)
		:str_stuff_after_call
			string Unexpected stuff after function call.
			byte 0
	:parse_expr_unary
		if c == KEYWORD_SIZEOF goto parse_sizeof
		*1out = unary_op_to_expression_type(c)
		c = *1out
		if c == EXPRESSION_CAST goto parse_cast
		out += 8
		a = out + 4 ; type of operand
		p = tokens + 16
		out = parse_expression(p, tokens_end, out)
		a = *4a
		if c == EXPRESSION_BITWISE_NOT goto unary_type_integral
		if c == EXPRESSION_UNARY_PLUS goto unary_type_promote
		if c == EXPRESSION_UNARY_MINUS goto unary_type_promote
		if c == EXPRESSION_LOGICAL_NOT goto unary_type_logical_not
		if c == EXPRESSION_ADDRESS_OF goto unary_address_of
		if c == EXPRESSION_DEREFERENCE goto unary_dereference
		if c == EXPRESSION_PRE_INCREMENT goto unary_type_scalar_nopromote
		if c == EXPRESSION_PRE_DECREMENT goto unary_type_scalar_nopromote
		puts(.str_unop_this_shouldnt_happen)
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
		
		parse_type_declarators(cast_prefix, cast_suffix, cast_suffix, cast_suffix_end, 0)
		parse_base_type(cast_base_type)
		
		p = cast_suffix_end
		
		if *1p != SYMBOL_RPAREN goto bad_cast ; e.g. (int ,)5
		out += 4
		*4out = a
		out += 4
		p += 16
		a = out + 4 ; pointer to casted expression type
		out = parse_expression(p, tokens_end, out)
		type_decay_array_to_pointer_in_place(*4a)
		return out
		:bad_cast
			token_error(tokens, .str_bad_cast)
		:str_bad_cast
			string Bad cast.
			byte 0		
	:unary_address_of
		*4type = type_create_pointer(a)
		return out
	:unary_dereference
		type_decay_array_to_pointer_in_place(a)
		p = types + a
		if *2p == TYPE2_FUNCTION_POINTER goto type_deref_fpointer
		if *1p != TYPE_POINTER goto unary_bad_type
		b = a + 1
		*4type = type_create_copy(b)
		return out
		:type_deref_fpointer
		*4type = a
		return out
	:unary_type_logical_not
		type_decay_array_to_pointer_in_place(a)
		p = types + a
		if *1p > TYPE_POINTER goto unary_bad_type
		*4type = TYPE_INT
		return out
	:unary_type_integral
		p = types + a
		if *1p >= TYPE_FLOAT goto unary_bad_type
		goto unary_type_promote
	:unary_type_promote
		p = types + a
		if *1p > TYPE_DOUBLE goto unary_bad_type
		*4type = type_promotion(a)
		return out
	:unary_type_scalar_nopromote
		p = types + a
		if *1p > TYPE_POINTER goto unary_bad_type
		*4type = a
		return out
	:unary_bad_type
		print_token_location(tokens)
		puts(.str_unary_bad_type)
		print_type(a)
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
			parse_type_declarators(sizeof_prefix, sizeof_suffix, sizeof_suffix, sizeof_suffix_end, 0)
			parse_base_type(sizeof_base_type)
			if *1p != SYMBOL_RPAREN goto bad_expression ; e.g. sizeof(int ,)
			p += 16
			if p != tokens_end goto stuff_after_sizeof_type
			*8out = type_sizeof(a)
			goto parse_sizeof_finish
			:stuff_after_sizeof_type
				token_error(sizeof_suffix_end, .str_stuff_after_sizeof_type)
			:str_stuff_after_sizeof_type
				string Unrecognized stuff after sizeof(T).
				byte 0
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
		if *1a == 0 goto use_of_incomplete_struct
		p += 8
		c = ident_list_lookup(a, *8p)
		if c == 0 goto member_not_in_struct
		
		*4type = c > 32 ; type
		*4type = type_create_copy(*4type)
		*4out = c & 0xffffffff ; offset
		out += 4
		*4out = type_is_array(*4type)
		out += 4
		p += 8
		
		if p != tokens_end goto bad_expression ; e.g. foo->bar hello
		return out
		:use_of_incomplete_struct
			token_error(p, .str_use_of_incomplete_struct)
		:str_use_of_incomplete_struct
			string Use of incomplete struct.
			byte 0
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
			p -= 8
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
		a = out + 4
		out = parse_expression(tokens, best, out)
		type_decay_array_to_pointer_in_place(*4a)
		
		; check type of "condition"
		b = types + *4a
		if *1b > TYPE_POINTER goto bad_condition_type
		
		a = out + 4 ; type of left branch of conditional
		best += 16
		out = parse_expression(best, p, out)
		type_decay_array_to_pointer_in_place(*4a)
		b = out + 4 ; type of right branch of conditional
		p += 16
		out = parse_expression(p, tokens_end, out)
		type_decay_array_to_pointer_in_place(*4b)
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
		:bad_condition_type
			token_error(tokens, .str_bad_condition_type)
		:str_bad_condition_type
			string Bad condition type for conditional operator (? :).
			byte 0
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
		
		n = block_depth
		:var_lookup_loop
			; check if it's a block static variable
			p = block_static_variables
			p += n < 3
			c = ident_list_lookup(*8p, a)
			if c != 0 goto found_global_variable
			p = local_variables
			p += n < 3
			c = ident_list_lookup(*8p, a)
			if c != 0 goto found_local_variable
			n -= 1
			if n >= 0 goto var_lookup_loop
		
		; check if it's a global
		c = ident_list_lookup(global_variables, a)
		if c == 0 goto not_global
		:found_global_variable
			; it is a global variable
			*1out = EXPRESSION_GLOBAL_VARIABLE
			out += 4
			a = c > 32 ; extract type
			*4out = type_create_copy(a)
			out += 4
			*4out = c & 0xffffffff ; extract address
			out += 4
			*4out = type_is_array(a)
			out += 4
			return out
		:not_global
		
		; it must be a function
		c = ident_list_lookup(function_types, a)
		if c == 0 goto undeclared_variable
		*1out = EXPRESSION_FUNCTION
		out += 4
		*4out = type_create_pointer(c)
		out += 4
		*8out = a
		out += 8
		return out
		:undeclared_variable
			; @NONSTANDARD: C89 allows calling functions without declaring them
			token_error(in, .str_undeclared_variable)
		:str_undeclared_variable
			string Undeclared variable.
			byte 0
		
		:found_local_variable
			; it's a local variable
			*1out = EXPRESSION_LOCAL_VARIABLE
			out += 4
			a = c > 32 ; extract type
			*4out = type_create_copy(a)
			out += 4
			c &= 0xffffffff ; extract rbp offset
			*4out = c
			out += 4
			*4out = type_is_array(a)
			out += 4
			return out
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
		
		; the type of this is array of n chars, where n = strlen(s)+1
		type = types + types_bytes_used
		*1type = TYPE_ARRAY
		type += 1
		p = output_file_data + value
		*8type = strlen(p)
		*8type += 1
		type += 8
		*1type = TYPE_CHAR
		
		p = out + 4
		*4p = types_bytes_used
		types_bytes_used += 10 ; TYPE_ARRAY + length + TYPE_CHAR
		
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

; if type is an array type, turn it into a pointer.
;   e.g.
;    char s[] = "hello";
;    char *t = s + 3; /* s "decays" into a pointer */
function type_decay_array_to_pointer_in_place
	argument type
	local dest
	local src
	src = types + type
	if *1src != TYPE_ARRAY goto return_0
	dest = types + type
	*1dest = TYPE_POINTER
	src = type + 9 ; skip TYPE_ARRAY and size
	dest = type + 1 ; skip TYPE_POINTER
	type_copy_ids(dest, src)
	return
	

; change type to `double` if it's `float`
; in C, float arguments have to be passed as double for varargs
;  there is also a rule that char/short/int are passed as ints, but we don't need to worry about it since we're passing everything as >=8 bytes.
function type_promote_float_to_double
	argument type
	local p
	p = types + type
	if *1p != TYPE_FLOAT goto return_0
	*1p = TYPE_DOUBLE
	return

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
	; void has a size of 1 for good reasons:
	;   - void pointer addition isn't standard, but it makes most sense to treat it the same as char* addition
	;   - code generation reasons
	if c == TYPE_VOID goto return_1
	if c == TYPE_POINTER goto return_8
	if c == TYPE_FUNCTION goto return_1
	if c == TYPE_ARRAY goto sizeof_array
	if c == TYPE_STRUCT goto sizeof_struct
	
	puts(.str_sizeof_bad)
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
	
	puts(.str_alignof_bad)
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
; @NONSTANDARD: only allows double-precision floating-point literals or 0; otherwise floats aren't allowed in constant expressions.
;                     this means you can't do
;                 e.g. float x[] = {1,2,3};  or   double x[] = {1.5+2.3, 5.5*6.4};
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
	p = types + type
	if *1p == TYPE_FLOAT goto bad_constexpr
	if c == EXPRESSION_CONSTANT_FLOAT goto eval_constant_float
	if c == EXPRESSION_UNARY_PLUS goto eval_unary_plus
	if c == EXPRESSION_UNARY_MINUS goto eval_unary_minus
	
	; only 0 and floating-point constants are supported as double initializers
	if *1p == TYPE_DOUBLE goto bad_constexpr
	
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
	
	:bad_constexpr
	token_error(token, .str_eval_bad_exprtype)
	
	:str_eval_bad_exprtype
		string Can't evaluate constant expression.
		byte 0
	:eval_cast
		p = types + type
		c = *1p
		if c == TYPE_VOID goto eval_cast_bad_type
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
	:eval_constant_float
		expr += 8
		*8p_value = *8expr
		expr += 8
		return expr
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
		p = types + type
		if *1p == TYPE_DOUBLE goto eval_minus_double
		*8p_value = 0 - a
		goto eval_fit_to_type
		:eval_minus_double
			*8p_value = 0x8000000000000000 ^ a
			return expr
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
	puts(.str_bad_fit_to_type)
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
	
	print_token_location(token)
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
	argument first_token
	local p_op
	local op
	local b
	
	if token == first_token goto operator_precedence_unary
	
	; if an operator is preceded by another, it must be a unary operator, e.g.
	;   in `5 + *x`, * is a unary operator
	p_op = token - 16
	:figure_out_arity
	op = *1p_op
	if op == SYMBOL_RPAREN goto figre_out_rparen_arity
	if op == SYMBOL_PLUS_PLUS goto figure_out_bimodal_arity
	if op == SYMBOL_MINUS_MINUS goto figure_out_bimodal_arity
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
	goto return_0xe0 ; it's a cast
	
	:figure_out_bimodal_arity
	; ++ and -- can act either as unary or binary operators.
	if p_op == first_token goto operator_precedence_unary ; e.g. ++*x
	; reverse one further to figure out which it is.
	p_op -= 16
	goto figure_out_arity
	
	
	:figre_out_rparen_arity
	; given that the token before this one is a right-parenthesis, figure out if
	; this is a unary or binary operator. this is (annoyingly) necessary, because:
	;  (y)-x;     /* subtraction processed first */
	;  (int)-x;   /* cast processed first */
	;  sizeof(int)-x;  /* subtraction processed first */
	local p
	p = token - 16
	token_reverse_to_matching_lparen(&p)
	p += 16
	b = token_is_type(p)
	if b != 0 goto rparen_might_be_cast
	goto operator_precedence_binary ; e.g. (y)-x;
	:rparen_might_be_cast
		p -= 32
		if *1p != KEYWORD_SIZEOF goto operator_precedence_unary ; e.g. (int)-x
		goto operator_precedence_binary ; e.g. sizeof(int)-x
	
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
	return EXPRESSION_PRE_DECREMENT
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
	byte SYMBOL_LPAREN
	byte EXPRESSION_CALL
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
	argument token_type
	local b
	b = binop_symbol_to_expression_type(token_type)
	if b != 0 goto return_1
	b = unary_op_to_expression_type(token_type)
	if b != 0 goto return_1
	if token_type == KEYWORD_SIZEOF goto return_1
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
	
	if c == EXPRESSION_FUNCTION goto print_expr_function
	if c == EXPRESSION_LOCAL_VARIABLE goto print_local_variable
	if c == EXPRESSION_GLOBAL_VARIABLE goto print_global_variable
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
	if c == EXPRESSION_CALL goto print_call
	if c == EXPRESSION_CONDITIONAL goto print_conditional

	b = binop_expression_type_to_symbol(c)
	if b != 0 goto print_expr_binop
	
	puts(.str_print_bad_expr)
	exit(1)
	
	:str_print_bad_expr
		string Bad expression passed to print_expression.
		byte 10
		byte 0
	:str_global_at
		string global@
		byte 0
	:print_local_variable
		puts(.str_local_prefix)
		expression += 8
		b = sign_extend_32_to_64(*4expression)
		putn_with_sign(b)
		putc('])
		expression += 8
		return expression
	:str_local_prefix
		string [rbp
		byte 0
	:print_expr_function
		expression += 8
		puts(*8expression)
		expression += 8
		return expression
	:print_global_variable
		puts(.str_global_at)
		expression += 8
		putx32(*4expression)
		expression += 8
		return expression
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
	:print_conditional
		putc(40)
		expression += 8
		expression = print_expression(expression)
		putc(32)
		putc('?)
		putc(32)
		expression = print_expression(expression)
		putc(32)
		putc(':)
		putc(32)
		expression = print_expression(expression)
		putc(41)
		return expression
	:print_expr_dot
		putc(40)
		expression += 8
		expression = print_expression(expression)
		puts(.str_dot)
		putn(*4expression)
		expression += 8
		putc(41)
		return expression
	:print_expr_arrow
		putc(40)
		expression += 8
		expression = print_expression(expression)
		puts(.str_arrow)
		putn(*4expression)
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
	:print_call
		putc(40)
		expression += 8
		expression = print_expression(expression) ; function name
		putc(40)
		:print_call_loop
			if *1expression == 0 goto print_call_loop_end
			expression = print_expression(expression)
			putc(44)
			goto print_call_loop
		:print_call_loop_end
		putc(41)
		expression += 8
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
	puts(.str_bad_print_type)
	putnln(type)
	putnln(c)
	putnln(types_bytes_used)
	exit(1)
	:str_bad_print_type
		string Bad type passed to print_type:
		byte 32
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
		putn(*8c)
		putc('])
		type += 8
		goto print_type_top
	:print_type_struct
		puts(.str_struct)
		c = types + type
		c += 1
		putc('@)
		putx64(*8c)
		return
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
