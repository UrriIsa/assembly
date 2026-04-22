.data
    shell : .asciiz "usu@fciencias:~$"    # así para simular una terminal
    
    #espacios apartados
    buffer: .space 1024     # aparto espacio para respuesta del usuario
    bufferArch : .space 4096    # aparto espacio para contenido de archivo
    arch1 : .space 256   # aparto espacio para archivo 1
    arch2 : .space 256   # aparto espacio para archivo 2
    
    #BORRAR
    msjEntra : .asciiz "hola, entró"
    
    #comandos (usamos para verificar): 
    cmdSong : .asciiz "song"
    cmdRev : .asciiz "rev"
    cmdCat : .asciiz "cat"
    cmdRepr : .asciiz "repr"
    cmdExit : .asciiz "exit"
    
    #Salto línea
    saltoLinea: .asciiz "\n"
    
    # mensaje al usuario
    errorCmd : .asciiz "Comando no reconocido.Puede checar help para más información\n"
    salidaVerif : .asciiz "¿Realmente quieres salir?"
    
    rcmdCmd1 : .asciiz "Uso : [comando] [file1.extension]\nPuede checar help para más información\n"     #recomendación para los argumentos de comando de un archivo
    rcmdCmd2: .asciiz "Uso : [comando] [file1.extension] [file2.extension]\nPuede checar help para más información\n"   #recomendación para los argumentos de comando de un archivo
   
    
    # para song
    kick:      .word 115   
    tambor:    .word 117   
    bajo:      .word 29   
    hat:       .word 42   

    NKick:     .byte 36
    NTambor:   .byte 45
    NBajo:     .byte 33
    NHat:      .byte 62
    
    cancioncita : .byte 64, 64, 67, 62, 64, 60, 62, 57, 55, 57, 60, 62, 60, 57, 55, 52

    
.text
.globl main

main :

buclePrincipal:
    li $v0, 4     # 4 para imprimir string
    la $a0, shell     # cargo la cadena shell
    syscall
    
    li $v0, 8     # 8 para leer string
    la $a0, buffer     # cargo la dirección donde se guarda lo del usuario
    li $a1, 1024    # límite máximo de caracteres
    syscall
    
    #limpiar la entrada del usuario para compararla con los comandos
    la $a0, buffer
    jal FlimpiaEntrada
    
    # ahora actuará como switch-case verificando cada uno
    
    #verifico song
    la $a0, buffer      # cargo a a0 la entrada
    la $a1, cmdSong      # cargo a a1 "song"
    jal FStrComp0      # linkeo el jum para la llamada auxiliar para comparar
    beq $v0, 0, EjctSong
    
    #verifico cat
    la $a0, buffer
    la $a1, cmdCat
    jal FStrComp2
    beq $v0, 0, EjctCat
    
    #verifico exit
    la $a0, buffer
    la $a1, cmdExit
    jal FStrComp0
    beq $v0, 0, EjctExit
    
    #verifico Rev
    la $a0, buffer
    la $a1, cmdRev
    jal FStrComp2
    beq $v0, 0, EjctRev
    
    
     # Si ya entró en uno o si no es ninguno : iteramos
    li $v0, 4
    la $a0, errorCmd
    syscall
    
    j buclePrincipal
    

# -----------------------------------------------------------------------------
# EJECUCIONES -  Comienzan con Ejct
# Ejecuciones de implementación cada comando

# EjecutarSong
EjctSong:
    li $s0, 0
    li $s1, 0
    li $s2, 128
    li $s3, 0

BucleBeat:
    beq $s1, $s2, FinCancion

    bne $s0, 0, ChkKick8
    jal SRpdcKick
    j DespKick
ChkKick8:
    bne $s0, 8, DespKick
    jal SRpdcKick
DespKick:

    bne $s0, 4, ChkSnare12
    jal SRpdcTambor
    j DespSnare
ChkSnare12:
    bne $s0, 12, DespSnare
    jal SRpdcTambor
DespSnare:

    andi $t0, $s0, 1
    bne  $t0, $zero, DespHat
    jal  HatRI
DespHat:

    andi $t0, $s0, 1
    bne  $t0, $zero, DespMel
    jal  BajoMelodia
DespMel:

    li $v0, 32
    li $a0, 110
    syscall

    addi $s0, $s0, 1
    addi $s1, $s1, 1

    li   $t1, 16
    blt  $s0, $t1, BucleBeat
    li   $s0, 0
    j    BucleBeat

FinCancion:
    j buclePrincipal
    
    
# Ejecutar REV
EjctRev:
    la $a0, buffer
    la $a1, arch1
    jal FExtraeArgs1
    beq $v0, 1, FfltArgs1    # no dio ningún argumento

    # intentar abrir como archivo
    la $a0, arch1
    li $v0, 13     # 13 para abrir archivo
    li $a1, 0     # lectura
    syscall
    move $s1, $v0     # muevo el descriptor
    bltz $s1, RevString      # si no hay archiv, entonces es una cadena normal

    # leer contenido del archivo
    move $a0, $s1
    la   $a1, bufferArch
    li   $a2, 4095
    li   $v0, 14     # 14 para leer del archivo
    syscall
    move $t0, $v0     # contenido en t0

    # cerrar archivo
    move $a0, $s1
    li   $v0, 16
    syscall

    blez $t0, buclePrincipal     # archivo vacío

    # poner \0 al final de lo leído
    la  $t1, bufferArch
    add $t1, $t1, $t0     # al bufferArch le sumo lo del contenido
    sb  $zero, 0($t1)    # le pongo el \0

    la $a0, bufferArch
    jal FReversa
    j buclePrincipal

RevString:
    la $a0, arch1
    jal FReversa
    j buclePrincipal    
    
    
    
    
    
# Ejecutar CAT
EjctCat:
   la $a0, buffer    
   la $a1, arch1    
   la $a2, arch2    
   jal FExtraeArgs2
   beq $v0, 1, FfltArgs2    

   # intenta abrir arch1
   la $a0, arch1
   li $v0, 13
   li $a1, 0    # lectura
   syscall
   move $s1, $v0      # guardamos descriptor 1 en $s1
   bltz $s1, FErrorCat    # si es < 0, error

   # intenta abrir arch2
   la $a0, arch2
   li $v0, 13
   li $a1, 0     # Modo lectura
   syscall
   move $s2, $v0      # Guardamos descriptor 2 en $s2
   
   bltz $s2, FErrorCat2 # Si falla el segundo, hay que cerrar el primero

   # si pasamos eso, ambos abrieron, así que leemos e imprimimos
   # arch 1
   move $a0, $s1
   jal FLeerYMostrar   # lee y muestra

   # arch 2
   move $a0, $s2
   jal FLeerYMostrar

   # cerrar ambos
   move $a0, $s1
   li $v0, 16
   syscall
   move $a0, $s2
   li $v0, 16
   syscall

   j buclePrincipal

    
    
#Ejecutar EXIT    
EjctExit : 
    la $a0, salidaVerif
    li $v0, 50      # 50 para el dialogo de confirmación, 0 es Si
    syscall
    beq $a0, $zero, exitFin
    j buclePrincipal
    
exitFin:
    li $v0, 10     # 10 de salida
    syscall


# ------------------------------------------------------------------------------ 
# "FUNCIONES" AUXILIARES - Comienzan con F
# son subrutinas que hace referencias a funciones/métodos en otros lenguajes.
# no son directamente el funcionamiento de cada comando

# Para decirle que faltaron argumentos en comando de 2 argumentos
FfltArgs2:
    li $v0, 4 # para imp String
    la $a0, rcmdCmd2
    j buclePrincipal
    
# Para decirle que faltaron argumentos en comando de 1 argumento
FfltArgs1:
    li $v0, 4 # para imp String
    la $a0, rcmdCmd1
    j buclePrincipal
    
    



#SUBRUTINA para limpiar todas las entradas del usuario de una \n. 0 si limpia, 1 si no
FlimpiaEntrada : 
    move $t0, $a0   #cargo siempre la entrada del ususario en $a0, entonces la muevo a t0 para no perderla

bucleLimpiar :
    lb $t1, 0($t0)    # cargo el caracter de buffer (entrada ususario)
    beqz $t1, finLimpiar    # si el caracter es igual a zero acabé
    li $t2, 10   # cargo ascii del salon de línea
    beq $t1, $t2, rempLimpiar   # si son iguales (caracter y salto) lo debo quitar
    addi $t0, $t0, 1    # avanzo en mi cadena
    j bucleLimpiar
    
rempLimpiar :
   sb $zero, ($t0)   # store byte para guardar el zero en donde estaba el \n, osea, donde apunta t0

finLimpiar :
    jr $ra



#SUBTURINA para checar

FStrComp2:
   move $t2, $a0   # para no romper a0
   move $t3, $a1   # para no romper a1
bucleSC2 :
    lb $t0, 0($t2)    # para cargar el primer byte de la cadena que cargamos en a0 (buffer) con a1 (a comparar)
    lb $t1, 0($t3)    # para cargar el primer byte de la cadena que cargamos en a1 (a comparar)
    
    beqz $t1, finCmd2
    bne $t0, $t1, difer2    # si no son iguales las letras vamos a difer
    
    addi $t2, $t2, 1     #le sumo uno a la dirección para ir a la siguiente letra
    addi $t3, $t3, 1
    j bucleSC2
finCmd2 :
    # el comando terminó; el buffer debe tener ' ' o '\0' aquí
    beqz $t0, igual2
    li   $t4, 32    # ASCII espacio
    beq  $t0, $t4, igual2
difer2 : 
    li $v0, 1    # guardo en v0 el 1, porque fueron diferentes
    jr $ra     # regreso a donde me llamaron
igual2 : 
    li $v0, 0    # guardo en v0 el 0, porque fueron iguales
    jr $ra     # regreso a donde me llamaron
    
# Para guardar los argumentos del archivo. a0 buffer, a1 destino arch1. UN ARCHIVO

FExtraeArgs1:
    move $t0, $a0
    move $t1, $a1

FEA1SaltaCmd:
    lb   $t3, 0($t0)
    beqz $t3, FEA1Error
    li   $t4, 32
    beq  $t3, $t4, FEA1SaltaEsp
    addi $t0, $t0, 1
    j    FEA1SaltaCmd

FEA1SaltaEsp:
    lb   $t3, 0($t0)
    li   $t4, 32
    bne  $t3, $t4, FEA1CopiaArg
    addi $t0, $t0, 1
    j    FEA1SaltaEsp

FEA1CopiaArg:
    lb   $t3, 0($t0)
    beqz $t3, FEA1Fin
    sb   $t3, 0($t1)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j    FEA1CopiaArg

FEA1Fin:
    sb   $zero, 0($t1)
    lb   $t3, 0($a1)
    beqz $t3, FEA1Error
    li   $v0, 0
    jr   $ra

FEA1Error:
    li $v0, 1
    jr $ra



# Para guardar los argumentos del archivo. a0 buffer, a1 destino arch1, a2 destino arch2. DOS ARCHIVOS
FExtraeArgs2: 
    move $t0, $a0   # buffer
    move $t1, $a1    # destino arch1
    move $t2, $a2    # destino arch2
    
# salta el comando hasta el primer espacio
FEASaltaCmd :
    lb $t3, 0($t0)     # cargo carcater
    beqz $t3, FEAError     # termino cadena y no hay espacio, entonces hay error
    li $t4, 32    # cargo ascii de espacio
    beq $t3, $t4, FEASaltaEsp1
    addi $t0, $t0, 1    # avanzo un caracter
    j FEASaltaCmd

# salto los espacios hasta encontrar el argumento 1
FEASaltaEsp1:
    lb $t3, 0($t0)
    li $t4, 32    # de nuevo cargo el espacio
    bne $t3, $t4, FEACopiaArg1    # no hay espacio, entonces copio
    addi $t0, $t0, 1
    j FEASaltaEsp1

FEACopiaArg1 : 
    lb $t3, 0($t0)    #cargo caracter
    beqz $t3, FEAFinArg1    # fin sin espacio (solo 1 arg)
    li $t4, 32    # cargo espacio en ascii
    beq $t3, $t4, FEAFinArg1   # espacio entonces ya
    sb $t3, 0($t1)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j FEACopiaArg1

FEAFinArg1 : 
     sb   $zero, 0($t1)       # terminar arg1 con '\0'
    # verificar que arg1 no esté vacío
    lb   $t3, 0($a1)
    beqz $t3, FEAError

FEASaltaEsp2 : 
    lb   $t3, 0($t0)
    beqz $t3, FEAError      # se acabó el buffer, no hay arg2
    li   $t4, 32
    bne  $t3, $t4, FEACopiaArg2
    addi $t0, $t0, 1
    j    FEASaltaEsp2
    
FEACopiaArg2 : 
    lb   $t3, 0($t0)
    beqz $t3, FEAFinArg2
    sb   $t3, 0($t2)
    addi $t0, $t0, 1
    addi $t2, $t2, 1
    j    FEACopiaArg2
    
FEAFinArg2: 
    sb   $zero, 0($t2)   # terminar arg2 con '\0'

    # verificar que arg2 no esté vacío
    lb   $t3, 0($a2)
    beqz $t3, FEAError

    li   $v0, 0   # éxito
    jr   $ra

FEAError :
    li   $v0, 1    # faltan argumentos
    jr   $ra


# Para sacarle la reversa
FReversa:
    move $s4, $a0     # guardamos inicio para imprimir al final
    move $t0, $a0     # puntero izquierdo
    move $t1, $a0     # buscar fin

FRVBuscaFin:    # recorremos la cadena hasta encontrar el fin \0
    lb   $t2, 0($t1)
    beqz $t2, FRVInvierte    #como ya encontramos el final, podemos invertir
    addi $t1, $t1, 1
    j    FRVBuscaFin

FRVInvierte:
    addi $t1, $t1, -1   # apunta al último caracter, antes del \0

FRVBucle:
    bge  $t0, $t1, FRVImprimir    # >= porque el \0 caracter nulo en ascii es 0, puntero izquierdo cruzó derecho
    lb   $t2, 0($t0)    # puntero izquierdo guarda en t2
    lb   $t3, 0($t1)    # puntero derecho guarda en t3
    sb   $t3, 0($t0)    # puntero derecho en posición izquierda
    sb   $t2, 0($t1)    # puntero izquierda en posición derecho
    addi $t0, $t0, 1    # avanza el de la izquierda
    addi $t1, $t1, -1    # "retrocede" el de la derecha
    j    FRVBucle
# la idea de izquierda y derecha es por ejemplo : [pi->]hola[<-pd]
# así en la primera iteración cambio las letras y avanzo : a[pi->]ol[<-pd]h    (cambié la 'a' y la 'h' y moví mis apuntadores)

FRVImprimir:
    li   $v0, 4    # 4 para imp string
    move $a0, $s4
    syscall
    la   $a0, saltoLinea
    syscall
    jr   $ra



# Funciones para la lectura de archivos
# Recibe en $a0 el descriptor de archivo (fd) ya abierto
FLeerYMostrar:
    move $s0, $a0        # Guardar fd para que syscalls no lo borren

FIALeer:
    move $a0, $s0        # fd
    la   $a1, bufferArch # buffer de lectura
    li   $a2, 4095       # máximo a leer
    li   $v0, 14
    syscall
    move $t0, $v0        # bytes leídos

    blez $t0, FIAFin     # 0 o negativo -> fin o error

    # Poner '\0' al final para imprimir
    la   $t1, bufferArch
    add  $t1, $t1, $t0
    sb   $zero, 0($t1)

    li   $v0, 4
    la   $a0, bufferArch
    syscall

    j FIALeer            # Seguir leyendo

FIAFin:
    jr $ra



# SUBRUTINA para comparar dos cadenas, para comandos sin argumento, por eso el 0
FStrComp0 :
   move $t2, $a0   # para no romper a0
   move $t3, $a1   # para no romper a1
bucleSC :
    
    lb $t0, 0($t2)    # para cargar el primer byte de la cadena que cargamos en a0 (buffer) con a1 (a comparar)
    lb $t1, 0($t3)    # para cargar el primer byte de la cadena que cargamos en a1 (a comparar)
    bne $t0, $t1, difer    # si no son iguales las letras vamos a difer
    
    beq $t0, $zero, igual    #si ya terminó la cadena y son iguales las cadenas
    addi $t2, $t2, 1     #le sumo uno a la dirección para ir a la siguiente letra
    addi $t3, $t3, 1
    j bucleSC
    
difer : 
    li $v0, 1    # guardo en v0 el 1, porque fueron diferentes
    jr $ra     # regreso a donde me llamaron
igual : 
    li $v0, 0    # guardo en v0 el 0, porque fueron iguales
    jr $ra     # regreso a donde me llamaron
    
       
          

FErrorCat2:
   # Si el segundo archivo falló, cerramos el primero que sí se abrió
   move $a0, $s1
   li $v0, 16
   syscall

FErrorCat:
   # Mensaje de error genérico
   la $a0, rcmdCmd2
   li $v0, 4
   syscall
   j buclePrincipal   
    
 
 # SUBRUTINAS DE AUDIO

SRpdcKick:
    li $v0, 31
    lb $a0, NKick
    li $a1, 100
    lw $a2, kick
    li $a3, 127
    syscall
    jr $ra

SRpdcTambor:
    li $v0, 31
    lb $a0, NTambor
    li $a1, 100
    lw $a2, tambor
    li $a3, 90
    syscall
    jr $ra

HatRI:
    li $v0, 31
    lb $a0, NHat
    li $a1, 50
    lw $a2, hat
    li $a3, 70
    syscall
    jr $ra

BajoMelodia:
    la   $t0, cancioncita
    add  $t0, $t0, $s3
    lb   $a0, 0($t0)
    li   $v0, 31
    li   $a1, 200
    lw   $a2, bajo
    li   $a3, 95
    syscall

    addi $s3, $s3, 1
    li   $t1, 16
    blt  $s3, $t1, FinBajoMel
    li   $s3, 0
    
FinBajoMel:
    jr   $ra