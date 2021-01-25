.ifndef KN_DEBUG
	.equ KN_DEBUG, 1
.endif // .ifndef KN_DEBUG

.macro todo msg:req
	lea kn_debug_todo_\@(%rip), %rdi
 	// ensure that the stack is properly aligned
	mov %rsp, %rcx
	mov %esp, %eax
	sub $8, %rcx
	and $8, %eax
	cmp $0, %eax
	cmovnz %rcx, %rsp
	jmp abort
.pushsection .data, ""
kn_debug_todo_\@:
	.asciz "todo: \msg\n"
.popsection
.endm

.ifdef KN_DEBUG
.macro assert_eq lhs:req rhs:req
	cmp \lhs, \rhs
	je .assert_eq_\@
	// mov \lhs, %rsi
	// mov \rhs, %rdi
	lea assertion_failed(%rip), %rdi
	jmp kn_debug_write_abort
.assert_eq_\@:
	nop
.endm // .macro assert_eq

// Note that this is not a proper function, it takes arguments 
// at `rsi` and `4dx`.
kn_debug_write_abort:
 	// ensure that the stack is properly aligned
	mov %rsp, %rcx
	mov %esp, %eax
	sub $8, %rcx
	and $8, %eax
	cmp $0, %eax
	cmovnz %rcx, %rsp
	jmp abort

.pushsection .data, ""
assertion_failed:
	.asciz "assertion failed" // : %1$ld (0x%1$lx) != %2$ld (0x%2$lx)\n
.popsection
.else
.macro assert_eq cond:req val=$0
.endm // .macro assert_eq
.endif // .ifdef KN_DEBUG

.macro assert_z reg:req
	assert_eq $0, \reg
.endm // assert_z
