// RDI, RSI, RDX, RCX, R8, R9

.include "debug.s"

.equ FALSE_BITS, 0b0000
.equ NULL_BITS,  0b0010
.equ TRUE_BITS,  0b0100
.equ FUNC_TAG,   0b1000
.equ STRING_TAG, 0b1100
.equ IDENT_TAG,  0b1110
.equ ALLOC_BIT,  0b1000
.equ TAG_MASK,   0b1111
.equ ALLOC_MASK, 0b1001

// abuse the fact that `malloc` will allocate things that are 16-aligned.
// 0...00000 = false
// 0...XXXX1 = 63-bit
// 0...00010 = null
// 0...00100 = true
// X...X1000 = function
// X...X1100 = string
// X...X1110 = ident

.globl kn_value_new_integer
kn_value_new_integer:
	mov %rdi, %rax
	shl %rax
	or $1, %al
	ret

// Create a new boolean.
// 
// if rdi is zero, false is returned. Otherwise, true is returned.
.globl kn_value_new_boolean
kn_value_new_boolean:
	cmp $0, %rdi
	je kn_value_new_false // If the value given is zero, return 'false'.
	// otherwise, fall through and reutnr 'true'.

// Create a true value
.globl kn_value_new_true
kn_value_new_true:
	mov $TRUE_BITS, %eax
	ret

// Create a false value.
.globl kn_value_new_false
kn_value_new_false:
	xor %eax, %eax
	assert_eq $FALSE_BITS, %rax
	ret

// Create a new null value.
.globl kn_value_new_null
kn_value_new_null:
	mov $NULL_BITS, %eax
	ret

// Creates a new string value from the given string.
//
// The string in `rdi` must have been created via functions in the kn_string file.
.globl kn_value_new_string
kn_value_new_string:
/*.ifdef KN_DEBUG // ensure that the lower bits are not set.
	mov %edi, %ecx
	and $TAG_MASK, %ecx
	assert_z %ecx
.endif // KN_DEBUG*/
	lea STRING_TAG(%rdi), %rax
	ret

// Creates a new identifier.
.globl kn_value_new_identifier
kn_value_new_identifier:
/*.ifdef KN_DEBUG // ensure that the lower bits are not set.
	mov %edi, %ecx
	and $TAG_MASK, %ecx
	assert_z %ecx
.endif // KN_DEBUG*/
	lea IDENT_TAG(%rdi), %rax
	ret

// NOTE: This function should only ever be called from `kn_parse`.
//
// A prereq is that `r12` contains the stream.
.globl kn_value_new_function
kn_value_new_function:
/*.ifdef KN_DEBUG // ensure that the lower bits are not set.
	mov %edi, %ecx
	and $TAG_MASK, %ecx
	assert_z %ecx
.endif // KN_DEBUG*/
	push %rbx
	push %r13
	push %r14

	mov %rdi, %rbx       // Save the function pointer
	movzb -1(%rdi), %r13 // load the arity

	mov %r13, %rdi
	inc %rdi             // add one for the function pointer itself
	imul $8, %rdi        // find the amount of bytes we need to allocate
	call xmalloc         // allocate the memory for the struct

	mov %rbx, (%rax)     // load the instruction pointer over.
	mov %rax, %rbx       // save our malloc pointer.
	mov %rax, %r14       // and load the "next position" pointer
0:
	cmp $0, %r13         // if we have no arguments left...
	jz 1f                // ...then we have nothing left to parse, and jump to the end.
	dec %r13             // otherwise, subtract one from argc,
	add $8, %r14         // and add one to the next pointer register.
	mov %r12, %rdi
	call kn_parse        // fetch the next stream
	mov %rax, (%r14)     // store the ast we just read
	mov %rdi, %r12       // the handle_stream function returns the stream in rdi; a bit of a hack...
	jmp 0b               // and
1:
	lea FUNC_TAG(%rbx), %rax // load the return value back
	pop %r14             // and restore the registers
	pop %r13
	pop %rbx
	ret

.globl kn_value_free
kn_value_free:
	mov %edi, %eax
	and $ALLOC_MASK, %eax
	cmp $ALLOC_BIT, %eax  // check to see if it is allocated.
	je 0f                 // if it is allocated, coninue on.
	ret                   // No need to free literal values.
0: // string or ident or function
	mov %edi, %eax
	and $TAG_MASK, %eax   // fetch the full tag again.
	and $~TAG_MASK, %rdi  // remove the tag
	cmp $STRING_TAG, %eax
	je kn_string_free     // if we are a string, return to it.
	cmp $IDENT_TAG, %eax
	je _free              // if we are an ident, use `_free`, as those are "char *"s
// otherwise, we are a function here
	push %rbx
	push %r12
	sub $8, %rsp
	mov %rdi, %rbx        // Store the base address.
	movzb -1(%rdi), %r12  // get the arity...
	imul $8, %r12         // ...then get the amount of bytes from rdi...
	add %rdi, %r12        // ...and then calculate the last index.
0:
	cmp %rbx, %r12
	je 1f                 // If our ending argument is equal to the starting one, we are done.
	mov %r12, %rdi
	call kn_value_free    // Free the current argument
	sub $8, %r12          // go one argument back
	jmp 0b
1:
	mov %rbx, %rdi        // now free the ending value
	add $8, %rsp          // Restore previous values
	pop %r12
	pop %rbx
	jmp _free             // Now free this entire struct

.globl kn_value_run_and_free
kn_value_run_and_free:
	push %rbx
	mov %rdi, %rbx
	call kn_value_run
	mov %rbx, %rdi
	pop %rbx
	jmp kn_value_free

.globl kn_value_run
kn_value_run:
	mov %edi, %eax
	and $ALLOC_MASK, %eax
	cmp $ALLOC_BIT, %eax    // check to see if we are an allocated type
	je 0f                   // if so, continue onwards
	mov %rdi, %rax          // otherwise, just copy the immediate value.
	ret
0: // string, ident, function
	mov %edi, %eax
	and $~TAG_MASK, %rdi
	and $TAG_MASK, %eax
	cmp $STRING_TAG, %eax
	jne 0f                   // if we are not a string, continue onwards
	sub $8, %rsp
	call kn_string_clone     // duplicate the string
	add $8, %rsp
	mov %rax, %rdi
	jmp kn_value_new_string   // create a new string with the return value.
0: // ident, function
	cmp $IDENT_TAG, %eax      // check to see if we are an ident
	cmove (%rdi), %rdi        // if we are, fetch the ident, and run it
	je kn_env_get
	assert_eq $FUNC_TAG, %rax // sanity check
	mov (%rdi), %rax
	lea 8(%rdi), %rdi
	push %rax
	ret

.globl kn_value_to_boolean
kn_value_to_boolean:
	mov %edi, %ecx
	and $ALLOC_MASK, %ecx // Check to see if we are an allocated value
	cmp $ALLOC_BIT, %ecx
	je 0f                 // If we are, go to that section.
	cmp $2, %ecx
	jle kn_value_new_false
	jmp kn_value_new_true
0: // string, identifier, function
	mov %edi, %ecx
	and $TAG_MASK, %ecx   // fetch the tag
	and $~TAG_MASK, %rdi  // remove the tag from the pointer
	cmp $STRING_TAG, %ecx
	jne 0f                   // If we are not a string, continue onwards.
	mov (%rdi), %rdi         // deref string struct
	movzbl (%rdi), %ecx      // deref string pointer
	jecxz kn_value_new_false // if the first byte is '\0', then the string is empty and we are false
	jmp kn_value_new_true    // otherwise, the string is truthy
0: // identifier, function
	// if we are an ident or function, execute first, then calculate the truthiness,
	// and then free the value we get from executing.
	cmp $IDENT_TAG, %ecx
	jne 0f                   // if we are not an ident, go to the function
	push %rbx
	call kn_env_get          // fetch the idents value
	mov %rax, %rbx           // keep the return value so we can free it
	mov %rax, %rdi
	call kn_value_to_boolean // convert the evaluated value to a boolean.
	mov %rbx, %rdi           // prepare to free the value we evaluted
	mov %rax, %rbx           // save the returned value
	call kn_value_free       // free the result of kn_value_to_boolean
	mov %rbx, %rax           // restore the old called value
	pop %rbx
	ret
0: // function
	je kn_env_get // if we are an ident, get the variable
	// otherwise, execute the function.
	push 8(%rdi)
	add $16, %rdi
	jmp die

/*
.globl value_to_integer
value_to_integer:
	// Short circuit: If the value is `0` (ie false), `1` (ie the number zero), or `2` (ie
	// `null`), then we return false. otherwise, return true.
	mov %dil, %al
	and $1, %al
	cmp $1, %al
	je 0f
	mov %dil, %cl
	cmp $ALLOC_BIT, %cl // if the allocated bit is set, jmp to not a literal.
	jae 1f
	and $1, %cl
	jne 0f // optimize for the path of being an integer
	shr %rdi
	mov %rdi, %rax
	ret
0: // a literal, but not an integer
	shr %dil
	or $1, %dil
	movzb %dil, %ecx
	ret
1: // either a string or a value that needs to be run.
	and $TAG_MASK, %cl
	cmp $STRING_TAG, %cl
	jne 2f // if we are not a string, we must evaluate it.
	and $~TAG_MASK, %rdi // remove the tag so we can deref it.
	mov (%rdi), %rdi // deref the string struct ptr
	jmp _strtoll
2: // must run the value to get the result.
	sub $8, %rsp
	call value_run
	mov %rax, %rdi
	add $8, %rsp
	jmp value_to_integer // do it over again.

.globl value_to_string
value_to_string:
	mov %dil, %al
	and $1, %al
	cmp $1, %al
	jne 0f
	call die // todo: int to string
0: // check for allocataed
	mov %dil, %cl
	cmp $ALLOC_BIT, %cl // if the allocated bit is set, jmp to not a literal.
	jae 1f
0: // check for false
	cmp $FALSE_BITS, %dil
	jne 0f
	mov kn_string_false(%rip), %rax
	ret
0: // check for true
	cmp $TRUE_BITS, %dil
	jne 0f
	mov kn_string_true(%rip), %rax
	ret
0: // we must be null here.
	mov kn_string_null(%rip), %rax
	ret
1: // either a string or a value that needs to be run.
	and $TAG_MASK, %cl
	cmp $STRING_TAG, %cl
	jne 2f // if weare not a string, we must evaluate it.
	sub $STRING_TAG, %rdi // remove tag so we can pass it to clone correctly.
	jmp kn_string_clone
2: // must run the value to get the result.
	sub $8, %rsp
	call value_run
	mov %rax, %rdi
	add $8, %rsp
	jmp value_to_string // do it over again.


.globl value_run
value_run:
	mov %dil, %al
	and $1, %al
	cmp $1, %al
	je 0f
	mov %dil, %cl
	cmp $ALLOC_BIT, %cl // if the allocated bit is set, jmp to not a literal.
	jae 1f
0:
	mov %rdi, %rax
	ret // do not need to run literal values.
1: // string or ident or function
	and $~TAG_MASK, %rdi // remove the tag
	and $TAG_MASK, %cl
	cmp $STRING_TAG, %cl
	jne 2f // if it is not a string, go onwards
	sub $8, %rsp
	call kn_string_clone // duplicate the string
	add $8, %rsp
	jmp kn_value_new_string // then return the new string
2: // ident or function
	cmp $IDENT_TAG, %cl
	je kn_env_get // if we are an ident, get the variable
	// otherwise, execute the function.
	push 8(%rdi)
	add $16, %rdi
	ret

.globl value_clone
value_clone:
	mov %dil, %al
	and $1, %al
	cmp $1, %al
	je 0f
	mov %dil, %cl
	cmp $ALLOC_BIT, %cl // if the allocated bit is set, jmp to not a literal.
	jae 1f
0:
	mov %rdi, %rax
	ret // do not need to clone literal values.
1: // string or ident or function
	sub $8, %rsp
	and $~TAG_MASK, %rdi // remove the tag
	and $TAG_MASK, %cl
	cmp $STRING_TAG, %cl
	jne 2f // if it is not a string, go onwards
	call kn_string_clone // duplicate the string
	add $8, %rsp
	jmp kn_value_new_string // then return the new string
2: // ident or function
	cmp $IDENT_TAG, %cl
	jne 3f
	call _strdup
	add $8, %rsp
	jmp kn_value_new_identifier
3:
	call die
*/
.globl kn_value_dump
kn_value_dump:
	mov %rdi, %rsi
	and $1, %sil
	jz 0f
	shr %rsi
	lea num_fmt(%rip), %rdi
	jmp _printf
0: // true, false, null, string, ident, function
	mov %rdi, %rsi
	cmp $TRUE_BITS, %rsi
	jne 1f
	lea true_fmt(%rip), %rdi
	jmp 2f
1:
	cmp $FALSE_BITS, %rsi
	jne 1f
	lea false_fmt(%rip), %rdi
	jmp 2f
1:
	cmp $NULL_BITS, %rsi
	jne 1f
	lea null_fmt(%rip), %rdi
2:
	jmp _printf
1:
0: // string, ident, function
	mov %sil, %al
	and $TAG_MASK, %al
	cmp $IDENT_TAG, %al
	jne 0f
	and $~TAG_MASK, %rsi
	lea ident_fmt(%rip), %rdi
	jmp _printf
0: // string, function
	cmp $STRING_TAG, %al
	jne 0f
	and $~TAG_MASK, %rsi
	lea string_fmt(%rip), %rdi
	mov (%rsi), %rsi
	jmp _printf
0: // function
	cmp $FUNC_TAG, %al
	jne 0f
	push %rbx

	// first, print the start
	and $~TAG_MASK, %rsi
	mov %rsi, %rbx
	lea kn_func_start(%rip), %rdi
	call _printf

	push %r12
	push %r13

	mov (%rbx), %rsi
	movzb -1(%rsi), %r12
	lea 8(%rbx), %r13
1:
	cmp $0, %r12
	je 2f
	dec %r12
	mov (%r13), %rdi
	call kn_value_dump
	add $8, %r13
	jmp 1b
2:
	// then print the end
	pop %r13
	pop %r12
	mov %rbx, %rsi
	pop %rbx
	lea kn_func_stop(%rip), %rdi
	jmp _printf
0: // unknown
	lea invalid_fmt(%rip), %rdi
	call abort

.data:
invalid_fmt: .asciz "unknown value type: '%d'\n"
kn_func_start: .asciz "Func(%p):\n"
kn_func_stop: .asciz "Func(%p)/\n"
num_fmt: .asciz "Number(%ld)\n"
string_fmt: .asciz "String(%s)\n"
ident_fmt: .asciz "Ident(%s)\n"
true_fmt: .asciz "True\n"
false_fmt: .asciz "False\n"
null_fmt: .asciz "Null\n"
