; returns a string of null character-separated preprocessing tokens
; this corresponds to translation phases 1-3 in the C89 standard
function split_into_preprocessing_tokens
	argument filename
	local fd
	local file_contents
	local pptokens
	local p
	local c
	local in
	local out
	local n
	
	fd = open_r(filename)
	file_contents = malloc(2000000)
	pptokens = malloc(2000000)
	p = file_contents
	:pptokens_read_loop
		n = syscall(0, fd, p, 4096)
		if n == 0 goto pptokens_read_loop_end
		p += n
	:pptokens_read_loop_end
	
	; okay we read the file. first, delete every backslash-newline sequence (phase 2)
	local newlines ; we add more newlines to keep line numbers right
	newlines = 1
	in = file_contents
	out = file_contents
	:backslashnewline_loop
		c = *1in
		if c == 0 goto backslashnewline_loop_end
		if c == 10 goto proper_newline_loop
		if c != '\ goto not_backslashnewline
			p = in + 1
			c = *1p
			if c != 10 goto not_backslashnewline
				in += 2 ; skip backlash and newline
				newlines += 1 ; add one additional newline the next time around to compensate
				goto backslashnewline_loop
		:not_backslashnewline
			*1out = *1in
			out += 1
			in += 1
			goto backslashnewline_loop
		:proper_newline_loop
			if newlines == 0 goto proper_newline_loop_end
			; output a newline
			*1out = 10
			out += 1
			newlines -= 1
			goto proper_newline_loop
		:proper_newline_loop_end
			newlines = 1
			in += 1
			goto backslashnewline_loop
	:backslashnewline_loop_end
	*1out = 0
	
	in = file_contents
	
	fputs(1, file_contents)
	
	free(file_contents)
	close(fd)
	return
	
	:unterminated_comment
		fputs(2, .str_unterminated_comment)
		fputs(2, filename)
		fputc(2, 10)
		exit(1)
	:str_unterminated_comment
		string Unterminated comment in file
		byte 32
		byte 0
