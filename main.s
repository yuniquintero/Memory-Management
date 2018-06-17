	.data
head1:	.space	4
head2:	.space	4
elem1:	.space	4
elem2:	.space	4
elem3:	.space	4

	.text
main:
	li	$a0, 0x200
	jal	init
	
	jal	create
	sw	$v0, head1
	
	lw	$a0, head1
	la	$a1, elem1
	jal	insert
	
	lw	$a0, head1
	la	$a1, elem2
	jal	insert
	
	lw	$a0, head1
	la	$a1, elem1
	jal	insert
	
	lw	$a0, head1
	la	$a1, elem2
	jal	insert

	li	$a0, 1
	jal	malloc
	sw	$v0, elem1
	
	li	$a0, 3
	jal	malloc
	sw	$v0, elem2
	#####
	lw	$a0, head1
	la	$a1, elem2
	jal	insert
	
	lw	$a0, head1
	la	$a1, elem1
	jal	insert
	
	lw	$a0, head1
	la	$a1, elem2
	jal	insert
	
	lw	$a0, head1
	la	$a1, elem1
	jal	insert
	lw	$a0, head1

	li	$a1, 2
	jal	delete
	
	li	$v0, 10
	syscall

.include "Manejador.s"
.include "Lista.s"
