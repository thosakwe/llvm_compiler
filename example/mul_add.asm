	.def	 @feat.00;
	.scl	3;
	.type	0;
	.endef
	.globl	@feat.00
@feat.00 = 1
	.def	 _mul_add;
	.scl	2;
	.type	32;
	.endef
	.text
	.globl	_mul_add
	.align	16, 0x90
_mul_add:                               # @mul_add
# BB#0:                                 # %entry
	movl	4(%esp), %eax
	imull	8(%esp), %eax
	addl	12(%esp), %eax
	ret


