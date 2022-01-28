; an "identifier list" is a list of identifiers and 64-bit values associated with them.
; they are stored as
;   null-terminated string
;   64-bit value (unaligned)
;   ...
;   null-terminated string
;   64-bit value (unaligned)
;   0 byte

function ident_list_create
	argument nbytes
	local list
	list = malloc(nbytes)
	return list

function ident_list_clear
	argument list
	*1list = 0
	return

function ident_list_free
	argument list
	free(list)
	return

function ident_list_len
	argument list
	local len
	len = 0
	:ilist_len_loop
		if *1list == 0 goto ilist_len_ret
		list = memchr(list, 0)
		list += 9 ; skip null byte and value
		len += 1
		goto ilist_len_loop
	:ilist_len_ret
	return len

function ident_list_value_at_index
	argument list
	argument idx
	:ilist_vai_loop
		if *1list == 0 goto return_0
		list = memchr(list, 0)
		list += 1
		if idx <= 0 goto ilist_vai_ret
		list += 8
		idx -= 1
		goto ilist_vai_loop
	:ilist_vai_ret
	return *8list
	

function ident_list_add
	argument list
	argument ident
	argument value
	
	:ilist_add_go_to_end_loop
		if *1list == 0 goto ilist_add_found_end
		list = memchr(list, 0)
		list += 9 ; skip null byte and value
		goto ilist_add_go_to_end_loop
	:ilist_add_found_end
	list = strcpy(list, ident)
	list += 1
	*8list = value ; UNALIGNED
	list += 8
	*1list = 0
	
	return

; return the value associated with this identifier, or 0 if none is
function ident_list_lookup
	argument list
	argument ident
	local b
	:ilist_lookup_loop
		if *1list == 0 goto return_0
		b = str_equals(list, ident)
		list = memchr(list, 0)
		list += 9 ; skip null byte and value
		if b == 0 goto ilist_lookup_loop
	list -= 8 ; backtrack to value
	return *8list ; UNALIGNED

; if identifier in list, sets *pvalue to its value (if pvalue is not null) and returns 1
; otherwise, returns 0
function ident_list_lookup_check
	argument list
	argument ident
	argument pvalue
	local b
	:ilist_lookcheck_loop
		if *1list == 0 goto return_0
		b = str_equals(list, ident)
		list = memchr(list, 0)
		list += 9 ; skip null byte and value
		if b == 0 goto ilist_lookcheck_loop
	if pvalue == 0 goto return_1
	list -= 8 ; backtrack to value
	*8pvalue = *8list
	return 1
	
function ident_list_print
	argument list
	:ilist_print_loop
		if *1list == 0 goto ilist_print_loop_end
		puts(list)
		putc(':)
		putc(32)
		list = memchr(list, 0)
		list += 1
		putnln(*8list)
		list += 8
		goto ilist_print_loop
	:ilist_print_loop_end
	return
	
function ident_list_printx64
	argument list
	:ilist_printx64_loop
		if *1list == 0 goto ilist_printx64_loop_end
		puts(list)
		putc(':)
		putc(32)
		list = memchr(list, 0)
		list += 1
		putx64ln(*8list)
		list += 8
		goto ilist_printx64_loop
	:ilist_printx64_loop_end
	return

function ident_list_printx32
	argument list
	:ilist_printx32_loop
		if *1list == 0 goto ilist_printx32_loop_end
		puts(list)
		putc(':)
		putc(32)
		list = memchr(list, 0)
		list += 1
		putx32ln(*8list)
		list += 8
		goto ilist_printx32_loop
	:ilist_printx32_loop_end
	return

