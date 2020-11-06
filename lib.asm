
section .data

global floatCmp
global floatClone
global floatDelete

global strClone
global strLen
global strCmp
global strDelete
global strPrint

global docClone
global docDelete

global listAdd

global treeInsert
global treePrint

extern malloc
extern free
extern fprintf
extern getCloneFunction
extern getDeleteFunction
extern getCompareFunction
extern listNew
extern getPrintFunction
extern listPrint

; offsets lista
%define offset_type 0
%define offset_size 4
%define offset_first 8
%define offset_last 16

; offsets documento
%define offset_count 0
%define offset_elemData 8
%define offset_vector 8

; offsets nodo lista
%define offset_data 0
%define offset_next 8
%define offset_prev 16

; offsets arbol
%define offset_raiz 0
%define offset_tam 8
%define offset_type_clave 12
%define offset_duplicate 16
%define offset_type_data 20

; offsets nodo arbol
%define offset_clave 0
%define offset_valores 8
%define offset_izquierda 16
%define offset_derecha 24

parentesis: DB "(", 0
flecha_arbol: DB ")->", 0
string_formato: DB "%s", 0
string_vacio: DB 'NULL',0


section .text


;*** Float ***

floatCmp:
  push rbp
  mov rbp, rsp
  xor rax, rax	; Limpiamos el registro de salida
	movss xmm0, [rdi] ; mueve floats
	movss xmm1, [rsi]
	comiss xmm0, xmm1 ; compara floats, setea eflags
	je .iguales
	ja .mayor
	mov eax, 1
	jmp .fin

  .mayor:

    mov eax, -1
    jmp .fin

  .iguales:
    mov eax, 0

  .fin:
  pop rbp
	ret

floatClone:
  push rbp
  mov rbp, rsp

  movss xmm0, [rdi]
  xor rdi, rdi
  mov rdi, 32
  call malloc
  movss [rax], xmm0

  pop rbp
  ret

floatDelete:
	push rbp
	mov rbp, rsp
  call free
  pop rbp
  ret

;*** String ***

strClone:
  ; rdi <- &a posicion del string a copiar

	push rbp
	mov rbp, rsp
	push r12
	push r13

	mov r12, rdi

	call strLen
	inc dword eax
	mov dword r13d, eax
	mov dword edi, eax
	call malloc

	xor rcx, rcx
	xor rdx, rdx

	.ciclo:
 		mov byte dl, [r12 + rcx]
 		mov byte [rax + rcx], dl

 		inc dword ecx
 		cmp dword r13d, ecx
 		jnz .ciclo

	.fin:
 		pop r13
 		pop r12
 		pop rbp
 		ret

strLen:
  ; aridad: uint32_t strLen(char* a)
  ; rdi <- &a
  push rbp
	mov rbp, rsp

	xor rcx, rcx ; limpiamos el contador

	.ciclo:
    ; cálculo de longitud
  		cmp byte [rdi], 0
  		je .fin
  		inc rdi
  		inc rcx
  		jmp .ciclo

	.fin:
 		xor rax, rax
  	mov rax, rcx
  	pop rbp
  	ret


strCmp:
  push rbp
  mov rbp, rsp
  push r14
  push r15

  .ciclo:
  xor r14, r14
  xor r15, r15
  mov byte r14b, [rdi] ; guardo el comienzo de a
  mov byte r15b, [rsi] ; guardo el comienzo de b
  cmp byte r14b, r15b  ; comparo los char
  jl .menor
  jg .mayor
  cmp dword r14d, 0    ; Si alguno es 0, entonces fin
  je .iguales
  inc dword edi           ; rdi apunta al proximo char
  inc dword esi           ; rsi apunta al proximo char
  jmp .ciclo

  .menor:
  mov dword eax, 1
  jmp .fin
  .mayor:
  mov dword eax, -1
  jmp .fin
  .iguales:
  mov eax, 0

  .fin:
  pop r15
  pop r14
  pop rbp
  ret

strDelete:
  push rbp
  mov rbp, rsp
  call free
  pop rbp
  ret

strPrint:
  ; void strPrint(char* a, FILE *pFile);
  ; rdi <- &a
  ; rsi <- &pFile
  push rbp
  mov rbp, rsp
  push r14
  push r15

  .archivos:
    mov r14, rsi ; r14 <- &file
    mov r15, rdi ; r15 <- &a

    ; Vemos si es el string vacío
  	cmp byte [r15], 0
    JE .nulo

  .imprimir:
    mov rdi, r14
    mov rsi, string_formato
    mov rdx, r15
    call fprintf
    jmp .fin

  .nulo:
    mov rdi, r14
    mov rsi, string_formato
    mov rdx, string_vacio
    call fprintf

  .fin:
    pop r15
    pop r14
    pop rbp
    ret

;*** Document ***

docClone:
	; aridad: document_t* docClone(document_t* a)
	; rdi <- &documento

	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15

	; Guardamos longitud y puntero a vector del viejo documento
	xor r15, r15
	mov r15, [rdi]							          ; r15 <- tamaño del documento
	mov qword r12, [rdi + offset_vector]	; r12 <- puntero a vector viejo

	; Creamos nuevo documento
	mov rdi, 16
	call malloc
	mov r13, rax							  ; r13 <- puntero a nuevo documento
	mov [r13], r15							; asignamos tamaño nuevo documento

	; creamos nuevo vector de elementos
	mov dword eax, r15d		   ; rax <- longitud del vector
	mov qword rdi, 16	; rdi <- tamaño de las posiciones del vector
	mul rdi				    ; rax <- resultado de la multiplicación
  mov rdi, rax
	call malloc
	mov r14, rax		; r14 <- puntero a vector nuevo
	mov qword [r13 + offset_vector], r14	; asignamos al nuevo documento el nuevo vector

	; Recorremos ambos vectores
	.ciclo:
		cmp dword r15d, 0
		je .fin
		; clonar dato viejo
		mov dword edi, [r12]	; rdi <- tipo de dato del elemento actual
		call getCloneFunction	; rax <- puntero a funcion clonar
		mov qword rdi, [r12 + offset_elemData]	; rdi <- puntero a dato a clonar
		call rax	; rax <- puntero a dato clonado
		; mover al nuevo vector
		xor rdx, rdx
		mov dword edx, [r12]
		mov dword [r14], edx	; asignamos tipo de dato
		mov qword [r14 + offset_elemData], rax
		; Pasamos a la siguiente posición
		add r12, 16
		add r14, 16
		; decrementamos el contador y volvemos al ciclo
		dec dword r15d
		jmp .ciclo

	.fin:
	mov rax, r13

	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

docDelete:
	; aridad: void docDelete(document_t* a)
	; rdi <- &a
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15

	; Guardamos longitud del documento
	xor r12, r12
	mov qword r12, [rdi]	; r12 <- longitud del documento

	; Guardamos puntero a documento y a vector de elementos
	mov r15, rdi								; r15 <- puntero a documento
	mov qword r13, [rdi + offset_vector]		; r13 <- puntero a vector

	; Recorremos el vector liberando los datos guardados
	mov r14, r13	; r14 <- indice vector
	.ciclo:
		cmp dword r12d, 0
		je .fin
		mov rdi, [r14 + offset_type]
		call getDeleteFunction
    mov rdi, [r14 + offset_elemData]
    call rax
		add r14, 16
		dec dword r12d
		jmp .ciclo

	.fin:
	; Liberamos la memoria del vector y del documento
	mov rdi, r13
	call free
	mov rdi, r15
	call free

	pop r15
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

;*** List ***

listAdd:
    ; aridad: void listAdd(list_t* l, void* data)
    ; rdi <- &lista
    ; rsi <- &dato

    push rbp
    mov rbp, rsp
    push r8
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8

    mov r14, rdi
    mov r13, rsi

    %define lista_ptr r14
    %define dato_ptr r13

    ; asigno espacio para nuevo nodo:
    .asignacion:
    mov rdi, 24
    call malloc
    mov r12, rax
    %define nodo_ptr r12
    mov qword [nodo_ptr + offset_data], dato_ptr    ; asignamos al nuevo nodo el puntero al dato
    mov qword [nodo_ptr + offset_next], 0		        ; ponemos en null los punteros del nuevo nodo
    mov qword [nodo_ptr + offset_prev], 0

    ; Busco el lugar del nuevo nodo en la lista:
    .busqueda:
    mov rcx, [lista_ptr + offset_size]               ; rcx <- tamaño de la lista
    cmp rcx, 0
    je .listaVacia
    mov rdi, [lista_ptr + offset_type]               ; rdi <- tipo de los elementos de la lista
    call getCompareFunction
    mov r11, rax
    %define comparar r11
    mov qword rdi, [lista_ptr + offset_first]
    mov qword rdi, [rdi]
    mov rsi, dato_ptr
    call comparar                         ; a = primero lista, b = nuevo
    cmp eax, -1                           ; nuevo < primero lista
    je .agregarPrimero
    cmp eax, 0
    je .agregarPrimero
    mov r15, [lista_ptr + offset_first]	  ; r15 <- puntero a primer elemento de la lista
    jmp .ciclo

    .ciclo:
    mov rdi, [r15]                      ; rdi <- dato actual
    mov rsi, dato_ptr                   ; rsi <- dato nuevo
    call comparar
    cmp eax, -1                         ; a = actual, b = nuevo
    je .agregar                         ; nuevo < actual
    jmp .avanzar

    .avanzar:
    cmp qword [r15 + offset_next], 0
    je .agregarUltimo
    mov r15, [r15 + offset_next]
    jmp .ciclo

    .agregar:
    mov r8, [r15 + offset_prev]        ; r8 <- puntero a anterior del actual
    mov [r8 + offset_next], nodo_ptr	 ; conecto el siguiente del anterior del actual con el nuevo
    mov [nodo_ptr + offset_prev], r8	 ; conecto el anterior del nuevo con el anterior del actual
    mov [nodo_ptr + offset_next], r15	 ; conecto el siguiente del nuevo con el actual
    mov [r15 + offset_prev], nodo_ptr	 ; conecto el nuevo como anterior del actual
    jmp .fin

    .listaVacia:
    mov [lista_ptr + offset_first], nodo_ptr ; primero de la lista es nuevo nodo
    mov [lista_ptr + offset_last], nodo_ptr  ; ultimo de la lista es nuevo nodo
    jmp .fin

    .agregarPrimero:
    mov r8, [lista_ptr + offset_first]        ; r8 <- puntero a primer nodo
    mov [r8 + 16], nodo_ptr                   ; conecto anterior de actual a nuevo
    mov [nodo_ptr + 8], r8                    ; conecto siguiente de nuevo a primero
    mov [lista_ptr + offset_first], nodo_ptr  ; conecto primero lista a nuevo nodo
    jmp .fin

    .agregarUltimo:
    mov r10, [lista_ptr + offset_last]        ; [r10]  <- puntero a ult elemento de la lista
    mov qword [nodo_ptr + offset_prev], r10   ; 1º Guardamos en el anterior del nuevo nodo el último
    mov qword [r10 + offset_next], nodo_ptr   ; 2º Guardamos en el siguiente del ultimo el nuevo nodo
    mov [lista_ptr + offset_last], nodo_ptr   ; 3º Guardamos en el ultimo de la lista el nuevo nodo

    .fin:
    add dword [lista_ptr + offset_size], 1 	; incrementamos la longitud de la lista
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r8
    pop rbp
    ret

;*** Tree ***
treeInsert:
	; Aridad: int treeInsert(tree_t* tree, void* key, void* data)
	; rdi <- &arbol
	; rsi <- &key
	; rdx <- &data

	push rbp
	mov rbp, rsp
  sub rsp,24
  push r11
	push r12
	push r13
	push r14
	push r15

	; Guardamos los punteros a los parámetros
	mov r15, rdi       ; r15 <- puntero a árbol
	mov qword [rbp-8], rsi   ; [rbp-8] <- puntero a llave
	mov r13, rdx
	%define tree_ptr r15
	%define clave_ptr [rbp-8]
	%define dato_ptr r13

	xor rdi, rdi
	mov dword edi, [tree_ptr + offset_type_clave]
	call getCompareFunction
	mov qword [rbp - 16], rax				; [rbp - 16] <- puntero a funcion comparar clave
	%define cmp_clave [rbp - 16]

	cmp qword [tree_ptr], 0
	je .arbolVacio
	mov qword r12, [tree_ptr]				; r12 <- puntero a nodo actual

	.ciclo:
		mov qword rdi, [r12]		; rdi <- clave arbol
		mov qword rsi, clave_ptr	; rsi <- clave buscada
		call cmp_clave
		cmp dword eax, 0
		je .clavesIguales
		cmp eax, 1
		je .der
		jmp .izq

	.clavesIguales:
		; vemos si la lista es vacia
		mov qword r11, [r12 + offset_valores]
		cmp dword [r11 + offset_size], 0
		je .agregarEnLista
		; No es vacía, vemos si duplicate es 1
		cmp dword [tree_ptr + offset_duplicate], 1
		je .agregarEnLista
		jmp .fin_no_agregado

	.agregarEnLista:
		; clonamos el dato pasado por parámetro
		xor rdi, rdi
		mov dword edi, [tree_ptr + offset_type_data]	;edi <- tipo de datos del arbol
		call getCloneFunction
		mov qword rdi, dato_ptr
		call rax		; rax <- puntero a dato clonado
		; agregamos el dato a la lista
		mov qword rdi, [r12 + offset_valores]			; rdi <- puntero a lista del nodo actual
		mov qword rsi, rax								; rsi <- puntero a dato clonado
		call listAdd
		jmp .fin_agregado

	.der:
		; vemos si el nodo a derecha es vacío
		cmp qword [r12 + offset_derecha], 0
		je .nuevoNodoDerecha
		; si no, nos movemos a la derecha
		mov qword r12, [r12 + offset_derecha]
		jmp .ciclo

		.nuevoNodoDerecha:
			; creamos el nuevo nodo
			mov qword rdi, 32
			call malloc
			mov qword [r12 + offset_derecha], rax	; conectamos el nuevo nodo a derecha del actual
			mov r14, rax							; preservamos puntero a nuevo nodo
			mov qword [r14 + offset_izquierda], 0
			mov qword [r14 + offset_derecha], 0
			; clonamos la clave
			xor rdi, rdi
			mov dword edi, [tree_ptr + offset_type_clave]
			call getCloneFunction
			mov qword rdi, clave_ptr
			call rax
			; agregamos la clave al nuevo nodo
			mov qword [r14], rax
			; creamos lista nueva para el nodo
			xor rdi, rdi
			mov dword edi, [tree_ptr + offset_type_data]
			call listNew
			mov qword [r14 + offset_valores], rax	; agregamos la nueva lista al nodo
			mov qword r12, rax						; preservamos puntero a nueva lista
			; clonamos el dato
			xor rdi, rdi
			mov dword edi, [tree_ptr + offset_type_data]
			call getCloneFunction
			mov qword rdi, dato_ptr
			call rax								; rax <- puntero a dato clonado
			; agregamos el dato a la lista
			mov qword rdi, r12
			mov qword rsi, rax
			call listAdd
			; incrementamos el tamaño del arbol
			add dword [tree_ptr + offset_tam], 1
			jmp .fin_agregado


	.izq:
		; vemos si el nodo a izquierda es vacío
		cmp qword [r12 + offset_izquierda], 0
		je .nuevoNodoIzquierda
		; si no, nos movemos a la izquierda
		mov qword r12, [r12 + offset_izquierda]
		jmp .ciclo

		.nuevoNodoIzquierda:
			; creamos el nuevo nodo
			mov qword rdi, 32
			call malloc
			mov qword [r12 + offset_izquierda], rax	; conectamos el nuevo nodo a izquierda del actual
			mov r14, rax							; preservamos puntero a nuevo nodo
			mov qword [r14 + offset_izquierda], 0
			mov qword [r14 + offset_derecha], 0
			; clonamos la clave
			xor rdi, rdi
			mov dword edi, [tree_ptr + offset_type_clave]
			call getCloneFunction
			mov qword rdi, clave_ptr
			call rax
			; agregamos la clave al nuevo nodo
			mov qword [r14], rax
			; creamos lista nueva para el nodo
			xor rdi, rdi
			mov dword edi, [tree_ptr + offset_type_data]
			call listNew
			mov qword [r14 + offset_valores], rax	; agregamos la nueva lista al nodo
			mov qword r12, rax						; preservamos puntero a nueva lista
			; clonamos el dato
			xor rdi, rdi
			mov dword edi, [tree_ptr + offset_type_data]
			call getCloneFunction
			mov qword rdi, dato_ptr
			call rax								; rax <- puntero a dato clonado
			; agregamos el dato a la lista
			mov qword rdi, r12
			mov qword rsi, rax
			call listAdd
			; incrementamos el tamaño del arbol
			add dword [tree_ptr + offset_tam], 1
			jmp .fin_agregado

	.arbolVacio:
		; creamos el nuevo nodo
		mov qword rdi, 32
		call malloc
		mov qword [tree_ptr], rax				; conectamos el nuevo nodo como primero
		mov r14, rax							; preservamos puntero a nuevo nodo
		mov qword [r14 + offset_izquierda], 0
		mov qword [r14 + offset_derecha], 0
		; clonamos la clave
		xor rdi, rdi
		mov dword edi, [tree_ptr + offset_type_clave]
		call getCloneFunction
		mov qword rdi, clave_ptr
		call rax
		; agregamos la clave al nuevo nodo
		mov qword [r14], rax
		; creamos lista nueva para el nodo
		xor rdi, rdi
		mov dword edi, [tree_ptr + offset_type_data]
		call listNew
		mov qword [r14 + offset_valores], rax	; agregamos la nueva lista al nodo
		mov qword r12, rax						; preservamos puntero a nueva lista
		; clonamos el dato
		xor rdi, rdi
		mov dword edi, [tree_ptr + offset_type_data]
		call getCloneFunction
		mov qword rdi, dato_ptr
		call rax								; rax <- puntero a dato clonado
		; agregamos el dato a la lista
		mov qword rdi, r12
		mov qword rsi, rax
		call listAdd
		; incrementamos el tamaño del arbol
		add dword [tree_ptr + offset_tam], 1
		jmp .fin_agregado

	.fin_no_agregado:
		xor rax, rax
		jmp .fin

	.fin_agregado:
		xor rax, rax
		inc rax

	.fin:
    pop r15
  	pop r14
  	pop r13
  	pop r12
  	pop r11
    add rsp, 24
  	pop rbp
  	ret


treePrint:
	; Aridad: void treePrint(tree_t* tree, FILE* pFile)
	; rdi <- &arbol
	; rsi <- &archivo

	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	sub rsp, 8

	; Guardamos los punteros a los parámetros
	mov r12, rdi
	mov r13, rsi

	; Guardamos punteros a las funciones imprimir de los tipos clave y dato
	xor rdi, rdi
	mov edi, [r12 + offset_type_clave]
	call getPrintFunction
	mov r14, rax	; r14 <- puntero a funcion imprimir clave

	cmp qword [r12], 0	; Vemos si es el árbol vacío
	je .fin
	mov rdi, [r12]		; rdi <- puntero a primer nodo
	mov rsi, r13		; rsi <- puntero a archivo
	mov rdx, r14		; rdx <- puntero a funcion imprimir clave
	call inorderPrint	; Llamamos funcion auxiliar desde el primer nodo

	.fin:
	add rsp, 8
	pop r14
	pop r13
	pop r12
	pop rbp
	ret

inorderPrint:
	; aridad: void inorderPrint(treeNode_t*, File* pFile, funcPrint_t* print_key)
	; rdi <- &nodo actual
	; rsi <- &archivo
	; rdx <- &funcion imprimir clave

	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	sub rsp, 8

	; Guardo un puntero al nodo actual
	mov r12, rdi

	; Guardo puntero a FILE
	mov r13, rsi

	; Guardo puntero a función imprimir
	mov r14, rdx

	; Llamamos a inorder print para el subarbol izquierdo
	.izq:
		cmp qword [r12 + offset_izquierda], 0
		je .imprimirRaiz
    mov rdi, [r12 + offset_izquierda]
    mov rsi, r13
    mov rdx, r14
		call inorderPrint

	.imprimirRaiz:
    ;imprimimos parentesis
    mov rdi, r13	; rdi <- FILE*
    mov rsi, string_formato
    mov rdx, parentesis
    call fprintf
		; Imprimimos la clave
		mov rdi, [r12]
		mov rsi, r13
		call r14	; llamo a imprimir la clave
		; Imprimimos ") ->"
		mov rdi, r13	; rdi <- FILE*
		mov rsi, string_formato
		mov rdx, flecha_arbol	; rsi <- mensaje
		call fprintf

		; Imprimimos la lista
		mov rdi, [r12 + offset_valores]
		mov rsi, r13
		call listPrint

	; Llamamos a inorder_print para el subarbol derecho
	.der:
		cmp qword [r12 + offset_derecha], 0
		je .fin
		mov rdi, [r12 + offset_derecha]
    mov rsi, r13
    mov rdx, r14
		call inorderPrint

	.fin:
	add rsp, 8
	pop r14
	pop r13
	pop r12
	pop rbp
	ret
