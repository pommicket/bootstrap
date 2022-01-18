; an "identifier list" is a list of identifiers and 64-bit values associated with them
; the values should be non-zero because 0 is returned for undefined identifiers.

function ident_list_create
	argument nbytes
	local list
	list = malloc(nbytes)
	*1list = 255
	return list

function ident_list_add
	argument list
	argument ident
	argument value
	
	list = memchr(list, 255)
	list = strcpy(list, ident)
	list += 1
	*8list = value ; UNALIGNED
	list += 8
	*1list = 255
	
	return

; return the value associated with this identifier, or 0 if none is
function ident_list_lookup
	argument list
	argument ident
	local b
	:ilist_lookup_loop
		if *1list == 255 goto return_0
		b = str_equals(list, ident)
		list = memchr(list, 0)
		list += 1
		if b == 0 goto ilist_lookup_loop
	return *8list ; UNALIGNED

function ident_list_print
	argument list
	:ilist_print_loop
		if *1list == 255 goto ilist_print_loop_end
		puts(list)
		putc(':)
		putc(32)
		list = memchr(list, 0)
		list += 1
		putn(*8list)
		list += 8
		goto ilist_print_loop
	:ilist_print_loop_end
	return
