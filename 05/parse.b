; @TODO: fix 5 * *x being interpreted as (5*) * x
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
	b = 1 ; first token? -- i.e. is this operator unary
	p = tokens
	best = 0
	best_precedence = 1000
	goto expr_find_operator_loop_first
	:expr_find_operator_loop
		b = 0
		:expr_find_operator_loop_first
		if p >= tokens_end goto expr_find_operator_loop_end
		c = *1p
		p += 16
		if depth > 0 goto expr_findop_not_new_best
		if depth < 0 goto expr_too_many_closing_brackets
		n = p - 16
		a = operator_precedence(n, b)
		n = a
		n -= operator_right_associative(c) ; ensure that the leftmost += / -= / etc. is processed first
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
	
	c = *1best
	
	if best == tokens goto parse_expr_unary
	
	; it's a binary expression.
	if c == SYMBOL_PLUS_PLUS goto parse_postincrement
	if c == SYMBOL_MINUS_MINUS goto parse_postdecrement
	if c == SYMBOL_QUESTION goto parse_conditional
	*1out = binop_symbol_to_expression_type(c)
	out += 8
	if c == SYMBOL_DOT goto parse_expr_member
	if c == SYMBOL_ARROW goto parse_expr_member
	a = out + 4 ; type of first operand
	out = parse_expression(tokens, best, out) ; first operand
	p = best + 16
	b = out + 4 ; type of second operand
	if c != SYMBOL_LSQUARE goto binary_not_subscript
	tokens_end -= 16
	if *1tokens_end != SYMBOL_RSQUARE goto unrecognized_expression
	:binary_not_subscript
	out = parse_expression(p, tokens_end, out) ; second operand
	
	if c == SYMBOL_LSHIFT goto type_binary_left_promote
	if c == SYMBOL_RSHIFT goto type_binary_left_promote
	if c == SYMBOL_LSQUARE goto type_subscript
	if c == SYMBOL_EQ_EQ goto type_binary_comparison
	if c == SYMBOL_NOT_EQ goto type_binary_comparison
	if c == SYMBOL_LT_EQ goto type_binary_comparison
	if c == SYMBOL_GT_EQ goto type_binary_comparison
	if c == SYMBOL_LT goto type_binary_comparison
	if c == SYMBOL_GT goto type_binary_comparison
	if c < SYMBOL_EQ goto type_binary_usual
	if c > SYMBOL_OR_EQ goto type_binary_usual
	goto type_binary_left
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
	:type_binary_usual
		*4type = expr_binary_type_usual_conversions(tokens, *4a, *4b)
		return out
	:type_binary_comparison
		*4type = TYPE_INT
		return out
	:type_binary_left
		*4type = *4a
		return out
	:type_binary_left_promote
		*4type = type_promotion(*4a)
		return out
	
	return out
	;@TODO: casts
	
	
	:parse_expr_unary
		if c == KEYWORD_SIZEOF goto parse_expr_sizeof
		*1out = unary_op_to_expression_type(c)
		out += 8
		p = tokens + 16
		out = parse_expression(p, tokens_end, out)
		return out
	
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

function expr_binary_type_usual_conversions
	argument token ; for errors
	argument type1
	argument type2
	
	local ptype1
	local ptype2
	
	if type1 == 0 goto return_0
	if type2 == 0 goto return_0
	; @TODO: pointer types
	ptype1 = types + type1
	ptype2 = types + type2
	
	type1 = *1ptype1
	type2 = *1ptype2
	if type1 == TYPE_POINTER goto type1_pointer
	if type2 == TYPE_POINTER goto type2_pointer
	
	if type1 > TYPE_DOUBLE goto bad_types_to_operator
	if type2 > TYPE_DOUBLE goto bad_types_to_operator
	
	; "if either operand has type double, the other operand is converted to double"
	if type1 == TYPE_DOUBLE goto return_type_double
	if type2 == TYPE_DOUBLE goto return_type_double
	; "if either operand has type float, the other operand is converted to float"
	if type1 == TYPE_FLOAT goto return_type_float
	if type2 == TYPE_FLOAT goto return_type_float
	; "If either operand has type unsigned long int, the other operand is converted to unsigned long int"
	if type1 == TYPE_UNSIGNED_LONG goto return_type_unsigned_long
	if type2 == TYPE_UNSIGNED_LONG goto return_type_unsigned_long
	; "if either operand has type long int, the other operand is converted to long int"
	if type1 == TYPE_LONG goto return_type_long
	if type2 == TYPE_LONG goto return_type_long
	; "if either operand has type unsigned int, the other operand is converted to unsigned int."
	if type1 == TYPE_UNSIGNED_INT goto return_type_unsigned_int
	if type2 == TYPE_UNSIGNED_INT goto return_type_unsigned_int
	; "Otherwise, both operands have type int."
	goto return_type_int
	
	:type1_pointer
		if type2 == TYPE_POINTER goto return_type_long ; this must be a pointer difference
		return ptype1 - types ; e.g. p_int + 5
	:type2_pointer
		return ptype2 - types ; e.g. 5 + p_int
	
	:bad_types_to_operator
		fprint_token_location(2, token)
		fputs(2, .str_bad_types_to_operator)
		print_type(type1)
		fputs(2, .str_space_and_space)
		print_type(type2)
		putc(10)
		exit(1)
	:str_bad_types_to_operator
		string : Bad types to operator:
		byte 32
		byte 0
	:str_space_and_space
		string  and
		byte 32
		byte 0

function type_promotion
	argument type
	type = types + type
	if *1type < TYPE_INT goto return_type_int
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
		putn(*8type) ; UNALIGNED
		putc('])
		type += 8
		goto print_type_top
	:print_type_struct
		return puts(.str_struct)
	:print_type_union
		return puts(.str_union)
