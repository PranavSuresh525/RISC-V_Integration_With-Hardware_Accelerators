	.file	"risc_code.c"
	.option nopic
	.attribute arch, "rv32i2p1"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	_start
	.type	_start, @function
_start:
 #APP
# 126 "risc_code.c" 1
	li sp, 262128
# 0 "" 2
 #NO_APP
	li	s1,0
	li	t2,-4096
	addi	t2,t2,1596
	li	a6,32768
	li	t4,255
	li	t1,65536
	li	t5,30
	li	s0,25
	li	s2,625
	j	.L2
.L5:
	addi	s4,s4,-127
	srli	a1,a1,7
	andi	a1,a1,127
	j	.L6
.L10:
	sub	a3,s4,a3
	bgt	a3,t5,.L13
	srl	a2,a2,a3
	mv	a3,s4
.L12:
	beq	s3,a5,.L31
	bgeu	a2,a1,.L32
.L16:
	sub	a4,a1,a2
	mv	s3,a5
	j	.L17
.L45:
	li	a1,0
.L31:
	add	a4,a1,a2
.L15:
	beq	a4,zero,.L9
.L17:
	bltu	a4,t1,.L18
	li	a5,0
.L19:
	srli	a4,a4,1
	addi	a5,a5,1
	bgeu	a4,t1,.L19
.L20:
	add	a5,a3,a5
	srli	a4,a4,8
	andi	a4,a4,127
	blt	a5,zero,.L43
.L29:
	ble	a5,t4,.L23
	mv	a5,t4
.L23:
	slli	a5,a5,7
	slli	s3,s3,15
	or	s3,s3,a4
	or	a4,a5,s3
	j	.L9
.L36:
	mv	a3,s4
	li	a2,0
	j	.L31
.L43:
	slli	a4,s3,15
	j	.L9
.L33:
	mv	a4,a5
.L9:
	addi	a7,a7,4
	addi	a0,a0,100
	beq	a0,t3,.L44
.L24:
	lw	a1,0(a7)
	lw	s3,0(a0)
	srli	s4,a1,7
	andi	s4,s4,255
	andi	a2,a1,127
	or	a5,s4,a2
	beq	a5,zero,.L3
	srli	s5,s3,7
	andi	s5,s5,255
	andi	a3,s3,127
	or	a5,s5,a3
	beq	a5,zero,.L3
	xor	a1,a1,s3
	srli	a1,a1,15
	andi	s3,a1,1
	ori	a2,a2,128
	ori	a3,a3,128
	li	a1,0
.L4:
	andi	a5,a3,1
	neg	a5,a5
	and	a5,a5,a2
	add	a1,a1,a5
	slli	a2,a2,1
	srli	a3,a3,1
	bne	a3,zero,.L4
	add	s4,s4,s5
	slli	a5,a1,16
	bge	a5,zero,.L5
	srli	a1,a1,8
	andi	a1,a1,127
	addi	s4,s4,-126
.L6:
	slli	a5,s3,15
	blt	s4,zero,.L3
	ble	s4,t4,.L8
	mv	s4,t4
.L8:
	slli	s4,s4,7
	slli	a5,s3,15
	or	a5,a5,a1
	or	a5,s4,a5
.L3:
	srli	a3,a4,7
	andi	a3,a3,255
	andi	a2,a4,127
	or	a1,a3,a2
	beq	a1,zero,.L33
	srli	s4,a5,7
	andi	s4,s4,255
	andi	a1,a5,127
	or	s3,s4,a1
	beq	s3,zero,.L9
	srli	s3,a4,15
	srli	a5,a5,15
	slli	a2,a2,8
	or	a2,a2,a6
	slli	a1,a1,8
	or	a1,a1,a6
	sub	a4,a3,s4
	blt	a4,zero,.L10
	srl	a1,a1,a4
	ble	a4,t5,.L12
	li	a1,0
	beq	s3,a5,.L45
.L32:
	sub	a4,a2,a1
	j	.L15
.L44:
	add	a5,t3,t0
	sw	a4,0(a5)
	addi	t6,t6,1
	addi	t3,t3,4
	beq	t6,s0,.L25
.L27:
	add	a0,t3,t2
	mv	a7,t0
	li	a4,0
	j	.L24
.L25:
	addi	s1,s1,25
	beq	s1,s2,.L26
.L2:
	slli	t0,s1,2
	li	t3,4096
	addi	t3,t3,904
	li	t6,0
	j	.L27
.L26:
	li	a4,8192
	li	a5,-559038464
	addi	a5,a5,-273
	sw	a5,1808(a4)
	li	a5,0
 #APP
# 155 "risc_code.c" 1
	.insn r 0x0b, 0, 0, x0, a5, x0
# 0 "" 2
 #NO_APP
	li	a5,4096
	addi	a5,a5,-1596
 #APP
# 156 "risc_code.c" 1
	.insn r 0x0b, 1, 0, x0, a5, x0
# 0 "" 2
 #NO_APP
	addi	a5,a4,-692
 #APP
# 157 "risc_code.c" 1
	.insn r 0x0b, 3, 0, x0, a5, x0
# 0 "" 2
 #NO_APP
	li	a5,-889274368
	addi	a5,a5,-1106
	sw	a5,1812(a4)
.L28:
 #APP
# 162 "risc_code.c" 1
	nop
# 0 "" 2
 #NO_APP
	j	.L28
.L46:
	mv	a5,a3
	srli	a4,a4,8
	andi	a4,a4,127
	j	.L29
.L18:
	li	a5,0
	bgeu	a4,a6,.L46
.L21:
	slli	a4,a4,1
	addi	a5,a5,-1
	bltu	a4,a6,.L21
	j	.L20
.L13:
	beq	s3,a5,.L36
	mv	a3,s4
	li	a2,0
	j	.L16
	.size	_start, .-_start
	.ident	"GCC: (14.2.0+19) 14.2.0"
	.section	.note.GNU-stack,"",@progbits
