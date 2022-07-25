addi x1, x1, 1
addi x2, x2, 2
addi x3, x3, 3

nop
nop
nop

addi x1, x1, 1
addi x2, x2, 2
addi x1, x1, 1
addi x3, x3, 3

nop
nop
nop

lw	x1, 0(x1)
lw	x2, 0(x1)
lw	x3, 0(x1)

nop
nop
nop

addi x1, x1, 1
addi x2, x2, 2
lw	x1, 0(x1)

nop
nop
nop

addi x1, x1, 1
lw	x1, 0(x1)
addi x2, x2, 2

nop
nop
nop

addi x1, x1, 1
addi x1, x2, 1
addi x2, x1, 1

nop
nop
nop

addi x1, x1, 1
add x3, x1, x2
add x3, x2, x1

nop
nop
nop

addi x1, x1, 1
add x3, x1, x4
add x3, x4, x1
