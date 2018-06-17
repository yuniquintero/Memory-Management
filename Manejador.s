# Manejador.s
# Autores:
#   Yuni Quintero
#   German Robayo

# init(IN size:entero; OUT code:entero)
# Descripcion:inicializa el manejador de memoria.
# Argumentos:
#	$a0: Numero de bytes a ser administrados.
# Retorno:
#	$v0
# Uso de registros:
#	$t0: Registro para almacenar las direcciones de memoria del manejador
#	para luego escribir informacion reservada al manejador. Tambien guarda
#	un valor para inicializar la estructura que admiistra el TAD Manejador.
	.data
sizeInit:
	.word 0
sizeAvail:
	.word 0
dirManej:
	.word 0
cabezaManej:
	.word 0
errMessage1:
	.asciiz "init: argumento invalido"
errMessage2:
	.asciiz "init: error con syscall"
errMessage3:
	.asciiz "malloc: argumento invalido. fuera de rango"
errMessage4:
	.asciiz "reallococ/malloc: no hay memoria disponible"
errMessage5:
	.asciiz "reallococ/free: argumento invalido. no previamente retornado por malloc/reallococ"
errMessage6:
	.asciiz "reallococ/malloc: no hay memoria continua disponible"
	.globl sizeInit, sizeAvail, dirManej, cabezaManej
	.text
	.globl	init
init:
	# Convencion de programador
	sw	$fp, ($sp)
	subi	$sp, $sp, 4
	move	$fp, $sp
	
	bgt	$a0, $0, init_ok
	li	$v0, -1

init_ok:
	li	$v0, 9			# Pedimos espacio para el usuario

	syscall
	sw	$a0, sizeInit		# Guardamos el tamano que nos pidio el usuario
	sw	$a0, sizeAvail		# Guardamos el espacio disponible
	sw	$v0, dirManej		# Guardamos la direccion donde comienza la memoria del usuario.
	
	li	$a0, 12			# Pido memoria para la cabeza del manejador
	li	$v0, 9
	syscall				# $v0 tiene la direccion de memoria de la cabeza del TADM.
	blt	$v0, $0, init_end
	beqz	$v0, init_err
	sw	$v0, cabezaManej
	lw	$t0, dirManej
	sw	$t0, ($v0)		# $v0 tiene la direccion de la cabeza, se guarda en cabezaManej
	sw	$0, 4($t0)		# size 0bytes para la cabeza
	sw	$0, 8($v0)		# cabeza apunta a null inicialmente
	move	$v0, $0
	b	init_end
init_err:
	li	$v0, -2
init_end:
	# Clausura de compromiso de programador
	addiu	$sp, $sp, 4
	lw	$fp, ($sp)
	jr	$ra
	
#
###############################################################################
# malloc(IN size:entero; OUT address: entero)
# Parametros: 
#	$a0 cantidad de bytes a ser asignados
		
# Retorno:
#	-1 si no hay espacio disponible
# Uso de registros:
#	$t0: direccion de nodo de inicio
#	$t1: direccion de nodo siguiente.
#	$t2: guarda la cantidad de espacios intermedios libres.
#	$t3: registro auxiliar.
	.text
	.globl malloc

malloc:
	# Compromiso de programador
	addiu	$sp, $sp, -4
	sw	$fp, 4($sp)
	move	$fp, $sp
	
	lw	$t1, sizeInit

	# En caso de que el parametro no este en rangos validos
	ble	$a0, $t1 malloc_valid_plus
	b	malloc_inv_number
malloc_valid_plus:
	bgtz	$a0, malloc_valid_number
malloc_inv_number:
	li	$v0, -3
	lw	$fp, 4($sp)
	addiu	$sp, $sp, 4
	jr	$ra
malloc_valid_number:
	lw 	$t0, sizeAvail
	
	# el siguiente branch es el caso en el que TODA la memoria esta disponible
	bne	$t0, $t1, malloc_head_not_init
	lw	$t1, cabezaManej
	sw	$a0, 4($t1)
	lw	$v0, ($t1)
	subu	$t0, $t0, $a0
	sw	$t0, sizeAvail		# Actualizamos el espacio restante
	lw	$fp, 4($sp)
	addiu	$sp, $sp, 4
	jr	$ra

malloc_head_not_init:
	ble	$a0, $t0, malloc_search	# if sizeAvail < $a0:
	b malloc_no_memory

malloc_search:
	# Ahora, llegar aqui no garantiza que hayan bloques de memoria continuos con $a0 bytes.
	lw	$t0, cabezaManej	# $t0 = M.head
	lw	$t1, 8($t0)		# $t1 = a.next
	lw	$t2, ($t0)		# $t2 = a.dir
	lw	$t3, 4($t0)		# $t3 = a.size
	bne	$t3, $0, malloc_not_head	# if a.size == 0: Esto ocurre cuando el segmento de memoria que empieza en (cabezaManej)
					#		fue anteriormente liberado.
	lw	$t3, ($t1)		#	$t3 = $t1.dir
	sub	$t3, $t3, $t2		#
	blt	$t3, $a0, malloc_not_head	# if hayEspacioEnCabeza:
	sw	$a0, 4($t0)		# cabeza.size = $a0
	lw	$v0, ($t0)		# le devolvemos la direccion.
	lw	$t0, sizeAvail
	subu	$t0, $t0, $a0
	sw	$t0, sizeAvail
	
	# Cerramos el compromiso de programador.
	lw	$fp, 4($sp)
	addiu	$sp, $sp, 4
	jr	$ra

malloc_not_head:
	# Si llegamos hasta aqui, fue por que la cabeza de la lista esta ocupada.
	li	$t2, 0			# Este registro llevara acumulado la cantidad de espacios intermedios.
malloc_loop:	# iteramos sobre los nodos del tad manejador en busca de huecos o null
	beqz	$t1, malloc_end_loop		# AQUI INICIA UN LOOP
	lw	$t3, ($t0)		# $t3 = $t0.dir
	lw	$t4, 4($t0)		# $t4 = $t0.size
	add 	$t3, $t4, $t3 		# buscamos hueco, $t3 almacenara la direccion que
					# le daremos al usuario
	rem	$t4, $t3, 4		# calculamos el resto para saber si la dir es multiplo de 4
	beqz	$t4, malloc_calc_space
	li	$t5, 4
	subu	$t4, $t5, $t4		# $t5 = 4 - s % 4
	add	$t3, $t3, $t4		# dirNueva = s + 4 - s % 4
malloc_calc_space:
	lw	$t4, ($t1)		# $t4 = $t1.dir
	subu	$t5, $t4, $t3		# $t5 tendra el espacio libre entre ambos bloques
					# referenciados por $t0 y $t1.

	bgt	$a0, $t5, malloc_next_iter	# if hayEspacioDisponibleEntre(a,b):
	add	$t5, $t0, 12		# $t5 => nodo intermedio de la lista entre $t0 y $t1

	move	$v0, $t3		# $v0 = dir_espacio_a_retornar
	sw	$v0, ($t5)		# $t3.dirManej = $v0
	sw	$a0, 4($t5)		# $$3.size = tamano_pedido
	sw	$t1, 8($t5)		# $t3.next = $t1
	sw	$t5, 8($t0)		# $t1.next = $t3
	lw	$t5, sizeAvail
	subu	$t5, $t5, $a0
	sw	$t5, sizeAvail		# Actualizamos el sizeAvail.
	# Clausura de compromiso de programador:
	lw	$fp, 4($sp)
	addiu	$sp, $sp, 4
	jr $ra				# Retornamos una direccion libre intermedia

malloc_next_iter:	
	add	$t2, $t2, $t5		# $t2 += $t5 Se incrementa la cantidad de espacios libres.
	move	$t0, $t1		# $t0 = $t1
	lw	$t3, 8($t1)
	move	$t1, $t3		# $t1 = $t1.next
	b malloc_loop
malloc_end_loop:
	# Si llegamos hasta aqui, es por que no hay espacios intermedios con $a0 bytes.
	# Nuestro registro $t2 tendra la cantidad de espacios libres intermedios.
	lw	$t3, sizeAvail
	sub	$t2, $t3, $t2
	blt	$t2, $a0, malloc_no_cont_memory	# Verificamos si hay memoria suficiente al final.
	move	$t1, $a0			#salvamos el tamano que pidio el usuario
	li 	$a0, 12				# Pedimos bytes suficientes para crear un nuevo nodo
	li 	$v0, 9				# en la lista
	syscall
	lw	$t3, ($t0)
	lw	$t2, 4($t0)
	add	$t2, $t2, $t3			# Calculamos la proxima direccion a entregar
	rem	$t5, $t2, 4
	beqz	$t5, malloc_no_rem
	sub	$t5, $t5, 4
	neg	$t5, $t5
	add	$t2, $t2, $t5
malloc_no_rem:
	sw	$t2, ($v0)			# La guardamos en el nodo agregado.
	sw	$t1, 4($v0)			# Se guarda la cantidad de bytes pedidos
	sw	$0,  8($v0)			# El proximo del ultimo es null = 0x0
	sw	$v0, 8($t0)
	lw	$t3, sizeAvail
	subu	$t3, $t3, $t1
	sw	$t3, sizeAvail
	move	$v0, $t2			# Para retornar dicha direccion
	
	# Clausura de compromiso de programador
	lw	$fp, 4($sp)
	addiu	$sp, $sp, 4
	jr	$ra
	
malloc_no_memory:
	# Se arroja el codigo -1
	li	$v0, -4
	lw	$fp, 4($sp)
	addiu	$sp, $sp, 4
	jr	$ra
malloc_no_cont_memory:
	# Se arroja el codigo -1
	li	$v0, -6
	lw	$fp, 4($sp)
	addiu	$sp, $sp, 4
	jr	$ra

#
###############################################################################
# free(IN address:entero; OUT code: entero)
# Parametros: 
#	$a0 direccion de comienzo en memoria del segmento de datos
#	que se quiere liberar
		
# Retorno:
#	0 si la operacion se realizo correctamente
#	neg si ocurrio un error

# Uso de registros:


free:
	sub 	$sp, $sp, 4				#prolog
	sw	$fp, 4($sp)
	move	$fp, $sp

									#verificar que el address esta ocupado?

	lw	$t0, cabezaManej

free_loop:
	beqz	$t0,  free_error		#while(a!= null)
									#si apunta a 0 no encontro la direccion
	lw	$t1, ($t0)
	
	beq 	$t1, $a0, free_node		#if(a.di == address)
	move	$t2, $t0				#prev = a
	lw	$t0, 8($t0)				#a = a.next
	b 	free_loop

free_node:
	lw	$t1, dirManej
	
	beq 	$a0, $t1, free_cabeza	#if(a == cabezaManej)
	lw 	$t3, 8($t0) 			#$t3 = a.next
	sw 	$t3, 8($t2)
	lw 	$t2, 4($t0) 				#$t2 = sizeliberado
	lw 	$t3, sizeAvail
	add	$t2, $t3, $t2, 
	sw 	$t2, sizeAvail				#prev.next = a.next
	b	free_end_loop

free_error:
	li 		$v0, -5			#return -1
	b 		free_end

free_cabeza:
	lw 	$t2, 4($t0) 				#$t2 = sizeliberado
	lw 	$t3, sizeAvail
	add	$t2, $t3, $t2, 
	sw 	$t2, sizeAvail
	sw	$0, 4($t0)				#para identificar que la cab esta libre

free_end_loop:
	move	$v0, $0					#return 0

free_end:							#epilog
	lw 	$fp, 4($sp)
	add 	$sp, $sp, 4
	jr	$ra

#
###############################################################################
# reallococ: (IN direc; dir, IN size: OUT address: entero)
# Descripcion:
#	Funcion que toma una direccion previamente retornada por malloc o reallococ
#	y la relocaliza con el fin de poder aumentar o disminuir ese segmento de memoria.
#	Los datos que estan en ese segmento migraran al proximo segmento.
# Parametros:
#	$a0 direccion en memoria
#	$a1 nuevo tamano que tendra ese esgmento de memoria.
# Uso de registros:
#	$s0: Tendra el nodo de la lista que hace referencia a $a0
#	$s1: Tendra el nodo anterior a $s0.
#	$s2: Tendra el tamano anterior.
#	$t0,$t1,$t2: son usados para iterar y carga de data. Son muy temporales.
reallococ:
	# Convenciones del llamado
	sw	$fp, ($sp)
	sw	$ra, -4($sp)
	sw	$s0, -8($sp)
	sw	$s1, -12($sp)
	subi	$sp, $sp, 16
	
	lw	$t0, cabezaManej	# $t0 = primer nodo
	li	$t1, 0			# $t1 = inicializado en 0x0, pero este
					# guardaria el nodo anterior a $t0.
	lw	$t2, ($t0)		# $t2 tiene la direccion que guarda el nodo
					# en la direccion de memoria referenciada
					# por $t0.
reallococ_search_loop:
	# En este loop, buscamos el nodo que referencia al contenido de $a0
	beq	$t2, $a0, reallococ_end_search_loop
	move	$t1, $t0
	lw	$t0, 8($t0)
	lw	$t2, ($t0)
	b	reallococ_search_loop

reallococ_end_search_loop:
	move	$s0, $t0	# $s0 tiene la direccion del nodo de la lista que tiene
				# la direccion que deseo realocar
	move	$s1, $t1	# $s1 tiene el nodo anterior al nodo referenciado por $s0
	
	lw	$s2, 4($t0)	# Guardamos el tamano por si acaso.

	lw	$t0, 4($s0)	# Cargamos el espacio reservado anteriormente
	ble	$a1, $t0, reallococ_less_space

reallococ_more_space:
	# En caso de que se desee aumentar la memoria, primero debemos liberar
	# ese segmento.
	
	# Seguimos las convenciones, en este caso, la subrutina
	# es un llamador.
	sw	$a0, ($sp)
	sw	$a1, -4($sp)
	subi	$sp, $sp, 8
	
	# Ya $a0 tiene la direccion que queremos liberar.
	jal	free
	# Esto no arroja error ya que el argumento es valido.
	
	# Seguimos las convenciones.
	addi	$sp, $sp, 8
	lw	$a0, ($sp)
	lw	$a1, -4($sp)
	
	# Ahora tenemos que hacer malloc con $a1 como argumento,
	# pues queremo ver si hay esa cantidad de espacio.
	# Seguimos las convenciones nuevamente.
	sw	$a0, ($sp)
	sw	$a1, -4($sp)
	subi	$sp, $sp, 8
	
	# Recordemos que $a1 tiene el tamano nuevo.
	move	$a0, $a1
	jal	malloc
	# Esto puede arrojar error en caso de que no haya o no haya
	# espacio continuo. En tal caso, el codigo del error esta en $v0.
	# Si todo salio bien, es decir, se pudo reservar otro segmento de
	# memoria, $v0 sera mayor a 0 y tendra la direccion que me interersa.
	addi	$sp, $sp, 8
	lw	$a0, ($sp)
	lw	$a1, -4($sp)
	blt	$v0, $0, reallococ_nothing_happened
	
	# La subrutina copy_bytes toma tres argumentos
	lw	$a0, ($s0)	# La direccion origen
	move	$a1, $v0	# La direccion destino
	move	$a2, $s2	# La cantidad de bytes que se copian.
	
	sw	$v0, ($sp)	# Guardamos la direccion retorno por si acaso.
	subi	$sp, $sp, 4

	jal	copy_bytes
	
	addi	$sp, $sp, 4
	lw	$v0, ($sp)
	b	reallococ_finish
reallococ_nothing_happened:
	# Recordemos que $s0 tiene todavia la direccion de aquel nodo.
	# Dado que en teoria "se libero" memoria, tenemos que volver
	# a dejar todo como antes.
	# free lo que hace es que el nodo anterior al que tiene la direccion
	# en memoria que se desea eliminar apunte a su siguiente. Tambien
	# actualiza el availSize, incrementandolo.
	# Restauramos sizeAvail
	lw	$t0, sizeAvail
	sw	$s2, 4($s0)	# Restauramos el tamano en el nodo.
	subu	$t0, $t0, $s2	# Decrementamos el tamano disponible.
	sw	$t0, sizeAvail	# Actualizado.
	
	# Ahora tenemos que hacer que el anterior apunte a este.
	# Si el nodo que se elimino fue la cabeza, $s1 seria igual a 0x00,
	# entonces no habria que hacer nada.
	beqz	$s1, reallococ_finish
	
	sw	$s0, 8($s1)	# $s1.next = $s0
	b reallococ_finish
reallococ_less_space:
	# En caso de que se desea reducir la memoria lo que hacemos es cambiar
	# el atributo size del nodo.
	sw	$a1, 4($s0)
	move	$v0, $a0
reallococ_finish:
	addi	$sp, $sp, 16
	lw	$fp, ($sp)
	lw	$ra, -4($sp)
	lw	$s0, -8($sp)
	lw	$s1, -12($sp)
	jr	$ra
	
#
###############################################################################
# copy_bytes(IN dir1:direc, dir2:direc, int size; out: void)
# Descripcion:
#	Funcion que copia size bytes de dir1 a dir2
# Parametros:
#	$a0. Direccion de inicio
#	$a1. Direccion de llegada
#	$a2. Cantidad de bytes a copiar
copy_bytes:
	sw	$fp, ($sp)
	subi	$sp, $sp, 4
	
	li	$t0, 0
copy_bytes_loop:
	bge	$t0, $a2, copy_bytes_fin_loop
	lw	$t1, ($a0)
	sw	$t1, ($a1)
	addi	$a0, $a0, 4
	addi	$a1, $a1, 4
	addi	$t0, $t0, 4
	b copy_bytes_loop
	
copy_bytes_fin_loop:
	addi	$sp, $sp, 4
	lw	$fp, ($sp)
	jr	$ra
	
#
###############################################################################
# perror(IN code:entero; OUT: void)
# Descripcion:
#	Funcion que imprime un mensaje de error basado en code
# Parametros:
#	$a0. codigo de error
# Planificacion de registros:
#	$t0, guarda
perror:
	sw	$fp, ($sp)
	subi	$sp, $sp, 4
	move	$fp, $sp
	
	neg	$a0, $a0
	li	$t0, 1
	beq	$a0, $t0, perror_1
	addi	$t0, $t0, 1
	beq	$a0, $t0, perror_2
	addi	$t0, $t0, 1
	beq	$a0, $t0, perror_3
	addi	$t0, $t0, 1
	beq	$a0, $t0, perror_4
	addi	$t0, $t0, 1
	beq	$a0, $t0, perror_5
	la	$a0, errMessage6
	b	perror_finish
perror_1:
	la	$a0, errMessage1
	b	perror_finish
perror_2:
	la	$a0, errMessage2
	b	perror_finish
perror_3:
	la	$a0, errMessage3
	b	perror_finish
perror_4:
	la	$a0, errMessage4
	b	perror_finish
perror_5:
	la	$a0, errMessage5
	b	perror_finish
perror_finish:
	li	$v0, 4
	syscall
	
	add	$sp, $sp, 4
	lw	$fp, ($sp)
