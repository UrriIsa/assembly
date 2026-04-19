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
    
    # mensaje al usuario
    errorCmd : .asciiz "Comando no reconocido.Puede checar help para más información\n"
    salidaVerif : .asciiz "¿Realmente quieres salir?"
    
    rcmdCmd1 : .asciiz "Uso : [comando] [file1.extension]\nPuede checar help para más información\n"     #recomendación para los argumentos de comando de un archivo
    rcmdCmd2: .asciiz "Uso : [comando] [file1.extension] [file2.extension]\nPuede checar help para más información\n"   #recomendación para los argumentos de comando de un archivo
    
    errorArch : .asciiz "Error con su archivo, porfavor verifique la extensión, locación o permisos el archivo."
    
    # para song
    notas : .word  67, 69, 71, 72, 74, 76, 60, 62, 64, 65   # un array
    duracion : .word 400
    
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
    
    
     # Si ya entró en uno o si no es ninguno : iteramos
    li $v0, 4
    la $a0, errorCmd
    syscall
    
    j buclePrincipal
    

# -----------------------------------------------------------------------------
# EJECUCIONES -  Comienzan con Ejct
# Ejecuciones de implementación cada comando

# SONG y sus auxiliares
EjctSong : 
   li $v0, 4   #imp String
   la $a0, msjEntra
   syscall
   
   j buclePrincipal

EjctCat :
   la $a0, buffer    # buffer cat f1 f2
   la $a1, arch1    # donde guardaré f1
   la $a2, arch2    # donde guardaré f2
   jal FExtraeArgs2
   beq $v0, 1, FfltArgs2    # si es 1 es que algo no estuvo bien (falta argumento)
   
   #abro e imprimo file 1
   la $a0, arch1
   jal FImpArch
   beq $v0, 1, FErrorArch
   
   #abro e imprimo file 2
   la $a0, arch2
   jal FImpArch
   beq $v0, 1, FErrorArch

   j buclePrincipal

    
    
# ------------------------------------------------------------------------------ 
# "FUNCIONES" AUXILIARES - Comienzan con F
# son subrutinas que hace referencias a funciones/métodos en otros lenguajes.
# no son directamente el funcionamiento de cada comando

# Para decirle que faltaron argumentos en comando de 2 argumentos
FfltArgs2:
    li $v0, 4 # para imp String
    la $a0, rcmdCmd2
    j buclePrincipal
    
# Para decirle que hubo un error con su archivo
FErrorArch:
    li $v0, 4 # para imp String
    la $a0, errorArch
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
    



# Compara el primer token de a0 (hasta ' ' o '\0') con la cadena en a1.
# Retorna v0=0 si iguales, v0=1 si diferentes.
FStrCompCmd:
    move $t2, $a0
    move $t3, $a1
bucleSCC:
    lb   $t0, 0($t2)
    lb   $t1, 0($t3)

    beqz $t1, SCCfinCmd        # llegamos al fin del comando a comparar
    bne  $t0, $t1, SCCdifer    # caracteres distintos

    addi $t2, $t2, 1
    addi $t3, $t3, 1
    j    bucleSCC

SCCfinCmd:
    # el comando terminó; el buffer debe tener ' ' o '\0' aquí
    beqz $t0, SCCigual
    li   $t4, 32                # ASCII espacio
    beq  $t0, $t4, SCCigual
    # hay más texto que no coincide
SCCdifer:
    li  $v0, 1
    jr  $ra
SCCigual:
    li  $v0, 0
    jr  $ra



# Para guardar los argumentos del archivo. a0 buffer, a1 destino arch1, a2 destino arch2
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


# abre, imprime y cierra archivos $a0 dirección del nombre, 0 bien, 1 error
FImpArch :

    # 13 abrir archivo
    move $a0, $a0   # nombre ya en a0
    li   $v0, 13
    li   $a1, 0    # 0 = solo lectura
    li   $a2, 0    # permisos extras
    syscall
    move $s0, $v0    # guardar el descriptor

    bltz $s0, FIAError      # si fd < 0, hubo error

    # lee e imprime en bucle
FIALeer:
    move $a0, $s0    # fd
    la   $a1, bufferArch # buffer de lectura
    li   $a2, 4095 # máximo a leer por vuelta
    li   $v0, 14
    syscall
    move $t0, $v0            # bytes leídos

    blez $t0, FIACerrar     # 0 o negativo → EOF o error

    # poner '\0' al final para imprimir como string
    la   $t1, bufferArch
    add  $t1, $t1, $t0
    sb   $zero, 0($t1)

    li   $v0, 4
    la   $a0, bufferArch
    syscall

    j FIALeer    # seguir leyendo si el archivo es grande

FIACerrar:
    move $a0, $s0
    li   $v0, 16  # 16 para cerrar archivp
    syscall

    li   $v0, 0   # 0 de que todo bien 
    jr   $ra

FIAError :
    li   $v0, 1
    jr   $ra


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
    