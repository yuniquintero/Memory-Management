# Lista.s
# Autores:
#   Yuni Quintero
#   German Robayo

# create(OUT: address: entero)
# parametros: void
# retorno: $v0 direccion donde se encuentra la cabeza de la lista
# valor negativo que representa el codigo del error ocurrido
# plan de registros:
# $fp: apuntador al marco de la subrutina
# $sp: apuntador a la primera posicion libre de la pila
# $ra: direccion de retorno al llamador
# $t0: temporal, tamano asignado por init() de TAD Manejador
# $a0: espacio solicitado para la cabeza de la Lista
# $v0: direccion donde se encuentra la cabeza de la lista

.text
.globl create

create:
	sw	$fp, ($sp) 		# prolog
	sw	$ra, -4($sp)
	subi	$sp, $sp, 8
	move	$fp, $sp

	lw	$t0, sizeInit 		# verifica si el manejador fue inicializado
	bnez	$t0, create_ok
	li	$v0, -7
	b	create_finish

create_ok: 					# solicita espacio para la cabeza de la lista
	li 	$a0, 12
	jal	malloc
	sw	$0, ($v0) 		# CabezaLista.first apunta a 0
	sw	$0, 4($v0)		# CabezaLista.last apunta a 0
	sw	$0, 8($v0)		# CabezaLista.size apunta a 0

create_finish: 			# epilog
	addi	$sp, $sp, 8
	lw	$fp, ($sp)
	lw	$ra, -4($sp)
	jr	$ra

# insert(IN lista_ptr: entero; IN elem_ptr: entero; OUT code: entero)
# parametros: $a0 direccion de la cabeza de la lista, $a1 direccion del
# elemento a ser insertado
# retorno: code 0 si hubo exito, valor negativo si ocurre error
# plan de registros:
# $fp: apuntador al marco de la subrutina
# $sp: apuntador a la primera posicion libre de la pila
# $ra: direccion de retorno al llamador
# $t0: temporal, tamano asignado por init() de TAD Manejador, direccion de CabezaLista.last
# $a0 direccion de la cabeza de la lista
# $a1 direccion del elemento a ser insertado

.text
.globl insert

insert:
	sw	$fp, ($sp) 		# prolog
	sw	$ra, -4($sp)
	subi	$sp, $sp, 8
	move	$fp, $sp

	lw	$t0, sizeInit
	bnez	$t0, insert_ok
insert_err:
	li	$v0, -7
	b	insert_finish

insert_ok:
	sw	$a0, ($sp)		# guardamos en la pila los valores de $a0 y $t0
	sw	$t0, -4($sp)
	subi	$sp, $sp, 8
	li	$a0, 8			# espacio a alocado para el nodo 8 bytes
	jal 	malloc

	addi	$sp, $sp, 8 	# rescatamos los valores de $a0 y $v0
	lw	$a0, ($sp)
	lw	$t0, -4($sp)

	blt	$v0, $0, insert_finish 	# si el malloc dio errores

	lw	$t0, 8($a0)
	addi	$t0, $t0, 1			#incrementamos la cantidad de nodos en la lista
	sw	$t0, 8($a0)
	beq	$t0, 1, insert_first 	# si solo hay un nodo, es que insertamos el primero de la lista
	lw	$t0, 4($a0)			#$t0 = direccion del last actual
	sw	$v0, ($t0)			# last actual.next apunta a la dir que se inserto
	sw	$v0, 4($a0)			# guardamos nuevo CabezaLista/last
	b	insert_node

insert_first:
	sw	$v0, ($a0) 			# first apunta al insertado
	sw	$v0, 4($a0)			# last apunta al insertado

insert_node:
	sw	$0, ($v0) 			# ultimo en insertar apunta a null
	sw  	$a1, 4($v0) 	# apuntador a la dir del elemento

insert_finish:			#epilog
	addi	$sp, $sp, 8
	lw	$fp, ($sp)
	lw	$ra, -4($sp)
	move	$v0, $0
	jr	$ra

# delete(IN lista_ptr: entero; IN pos: entero; OUT address: entero)
# parametros: $a0 direccion de la cabeza de la lista, $a1 posicion del elemento
# que se desea liberar
# retorno: $vo direccion de memoria del elemento correspondiente
# valor negativo si ocurre error, el correspondiente a free
# plan de registros: 
# $fp: apuntador al marco de la subrutina
# $sp: apuntador a la primera posicion libre de la pila
# $ra: direccion de retorno al llamador
# $t0: temporal, iterador
# $t1: apuntador a cabezaLista.size, decrementa
# $t2: apuntador al nodo actual
# $t3: registro para guardar el predecesor del nodo actual
# $t4: apuntador a nodo.next
# $t5: apuntador a cabezaLista.size

.text
.globl delete

delete:
	sw	$fp, ($sp)
	sw	$ra, -4($sp)
	sub	$sp, $sp, 8 		# prolog
	move	$fp, $sp
	
	lw  	$t0, sizeInit
	bnez 	$t0, delete_ok
delete_err:
	li 	$v0, -8
	b 	delete_end

delete_ok:	
	li	$t0, 1
	lw	$t1, 8($a0)  		# $t1 = cabezaLista.size
	lw	$t5, 8($a0)		#$t5 = cabezaLista.size
	lw	$t2, ($a0) 		#$t2 = nodo actual
	lw	$t3, ($a0)  		# $t3 = nodo actual, posteriormente su predecesor

	bgt	$a1, $t1, delete_error # pos no esta en el rango

delete_loop: 				# iterar para buscar el nodo en la posicion dada
	beq	$t0, $a1, delete_node 	# si coincide el iterador con la pos
	addi	$t0, $t0, 1		# incrementa iterador si pos no coincide
	move	$t3, $t2		# prev = nodo actual
	lw	$t2, ($t2)		# nodo=nodo.next
	b	delete_loop

delete_node:
	beq	$a1, 1, delete_first  	  # si elimino el primero de la lista
	beq	$a1, $t5, delete_last	 # si elimino el ultimo de la lista
	lw	$t4, ($t2)		# $t4 = el nodo sucesor del que sera eliminado, $t4 = nodo.next
	sw	$t4, ($t3)		# nodo.prev.next=nodo.next
	b	delete_call

delete_first:
	lw	$t0, ($t2)	# $t0 obtenemos sucesor del nodo
	sw	$t0, ($a0)	# cabezaLista.first apunta al sucesor del nodo eliminado
	b	delete_call
		
delete_last:
	lw	$t0, ($t3) 		# $t0 obtenemos predecesor del nodo a ser eliminado, 
						# en la linea 136 el predecesor se guardo en $t3
	sw	$t0, 4($a0) 	# cabezaLista.last apunta al predecesor del eliminado

delete_call:
	subi	$t1, $t1, 1	# prolog
	sw	$t1, 8($a0)
	
	sw	$a0, ($sp)	# guardamos parametros y registros temprales en la pila
	sw	$a1, -4($sp)
	sw	$t0, -8($sp)
	sw	$t1, -12($sp)
	sw	$t2, -16($sp)
	sw	$t3, -20($sp)
	sw	$t4, -24($sp)
	sw	$t5, -28($sp)
	subi	$sp, $sp, 32
	
	move	$a0, $t2
	jal	free
	
	addi	$sp, $sp, 32 	# recuperar valores empilados
	lw	$a0, ($sp)
	lw	$a1, -4($sp)
	lw	$t0, -8($sp)
	lw	$t1, -12($sp)
	lw	$t2, -16($sp)
	lw	$t3, -20($sp)
	lw	$t4, -24($sp)
	lw	$t5, -28($sp)
	
	lw	$v0, 4($t2) 	# retorna la dir del elemento del nodo que fue eliminado
	b	delete_end

delete_error:
	li	$v0, -1
	
delete_end: 		# epilog
	addi	$sp, $sp, 8
	lw	$fp, ($sp)
	lw	$ra, 4($sp)
	jr	$ra

# print(IN lista_ptr: entero; IN fun_print: entero; OUT void)
# parametros: $a0 direccion de la cabeza de la lista, $a1 fun_print
# retorno: void
# plan de registros: 
# $fp: apuntador al marco de la subrutina
# $sp: apuntador a la primera posicion libre de la pila
# $ra: direccion de retorno al llamador
# $t0: direccion del nodo actual
# $a0: direccion de la cabeza de la lista
# $t0:temporal, direccion del nodo actual 
# $a1: registro de funprint

.text
.globl print

print:
	sw	$fp, ($sp) 	# prolog
	sw	$ra, 4($sp)
	subi	$sp, $sp, 8
	move	$fp, $sp
	
	lw	$t0, ($a0)	#$ t0 = primer nodo, CabezaLista.first
	
print_loop: 			# iterar sobre la lista
	beqz	$t0, print_end
	lw	$a0, 4($t0) 	# $a0 = dir del elemento que apunta el nodo
	jarl	$a1 		# llamada a la funprint
	lw	$t0, ($t0) 		# nodo=nodo.next
	b	print_loop

print_end:   #epilog
	addi	$sp, $sp, 8
	lw	$fp, ($sp)
	lw	$ra, 4($sp)
	move	$v0, $0
	jr	$ra
