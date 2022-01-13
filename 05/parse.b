function parse_expression
	argument tokens
	argument tokens_end
	argument out
	local in
	local a
	local b
	local c
	local p
	local value
	
	if tokens == tokens_end goto empty_expression
	p = tokens + 16
	if p == tokens_end goto single_token_expression
	
	goto unrecognized_expression
	
	:single_token_expression
		in = tokens
		c = *1in
		if c == TOKEN_CONSTANT_INT goto expression_integer
		if c == TOKEN_CONSTANT_CHAR goto expression_integer ; character constants are basically the same as integer constants
		if c == TOKEN_CONSTANT_FLOAT goto expression_float
		if c == TOKEN_STRING_LITERAL goto expression_string_literal
		byte 0xcc
	
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
	:unrecognized_expression
		token_error(tokens, .str_unrecognized_expression)
	:str_unrecognized_expression
		string Unrecognized expression.
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

function print_expression
	argument expression
	local c
	local p
	p = expression + 4
	putc(40)
	print_type(*4p)
	putc(41)
	c = *1expression
	
	if c == EXPRESSION_CONSTANT_INT goto print_expr_int
	if c == EXPRESSION_CONSTANT_FLOAT goto print_expr_float
	if c == EXPRESSION_STRING_LITERAL goto print_expr_str
	byte 0xcc
	:print_expr_int
		expression += 8
		putn(*8expression)
		return
	:print_expr_float
		expression += 8
		putx64(*8expression)
		return
	:print_expr_str
		expression += 8
		putc('0)
		putc('x)
		putx32(*8expression)
		return

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
