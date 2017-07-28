	.def	 @feat.00;
	.scl	3;
	.type	0;
	.endef
	.globl	@feat.00
@feat.00 = 1
	.def	 _main;
	.scl	2;
	.type	32;
	.endef
	.text
	.globl	_main
	.align	16, 0x90
_main:                                  # @main
# BB#0:                                 # %entry
	pushl	%eax
	movl	$L_.str0, (%esp)
	calll	_puts
	xorl	%eax, %eax
	popl	%edx
	ret

	.section	.rdata,"r"
	.align	16                      # @.str0
L_.str0:
	.asciz	"Hello, LLVM world!"


