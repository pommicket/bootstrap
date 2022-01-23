function parse_tokens
	argument tokens
	local token
	local ident
	local type
	
	token = tokens
	:parse_tokens_loop
		if *1token == TOKEN_EOF goto parse_tokens_eof
		if *1token == KEYWORD_TYPEDEF goto parse_typedef
		
		byte 0xcc ; not implemented
		
		:parse_typedef
			token += 16
			type = parse_type(&token, &ident)
			puts(ident)
			putc(10)
			print_type(type)
			putc(10)
			exit(0)
	:parse_tokens_eof
	return


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


; parse things like  `int x` or `int f(void, int, char *)`
; advances *p_token and sets *p_ident to a pointer to the identifier (or 0 if this is just a type)
; returns type ID
function parse_type
	argument p_token
	argument p_ident
	local type
	local p
	local n
	type = types_bytes_used
	p = types + type
	n = parse_type_to(p_token, p_ident, p)
	types_bytes_used = n - types
	return type
	
; like parse_type, but outputs to out.
; returns new position of out, after type gets put there
function parse_type_to
	; split types into prefix (P) and suffix (S)
	;     struct Thing (*things[5])(void);
	;     PPPPPPPPPPPPPPP      SSSSSSSSSS
	; Here, we call `struct Thing` the "base type".
	
	argument p_token
	argument p_ident
	argument out ; pointer to type
	local token
	local c
	local p
	local n
	local base_type_end
	local depth
	local prefix
	local prefix_end
	local suffix
	local suffix_end
	
	token = *8p_token
	prefix = token
	*8p_ident = 0
	
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
		goto find_prefix_end
		:skip_base_type_loop_cont
			token += 16
			goto skip_base_type_loop
	
	:find_prefix_end
	; find end of prefix
	base_type_end = token
	
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
	prefix_end = token
	
	if *1token != TOKEN_IDENTIFIER goto parse_type_no_ident
	token += 8
	*8p_ident = *8token
	token += 8
	:parse_type_no_ident
	
	
	suffix = token
	
	; find end of suffix
	token = base_type_end ; start back here so we can keep track of bracket depth
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
		if c == TOKEN_EOF goto bad_type
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
	
	suffix_end = token
	
#define TYPEDEBUG ;
	TYPEDEBUG putc('B)
	TYPEDEBUG putc('a)
	TYPEDEBUG putc('s)
	TYPEDEBUG putc(':)
	TYPEDEBUG putc(32)
	TYPEDEBUG print_tokens(*8p_token, base_type_end)
	TYPEDEBUG putc('P)
	TYPEDEBUG putc('r)
	TYPEDEBUG putc('e)
	TYPEDEBUG putc(':)
	TYPEDEBUG putc(32)
	TYPEDEBUG print_tokens(prefix, prefix_end)
	TYPEDEBUG putc('S)
	TYPEDEBUG putc('u)
	TYPEDEBUG putc('f)
	TYPEDEBUG putc(':)
	TYPEDEBUG putc(32)
	TYPEDEBUG print_tokens(suffix, suffix_end)
	
	; main loop for parsing types
	:parse_type_loop
		p = prefix_end - 16
		if *1suffix == SYMBOL_LSQUARE goto parse_array_type
		if *1suffix == SYMBOL_LPAREN goto parse_function_type
		if *1p == SYMBOL_TIMES goto parse_pointer_type
		if suffix == suffix_end goto parse_base_type
		if *1suffix == SYMBOL_RPAREN goto parse_type_remove_parentheses
		
		
		:parse_pointer_type
			*1out = TYPE_POINTER
			out += 1
			prefix_end = p
			goto parse_type_loop
		:parse_array_type
			local expr
			expr = malloc(4000)
			*1out = TYPE_ARRAY
			out += 1
			p = suffix
			token_skip_to_matching_rsquare(&p)
			suffix += 16 ; skip [
			parse_expression(suffix, p, expr)
			evaluate_constant_expression(expr, &n)
			if n < 0 goto bad_array_size
			*8out = n
			out += 8
			free(expr)
			suffix = p + 16
			goto parse_type_loop
			:bad_array_size
				token_error(*8p_token, .str_bad_array_size)
			:str_bad_array_size
				string Very large or negative array size.
				byte 0 
		:parse_function_type
			p = suffix + 16
			local RRR
			RRR = out
			*1out = TYPE_FUNCTION
			out += 1
			:function_type_loop
				if *1p == SYMBOL_RPAREN goto function_type_loop_end ; only needed for 1st iteration
				out = parse_type_to(&p, &c, out)
				if *1p == SYMBOL_RPAREN goto function_type_loop_end
				if *1p != SYMBOL_COMMA goto bad_type
				p += 16
				goto function_type_loop
			:function_type_loop_end
			*1out = 0
			out += 1
			suffix = p + 16
			goto parse_type_loop
		:parse_type_remove_parentheses
			if *1p != SYMBOL_LPAREN goto bad_type
			prefix_end = p
			suffix += 16
			goto parse_type_loop
	:parse_base_type
	if *1prefix == TOKEN_IDENTIFIER goto base_type_typedef
	if *1prefix == KEYWORD_STRUCT goto base_type_struct
	if *1prefix == KEYWORD_UNION goto base_type_union
	if *1prefix == KEYWORD_ENUM goto base_type_enum
	if *1prefix == KEYWORD_FLOAT goto base_type_float
	if *1prefix == KEYWORD_VOID goto base_type_void
	
	; "normal" type like int, unsigned char, etc.
	local flags
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
	p = prefix
	:base_type_normal_loop
		c = *1p
		p += 16
		; yes, this allows for `int int x;` but whatever
		if c == KEYWORD_CHAR goto base_type_flag_char
		if c == KEYWORD_SHORT goto base_type_flag_short
		if c == KEYWORD_INT goto base_type_flag_int
		if c == KEYWORD_LONG goto base_type_flag_long
		if c == KEYWORD_UNSIGNED goto base_type_flag_unsigned
		if c == KEYWORD_DOUBLE goto base_type_flag_double
		goto base_type_normal_loop_end
		:base_type_flag_char
			flags |= PARSETYPE_FLAG_CHAR
			goto base_type_normal_loop
		:base_type_flag_short
			flags |= PARSETYPE_FLAG_SHORT
			goto base_type_normal_loop
		:base_type_flag_int
			flags |= PARSETYPE_FLAG_INT
			goto base_type_normal_loop
		:base_type_flag_long
			flags |= PARSETYPE_FLAG_LONG
			goto base_type_normal_loop
		:base_type_flag_unsigned
			flags |= PARSETYPE_FLAG_UNSIGNED
			goto base_type_normal_loop
		:base_type_flag_double
			flags |= PARSETYPE_FLAG_DOUBLE
			goto base_type_normal_loop
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
	*8p_token = suffix_end
	return out
	:base_type_struct
		byte 0xcc ; @TODO
	:base_type_union
		byte 0xcc ; @TODO
	:base_type_enum
		byte 0xcc ; @TODO
	:base_type_float
		*1out = TYPE_FLOAT
		out += 1
		goto base_type_done
	:base_type_void
		*1out = TYPE_VOID
		out += 1
		goto base_type_done	
	:base_type_typedef
		p = prefix + 8
		c = ident_list_lookup(typedefs, *8p)
		n = type_length(c)
		out = memcpy(out, c, n)
		goto base_type_done
	
	:skip_struct_union_enum
		token += 16
		if *1token != TOKEN_IDENTIFIER goto skip_sue_no_name
			token += 16 ; struct *blah*
		:skip_sue_no_name
		if *1token != SYMBOL_LBRACE goto find_prefix_end ; e.g. struct Something x[5];
		; okay we have something like
		;   struct {
		;       int x, y;
		;   } test;
		token_skip_to_matching_rbrace(&token)
		token += 16
		goto find_prefix_end
	:bad_type
		token_error(*8p_token, .str_bad_type)
	:str_bad_type
		string Bad type.
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
	if *1p == TYPE_STRUCT goto return_5
	if *1p == TYPE_UNION goto return_5
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
	;@TODO: casts
	
	
	:parse_expr_unary
		if c == KEYWORD_SIZEOF goto parse_expr_sizeof
		*1out = unary_op_to_expression_type(c)
		c = *1out
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
	
	:parse_expr_sizeof
		byte 0xcc ; @TODO
	
	:parse_expr_member ; -> or .
		p = best + 16
		if *1p != TOKEN_IDENTIFIER goto bad_expression
		p += 8
		*8out = *8p ; copy identifier name
		p += 8
		if p != tokens_end goto bad_expression ; e.g. foo->bar hello
		out += 8
		out = parse_expression(tokens, best, out)
		; @TODO: typing
		return out
		
	
	:parse_conditional
		byte 0xcc ; @TODO
	
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
		goto unrecognized_expression
	
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
		*1out = EXPRESSION_STRING_LITERAL
		p = in + 8
		value = *8p
		p = out + 8
		*8p = value
		
		; we already know this is char*
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

; evaluate an expression which can be the size of an array, e.g.
;    enum { A, B, C };
;    int x[A * sizeof(float) + 3 << 5];
; @NONSTANDARD: doesn't handle floats, but really why would you use floats in an array size
;                 e.g.   SomeType x[(int)3.3];
; this is also used for #if evaluation
; NOTE: this returns the end of the expression, not the value (which is stored in *8p_value)
function evaluate_constant_expression
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
	if c == EXPRESSION_IDENTIFIER goto eval_constant_identifier
	if c == EXPRESSION_UNARY_PLUS goto eval_unary_plus
	if c == EXPRESSION_UNARY_MINUS goto eval_unary_minus
	if c == EXPRESSION_BITWISE_NOT goto eval_bitwise_not
	if c == EXPRESSION_LOGICAL_NOT goto eval_logical_not
	if c == EXPRESSION_CAST goto eval_todo ; @TODO
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
	if c == EXPRESSION_CONDITIONAL goto eval_todo ; @TODO
	
	byte 0xcc
	
	:eval_todo
		fputs(2, .str_eval_todo)
		exit(1)
	:str_eval_todo
		string evaluate_constant_expression does not support this kind of expression yet (see @TODOs).
		byte 0

	:eval_constant_identifier
		; @TODO: enum values
		fputs(2, .str_constant_identifier)
		exit(1)
		:str_constant_identifier
			string Constant identifiers not handled (see @TODO).
			byte 10
			byte 0
	:eval_constant_int
		expr += 8
		*8p_value = *8expr
		expr += 8
		return expr
	:eval_unary_plus
		expr += 8
		expr = evaluate_constant_expression(expr, p_value)
		return expr
	:eval_unary_minus
		expr += 8
		expr = evaluate_constant_expression(expr, &a)
		*8p_value = 0 - a
		goto eval_fit_to_type
	:eval_bitwise_not
		expr += 8
		expr = evaluate_constant_expression(expr, &a)
		*8p_value = ~a
		goto eval_fit_to_type
	:eval_logical_not
		expr += 8
		expr = evaluate_constant_expression(expr, &a)
		if a == 0 goto eval_value_1
		goto eval_value_0
	:eval_add
		expr += 8
		expr = evaluate_constant_expression(expr, &a)
		expr = evaluate_constant_expression(expr, &b)
		*8p_value = a + b
		goto eval_fit_to_type
	:eval_sub
		expr += 8
		expr = evaluate_constant_expression(expr, &a)
		expr = evaluate_constant_expression(expr, &b)
		*8p_value = a - b
		goto eval_fit_to_type
	:eval_mul
		expr += 8
		expr = evaluate_constant_expression(expr, &a)
		expr = evaluate_constant_expression(expr, &b)
		*8p_value = a * b
		goto eval_fit_to_type
	:eval_div
		expr += 8
		expr = evaluate_constant_expression(expr, &a)
		expr = evaluate_constant_expression(expr, &b)
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
		expr = evaluate_constant_expression(expr, &a)
		expr = evaluate_constant_expression(expr, &b)
		p = types + type
		if *1p == TYPE_UNSIGNED_LONG goto eval_rem_unsigned
			*8p_value = a % b
			goto eval_fit_to_type
		:eval_rem_unsigned
			divmod_unsigned(a, b, &a, p_value)
			goto eval_fit_to_type
	:eval_lshift
		expr += 8
		expr = evaluate_constant_expression(expr, &a)
		expr = evaluate_constant_expression(expr, &b)
		*8p_value = a < b
		goto eval_fit_to_type
	:eval_rshift
		expr += 8
		expr = evaluate_constant_expression(expr, &a)
		expr = evaluate_constant_expression(expr, &b)
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
		expr = evaluate_constant_expression(expr, &a)
		expr = evaluate_constant_expression(expr, &b)
		
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
		expr = evaluate_constant_expression(expr, &a)
		expr = evaluate_constant_expression(expr, &b)
		*8p_value = a & b
		goto eval_fit_to_type
	:eval_bitwise_or
		expr += 8
		expr = evaluate_constant_expression(expr, &a)
		expr = evaluate_constant_expression(expr, &b)
		*8p_value = a | b
		goto eval_fit_to_type
	:eval_bitwise_xor
		expr += 8
		expr = evaluate_constant_expression(expr, &a)
		expr = evaluate_constant_expression(expr, &b)
		*8p_value = a ^ b
		goto eval_fit_to_type
	:eval_logical_and
		expr += 8
		expr = evaluate_constant_expression(expr, &a)
		if a == 0 goto eval_value_0
		expr = evaluate_constant_expression(expr, &b)
		if b == 0 goto eval_value_0
		goto eval_value_1
	:eval_logical_or
		expr += 8
		expr = evaluate_constant_expression(expr, &a)
		if a != 0 goto eval_value_1
		expr = evaluate_constant_expression(expr, &b)
		if b != 0 goto eval_value_1
		goto eval_value_0
		
		
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
	
	if is_first != 0 goto operator_precedence_unary
	
	; if an operator is preceded by another, it must be a unary operator, e.g.
	;   in 5 + *x, * is a unary operator
	op = token - 16
	op = *1op
	op = is_operator(op)
	if op != 0 goto operator_precedence_unary
	
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
	
	return 0xffff

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


; is this operator right-associative? most C operators are left associative,
; but += / -= / etc. are not
function operator_right_associative
	argument op
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
	if c == EXPRESSION_STRING_LITERAL goto print_expr_str
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

	b = binop_expression_type_to_symbol(c)
	if b != 0 goto print_expr_binop
	
	puts(.str_print_bad_expr)
	exit(1)
	
	:str_print_bad_expr
		string Bad expression passed to print_expression.
		byte 10
		byte 0
	
	:print_expr_int
		expression += 8
		putn(*8expression)
		expression += 8
		return expression
	:print_expr_float
		expression += 8
		putx64(*8expression)
		expression += 8
		return expression
	:print_expr_str
		expression += 8
		putc('0)
		putc('x)
		putx32(*8expression)
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
		p = *8expression
		expression += 8
		expression = print_expression(expression)
		putc('.)
		puts(p)
		putc(41)
		return expression
	:print_expr_arrow
		putc(40)
		expression += 8
		p = *8expression
		expression += 8
		expression = print_expression(expression)
		puts(.str_arrow)
		puts(p)
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
	if c == TYPE_UNION goto print_type_union
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
	:print_type_union
		return puts(.str_union)
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
