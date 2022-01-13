; multiply two 64-bit signed numbers to a 128-bit number
function full_multiply_signed
	argument a
	argument b
	argument p_lower
	argument p_upper
	local lower
	local upper
	
	lower = a * b
	; mov rax, rdx
	byte 0x48
	byte 0x89
	byte 0xd0
	; mov [rbp-48] (upper), rax
	byte 0x48
	byte 0x89
	byte 0x85
	byte 0xd0
	byte 0xff
	byte 0xff
	byte 0xff
	
	*8p_lower = lower
	*8p_upper = upper
	return

; allows for negative shifts
function right_shift
	argument x
	argument n
	if n < 0 goto right_shift_negative
	return x > n
	:right_shift_negative
	n = 0 - n
	return x < n

; allows for negative shifts
function left_shift
	argument x
	argument n
	if n < 0 goto right_shift_negative
	return x < n
	:left_shift_negative
	n = 0 - n
	return x > n

function max_signed
	argument a
	argument b
	if a > b goto maxs_return_a
	return b
	:maxs_return_a
	return a
	
function file_error
	argument name
	fputs(2, .str_file_error)
	fputs(2, name)
	fputc(2, 10)
	exit(1)
	
:str_file_error
	string Error opening file:
	byte 32
	byte 0

function malloc
	argument size
	local total_size
	local memory
	total_size = size + 8
	memory = syscall(9, 0, total_size, 3, 0x22, -1, 0)
	if memory ] 0xffffffffffff0000 goto malloc_failed
	*8memory = total_size
	return memory + 8

:malloc_failed
	fputs(2, .str_out_of_memory)
	exit(1)
	
:str_out_of_memory
	string Out of memory.
	byte 10
	byte 0

function free
	argument memory
	local psize
	local size
	psize = memory - 8
	size = *8psize
	syscall(11, psize, size)
	return

; returns a pointer to a null-terminated string containing the number given
function itos
	global 32 itos_string
	argument x
	local c
	local p
	p = &itos_string
	p += 30
	:itos_loop
		c = x % 10
		c += '0
		*1p = c
		x /= 10
		if x == 0 goto itos_loop_end
		p -= 1
		goto itos_loop
	:itos_loop_end
	return p

; returns the number in the given base at the start of the string, advancing the string past it.
function strtoi
	argument p_s
	argument base
	local s
	local c
	local n
	n = 0
	s = *8p_s
	:strtoi_loop
		c = *1s
		if c < '0 goto strtoi_loop_end
		if c <= '9 goto strtoi_decimal_digit
		if c < 'A goto strtoi_loop_end
		if c <= 'F goto strtoi_upper_hexdigit
		if c < 'a goto strtoi_loop_end
		if c <= 'f goto strtoi_lower_hexdigit
		goto strtoi_loop_end
		
		:strtoi_decimal_digit
			c -= '0
			goto strtoi_digit
		:strtoi_upper_hexdigit
			c += 10 - 'A
			goto strtoi_digit
		:strtoi_lower_hexdigit
			c += 10 - 'a
			goto strtoi_digit
		:strtoi_digit
			if c >= base goto strtoi_loop_end
			n *= base
			n += c
			s += 1
			goto strtoi_loop
			
	:strtoi_loop_end
	*8p_s = s
	return n
	
; returns the decimal number at the start of the given string
function stoi
	argument s
	return strtoi(&s, 10)

function memchr
	argument mem
	argument c
	local p
	p = mem
	:memchr_loop
		if *1p == c goto memchr_loop_end
		p += 1
		goto memchr_loop
	:memchr_loop_end
	return p

function strchr
	argument str
	argument c
	local p
	p = str
	:strchr_loop
		if *1p == 0 goto return_0
		if *1p == c goto strchr_loop_end
		p += 1
		goto strchr_loop
	:strchr_loop_end
	return p

; copy from *p_src to *p_dest until terminator is reached, setting both to point to their respective terminators
function memccpy_advance
	argument p_dest
	argument p_src
	argument terminator
	local src
	local dest
	local c
	src = *8p_src
	dest = *8p_dest
	:memccpy_advance_loop
		c = *1src
		*1dest = c
		if c == terminator goto memccpy_advance_loop_end
		src += 1
		dest += 1
		goto memccpy_advance_loop
	:memccpy_advance_loop_end
	*8p_src = src
	*8p_dest = dest
	return

; copy from src to dest until terminator is reached, returning pointer to terminator in dest.
function memccpy
	argument dest
	argument src
	argument terminator
	memccpy_advance(&dest, &src, terminator)
	return dest

; just like C
function memcpy
	argument dest
	argument src
	argument n
	local p
	local q
	p = dest
	q = src
	:memcpy_loop
		if n == 0 goto return_0
		*1p = *1q
		p += 1
		q += 1
		n -= 1
		goto memcpy_loop

function strlen
	argument s
	local p
	p = s
	:strlen_loop
		if *1p == 0 goto strlen_loop_end
		p += 1
		goto strlen_loop
	:strlen_loop_end
	return p - s

; like C strcpy, but returns a pointer to the terminating null character in dest
function strcpy
	argument dest
	argument src
	local p
	local q
	local c
	p = dest
	q = src
	:strcpy_loop
		c = *1q
		*1p = c
		if c == 0 goto strcpy_loop_end
		p += 1
		q += 1
		goto strcpy_loop
	:strcpy_loop_end
	return p

function str_equals
	argument a
	argument b
	local c
	local d
	:str_equals_loop
		c = *1a
		d = *1b
		if c != d goto return_0
		if c == 0 goto return_1
		a += 1
		b += 1
		goto str_equals_loop

function str_startswith
	argument s
	argument prefix
	local p
	local q
	local c1
	local c2
	p = s
	q = prefix
	:str_startswith_loop
		c1 = *1p
		c2 = *1q
		if c2 == 0 goto return_1
		if c1 != c2 goto return_0
		p += 1
		q += 1
		goto str_startswith_loop

function fputs
	argument fd
	argument s
	local length
	length = strlen(s)
	syscall(1, fd, s, length)
	return

function puts
	argument s
	fputs(1, s)
	return

function print_separator
	fputs(1, .str_separator)
	return

:str_separator
	byte 10
	string ------------------------------------------------
	byte 10
	byte 0

function fputn
	argument fd
	argument n
	local s
	s = itos(n)
	fputs(fd, s)
	return

function fputn_signed
	argument fd
	argument n
	if n < 0 goto fputn_negative
	
	fputn(fd, n)
	return
	
	:fputn_negative
		fputc(fd, '-)
		n = 0 - n
		fputn(fd, n)
		return
		
:hex_digits
	string 0123456789abcdef

function fputx64
	argument fd
	argument n
	local m
	local x
	m = 60
	:fputx64_loop
		x = n > m
		x &= 0xf
		x += .hex_digits
		fputc(fd, *1x)
		m -= 4
		if m >= 0 goto fputx64_loop
	return
function putx64
	argument n
	fputx64(1, n)
	return
	
function fputx32
	argument fd
	argument n
	local m
	local x
	m = 28
	:fputx32_loop
		x = n > m
		x &= 0xf
		x += .hex_digits
		fputc(fd, *1x)
		m -= 4
		if m >= 0 goto fputx32_loop
	return
function putx32
	argument n
	fputx32(1, n)
	return

function putn
	argument n
	fputn(1, n)
	return

function putn_signed
	argument n
	fputn_signed(1, n)
	return


function fputc
	argument fd
	argument c
	syscall(1, fd, &c, 1)
	return

function putc
	argument c
	fputc(1, c)
	return

; returns 0 at end of file
function fgetc
	argument fd
	local c
	c = 0
	syscall(0, fd, &c, 1)
	return c

; read a line from fd as a null-terminated string
; returns 0 at end of file, 1 otherwise
function fgets
	argument fd
	argument buf
	argument size
	local p
	local end
	local c
	p = buf
	end = buf + size
	
	:fgets_loop
		c = fgetc(fd)
		if c == 0 goto fgets_eof
		if c == 10 goto fgets_eol
		*1p = c
		p += 1
		if p == end goto fgets_eob
		goto fgets_loop
		
	:fgets_eol ; end of line
	*1p = 0
	return 1
	:fgets_eof ; end of file
	*1p = 0
	return 0
	:fgets_eob ; end of buffer
	p -= 1
	*1p = 0
	return 1

; open the given file for reading
function open_r
	argument filename
	local fd
	fd = syscall(2, filename, 0)
	if fd < 0 goto open_r_error
		return fd
	:open_r_error
		file_error(filename)
		return -1

; open the given file for writing with the given mode
function open_w
	argument filename
	argument mode
	local fd
	fd = syscall(2, filename, 0x241, mode)
	if fd < 0 goto open_w_error
		return fd
	:open_w_error
		file_error(filename)
		return -1
	
function close
	argument fd
	syscall(3, fd)
	return

#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

function lseek
	argument fd
	argument offset
	argument whence
	return syscall(8, fd, offset, whence)

function isupper
	argument c
	if c < 'A goto return_0
	if c <= 'Z goto return_1
	goto return_0

function islower
	argument c
	if c < 'a goto return_0
	if c <= 'z goto return_1
	goto return_0

function isdigit
	argument c
	if c < '0 goto return_0
	if c <= '9 goto return_1
	goto return_0

function isoctdigit
	argument c
	if c < '0 goto return_0
	if c <= '7 goto return_1
	goto return_0	

function isalpha
	argument c
	if c < 'A goto return_0
	if c <= 'Z goto return_1
	if c < 'a goto return_0
	if c <= 'z goto return_1
	goto return_0

; characters which can start identifiers in C
function isalpha_or_underscore
	argument c
	if c < 'A goto return_0
	if c <= 'Z goto return_1
	if c == '_ goto return_1
	if c < 'a goto return_0
	if c <= 'z goto return_1
	goto return_0

; characters which can appear in identifiers in C
function isalnum_or_underscore
	argument c
	if c < '0 goto return_0
	if c <= '9 goto return_1
	if c < 'A goto return_0
	if c <= 'Z goto return_1
	if c == '_ goto return_1
	if c < 'a goto return_0
	if c <= 'z goto return_1
	goto return_0

; is the given character one of:
;   .0123456789
; (these are the characters which can appear at the start of a number in C)
function isdigit_or_dot
	argument c
	if c < '. goto return_0
	if c == '. goto return_1
	if c < '0 goto return_0
	if c <= '9 goto return_1
	goto return_0

function exit
	argument status_code
	syscall(0x3c, status_code)

; return index of leftmost bit
; error on 0
function leftmost_1bit
	argument x
	local i
	local b
	if x == 0 goto leftmost1bit_0
	
	i = 63
	:leftmost1bit_loop
		b = 1 < i
		b &= x
		if b != 0 goto leftmost1bit_found
		i -= 1
		goto leftmost1bit_loop
	:leftmost1bit_found
		return i
	:leftmost1bit_0
		fputs(2, .str_leftmost1bit_0)
		exit(1)
	:str_leftmost1bit_0
		string 0 passed to leftmost_1bit.
		byte 0
:return_0
	return 0
:return_1
	return 1
:return_minus1
	return -1
:return_0x10
	return 0x10
:return_0x20
	return 0x20
:return_0x30
	return 0x30
:return_0x40
	return 0x40
:return_0x50
	return 0x50
:return_0x60
	return 0x60
:return_0x70
	return 0x70
:return_0x80
	return 0x80
:return_0x90
	return 0x90
:return_0xa0
	return 0xa0
:return_0xb0
	return 0xb0
:return_0xc0
	return 0xc0
:return_0xd0
	return 0xd0
:return_0xe0
	return 0xe0
:return_0xf0
	return 0xf0

function syscall
	; I've done some testing, and this should be okay even if
	; rbp-56 goes beyond the end of the stack.
	; mov rax, [rbp-16]
	byte 0x48
	byte 0x8b
	byte 0x85
	byte 0xf0
	byte 0xff
	byte 0xff
	byte 0xff
	; mov rdi, rax
	byte 0x48
	byte 0x89
	byte 0xc7
	
	; mov rax, [rbp-24]
	byte 0x48
	byte 0x8b
	byte 0x85
	byte 0xe8
	byte 0xff
	byte 0xff
	byte 0xff
	; mov rsi, rax
	byte 0x48
	byte 0x89
	byte 0xc6
	
	; mov rax, [rbp-32]
	byte 0x48
	byte 0x8b
	byte 0x85
	byte 0xe0
	byte 0xff
	byte 0xff
	byte 0xff
	; mov rdx, rax
	byte 0x48
	byte 0x89
	byte 0xc2
	
	; mov rax, [rbp-40]
	byte 0x48
	byte 0x8b
	byte 0x85
	byte 0xd8
	byte 0xff
	byte 0xff
	byte 0xff
	; mov r10, rax
	byte 0x49
	byte 0x89
	byte 0xc2
	
	; mov rax, [rbp-48]
	byte 0x48
	byte 0x8b
	byte 0x85
	byte 0xd0
	byte 0xff
	byte 0xff
	byte 0xff
	; mov r8, rax
	byte 0x49
	byte 0x89
	byte 0xc0
	
	; mov rax, [rbp-56]
	byte 0x48
	byte 0x8b
	byte 0x85
	byte 0xc8
	byte 0xff
	byte 0xff
	byte 0xff
	; mov r9, rax
	byte 0x49
	byte 0x89
	byte 0xc1
	
	; mov rax, [rbp-8]
	byte 0x48
	byte 0x8b
	byte 0x85
	byte 0xf8
	byte 0xff
	byte 0xff
	byte 0xff
	
	; syscall
	byte 0x0f
	byte 0x05
	
	return
