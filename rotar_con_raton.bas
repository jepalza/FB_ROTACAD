


#Include "gl/glut.bi"
#Include "windows.bi"


' incluye las rutinas de rotacion y movimientos con RATON
#Include "rotaciones.bas"





' ============================================ PRINCIPAL ===============================================

' Inicializa la ventana OPENGL
GL_Inicializa(800,600)

' Inicializa el sistema de movimientos con Raton
RT_Inicializa() 


' poner a "0" para visualizar SIN efectos
#If 1
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'       opcionales, para mejorar la presentacion grafica
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' varios tipos de luces y sombreados.
	' se pueden elegir todos, ninguno o variados, para ver diferencias
	Dim As Single light_ambient(4)  = { 0.0, 0.0, 0.0, 1.0 }
	Dim As Single light_diffuse(4)  = { 1.0, 1.0, 1.0, 1.0 }
	Dim As Single light_specular(4) = { 1.0, 1.0, 1.0, 1.0 }
	Dim As Single light_position(4) = { 1.0, 1.0, 1.0, 0.0 }
	Dim as Single mat_ambient(4)    = { 0.7, 0.7, 0.7, 1.0 }
	Dim As Single mat_diffuse(4)    = { 0.8, 0.8, 0.8, 1.0 }
	Dim As Single mat_specular(4)   = { 1.0, 1.0, 1.0, 1.0 }
	Dim As Single high_shininess(4) = { 100.0 }
	
	glLightfv(GL_LIGHT0, GL_AMBIENT , @light_ambient(0)) 
	glLightfv(GL_LIGHT0, GL_DIFFUSE , @light_diffuse(0)) 
	glLightfv(GL_LIGHT0, GL_SPECULAR, @light_specular(0)) 
	glLightfv(GL_LIGHT0, GL_POSITION, @light_position(0)) 
	
	glMaterialfv(GL_FRONT, GL_AMBIENT , @mat_ambient(0)) 
	glMaterialfv(GL_FRONT, GL_DIFFUSE , @mat_diffuse(0)) 
	glMaterialfv(GL_FRONT, GL_SPECULAR, @mat_specular(0)) 
	glMaterialfv(GL_FRONT, GL_SHININESS,@high_shininess(0)) 
	
	' obligatorios si se elige alguno de los anteriores
	' per tambien funcionan por separado, y le dan un tono sombreado al color
	glEnable(GL_LIGHTING) 
	glEnable(GL_LIGHT0) 
	glEnable(GL_COLOR_MATERIAL) 
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	' estas son opcionales tambien, pero si se quitan , no hay profundidad ni tonos de sombras
	glDepthFunc(GL_LESS) 
	glEnable(GL_DEPTH_TEST) 
	glEnable(GL_NORMALIZE)
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
#EndIf





Print "Giro del 'mundo' al estilo CAD"
Print "Usando la tecla CONTROL junto al raton:"
Print "  boton izquierdo hace lupas"
Print "  boton del medio giros"
Print "  boton derecho mueve"
Print ""
Print "para cambiar punto de giro, pulsacion rapida del "
Print "   boton del medio, junto a CTRL"


' bucle infinito entre los eventos
glutMainLoop() 

