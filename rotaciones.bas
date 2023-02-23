

'#include "gl/glut.bi" ' necesarios, pero se incluyen en el principal
'#Include "windows.bi"

Dim Shared ctrl_pulsado As Integer=0

Dim Shared As double _Izq    = 0.0
Dim Shared As double _Der    = 0.0
Dim Shared As double _Abajo  = 0.0
Dim Shared As double _Arriba = 0.0
Dim Shared As double _Cerca  = -10.0
Dim Shared As double _Lejos  = 10.0

Dim Shared As integer _RatonX   = 0
Dim Shared As integer _RatonY   = 0
Dim Shared As integer _RatonIzq = FALSE 
Dim Shared As integer _RatonMed = FALSE 
Dim Shared As integer _RatonDer = FALSE 

Dim Shared As double _ActualPosX = 0.0
Dim Shared As double _ActualPosY = 0.0
Dim Shared As double _ActualPosZ = 0.0

Dim Shared as Double _matriz(16)
Dim Shared as Double _matriz_inversa(16)


' declaraciones 
Declare Function RT_LongVector(x As Double , y As Double , z As Double ) As Double 

Declare sub FB_teclacontrol()

Declare Sub RT_Inicializa()  
Declare Sub RT_CogeMatriz() 
Declare Sub RT_Posicion(px As Double ptr, py As Double ptr, pz As Double Ptr, mX As Integer , mY As Integer , vista As Integer Ptr)  
Declare Sub RT_MatrizInversa(matriz As Double Ptr, salida As Double ptr) 

' llamadas desde GL 
Declare Sub RT_Actualiza  Cdecl(ancho As Integer , alto As Integer)  
Declare Sub RT_LeeRaton   Cdecl(mBoton As Integer , mEstado As Integer , mX As Integer , mY As Integer)  
Declare Sub RT_MueveRaton cdecl(mX As Integer , mY As Integer)  

' coordenadas XYZ PRINCIPALES, donde rota y hace ZOOM (x,y,z,?)
Dim Shared as Double RT_PuntoRot(3)= { 0.0, 0.0, 20.0 ,0.0 }


Sub RT_Inicializa() 
    RT_CogeMatriz() 
    glutReshapeFunc(@RT_Actualiza) 
    glutMouseFunc  (@RT_LeeRaton) 
    glutMotionFunc (@RT_MueveRaton) 
End Sub


Sub RT_Actualiza Cdecl(ancho As Integer , alto As Integer ) 
    glViewport(0,0,ancho,alto) 
    _Arriba =  1.0 
    _Abajo  = -1.0 
    _Izq    = -ancho/alto 
    _Der    = -_Izq 
    glMatrixMode(GL_PROJECTION) 
    glLoadIdentity() 
    glOrtho(_Izq,_Der,_Abajo,_Arriba,_Cerca,_Lejos) 
    glMatrixMode(GL_MODELVIEW) 
End Sub


Sub RT_LeeRaton Cdecl(mBoton As Integer , mEstado As Integer , mX As Integer , mY As Integer ) 
   
	Static As double tiempo=0 ' controla el tiempo que se mantiene pulsado el boton del medio
	Dim As Byte puntorotacion=0
	
	' sin la tecla CTRL (izq. o der.), no hay movimientos
   FB_teclacontrol()
   
   ' raton a nuevas coordenadas
    _RatonX = mX 
    _RatonY = mY 
    
    puntorotacion=0 ' por defecto, no se emplea hasta que se pulsa
    
    ' si hemos pulsado la tecla CONTROL
    if (mEstado=GLUT_UP) Then ' boton raton sin pulsar
        Select Case (mBoton)
        	case GLUT_LEFT_BUTTON    
        		_RatonIzq = FALSE
        	Case GLUT_MIDDLE_BUTTON  
            _RatonMed = FALSE
            ' si soltamos el boton del medio antes de 20milisegundos, se activa el punto de rotacion nuevo
            If (Timer*100)-tiempo<20 Then 
            	puntorotacion=1
            EndIf
        	Case GLUT_RIGHT_BUTTON   
            _RatonDer = FALSE
        End Select 
    ElseIf (mEstado=GLUT_DOWN) Then ' boton raton pulsado
        Select Case (mBoton)
        	case GLUT_LEFT_BUTTON    
        		_RatonIzq = TRUE
           Case GLUT_MIDDLE_BUTTON  
            _RatonMed = TRUE
            tiempo=Timer*100 ' guardamos el momento en el que se pulsa el boton del medio
        	Case GLUT_RIGHT_BUTTON   
            _RatonDer = TRUE
        End Select 
    End If
    
   ' recupero la matriz de la nueva posicion
	'   vista[0] es mX
	'   vista[1] es mY
	'   vista[2] es ancho
	'   vista[3] es alto
   Dim As GLint vista(3) 
   glGetIntegerv(GL_ViewPort,@vista(0)) 
   ' y guardo los datos
   RT_Posicion(@_ActualPosX,@_ActualPosY,@_ActualPosZ,mX,mY,@vista(0)) 
    
    
   '''''''''''''''''''''''''''''''
   ' localiza el punto mas cercano al raton, de los elementos 3D que ve en pantalla 
	Dim As GLfloat  winX, winY, winZ ' posicion XY del raton (la Z se calcula abajo)
	Dim As GLdouble posX, posY, posZ ' aqui va la posicion 3D del raton proyectado
	
   Dim As GLdouble vistamodelo(15)	
	glGetDoublev( GL_MODELVIEW_MATRIX , @vistamodelo(0) )
	
	Dim As GLdouble proyeccion(15) 
	glGetDoublev( GL_PROJECTION_MATRIX, @proyeccion(0) )
	
	' cogemos la XY del raton
	winX = CSng(mX)
	winY = CSng(vista(3)) - CSng(mY) ' a la Y se le resta la profundidad de la pantalla
	
	' buscamos la Z del raton en 3D
	glReadPixels(winX, CInt(winY), 1, 1, GL_DEPTH_COMPONENT, GL_FLOAT, @winZ )
	
	' usando el vista ya cogido antes
	gluUnProject( winX, winY, winZ, @vistamodelo(0), @proyeccion(0), @vista(0), @posX, @posY, @posZ)
	
	' Print "punto localizado mas cercano al raton:";posX,posY,posZ
	' una vez localizado, lo asignamos al punto de giro principal
	' If mBoton=GLUT_Izq_BUTTON And mBoton=GLUT_MIDDLE_BUTTON Then
	If puntorotacion Then
		RT_PuntoRot(0)=posX
		RT_PuntoRot(1)=posY
		RT_PuntoRot(2)=posZ
	End If
	'''''''''''''''''''''''''''''''

	' actualizamos el mundo
   glutPostRedisplay() 
End Sub


' movimientos y rotaciones sgun raton
Sub RT_MueveRaton Cdecl(mX As Integer , mY As Integer) 
    Dim As integer HayCambio = FALSE 
    
    Static as Integer dx 
    	dx=mX - _RatonX 
    
    static As integer dy 
    	dy=mY - _RatonY 
    
    Dim As GLint vista(4) 
    
    glGetIntegerv(GL_ViewPort,@vista(0)) 
    if (dx=0 And dy=0) Then return 
    
    ' con boton izquierdo+CTRL hacemos ZOOM (Lupas)
    if (_RatonIzq  And ctrl_pulsado) Then '  Or  (_RatonIzq  And  _RatonDer)
        Dim As Double escala = exp(dy*0.004) ' con 0.01 en un I7 va muy rapido
        ' si quitamos los dos glTranslate, el punto de ZOOM pasa a ser el "0,0,0", igual es mas logico
        ' si no, el ZOOM lo hace en el mismo punto de giro, pero si este queda alejado, el ZOOM parece descontrolado
        glTranslatef( RT_PuntoRot(0), RT_PuntoRot(1), RT_PuntoRot(2)) ' se situa en el punto de rotacion
        glScalef(escala,escala,escala) ' hace el ZOOM
        glTranslatef(-RT_PuntoRot(0),-RT_PuntoRot(1),-RT_PuntoRot(2)) ' vuelve al punto original
        HayCambio = TRUE 
    Else ' con boton medio+CTRL, ROTACIONES
        if (_RatonMed  And ctrl_pulsado) Then 
        		Dim As Double ax,ay,az 
            Dim As Double bx,by,bz 
            Dim As Double angulo 
            ax = dy 
            ay = dx 
            az = 0.0 
            angulo = RT_LongVector(ax,ay,az)/(vista(2)+1)*180.0 
            ' matriz inversa para determinar la rotacion
            bx = _matriz_inversa(0)*ax + _matriz_inversa(4)*ay + _matriz_inversa(8) *az 
            by = _matriz_inversa(1)*ax + _matriz_inversa(5)*ay + _matriz_inversa(9) *az 
            bz = _matriz_inversa(2)*ax + _matriz_inversa(6)*ay + _matriz_inversa(10)*az 
            glTranslatef( RT_PuntoRot(0), RT_PuntoRot(1), RT_PuntoRot(2)) 
            glRotatef(angulo,bx,by,bz) 
            glTranslatef(-RT_PuntoRot(0),-RT_PuntoRot(1),-RT_PuntoRot(2)) 
            HayCambio = TRUE 
        Else ' con boton derecho+CTRL MOVEMOS
            if (_RatonDer  And ctrl_pulsado) Then 
                Dim As Double px,py,pz 
                RT_Posicion( @px,@py,@pz,mX,mY,@vista(0)) 
                glLoadIdentity() 
                glTranslatef(px-_ActualPosX,py-_ActualPosY,pz-_ActualPosZ) 
                glMultMatrixd(@_matriz(0)) 
                _ActualPosX = px 
                _ActualPosY = py 
                _ActualPosZ = pz 
                HayCambio = TRUE 
            End If
        End If
    End If
    _RatonX = mX 
    _RatonY = mY
    if (HayCambio) Then 
        RT_CogeMatriz() 
        glutPostRedisplay() 
    End If
End Sub


' calcula la longitud de un vector
' ejemplo: x1.1, y2.2, z3.3 es igual a 4.1158
Function RT_LongVector(x As Double , y As Double , z As Double ) As Double 
    return sqr(x*x+y*y+z*z) 
End Function


' gira las coordenadas del raton
Sub RT_Posicion(px As Double ptr, py As Double ptr, pz As Double ptr, mX As Integer ,mY As Integer , vista As Integer Ptr) 
    *px = (mX-vista[0])/(vista[2]) 
    *py = (mY-vista[1])/(vista[3]) 
    *px = _Izq + (*px)*(_Der-_Izq) 
    *py = _Arriba + (*py)*(_Abajo-_Arriba) 
    *pz = _Cerca 
End Sub


Sub RT_CogeMatriz() 
    glGetDoublev(GL_MODELVIEW_MATRIX,@_matriz(0)) 
    RT_MatrizInversa(@_matriz(0),@_matriz_inversa(0)) 
End Sub





 
#Define MAT(matriz,r,c) (matriz)[(c)*4+(r)]

#Define m11 MAT(matriz,0,0)
#Define m12 MAT(matriz,0,1)
#Define m13 MAT(matriz,0,2)
#Define m14 MAT(matriz,0,3)
#Define m21 MAT(matriz,1,0)
#Define m22 MAT(matriz,1,1)
#Define m23 MAT(matriz,1,2)
#Define m24 MAT(matriz,1,3)
#Define m31 MAT(matriz,2,0)
#Define m32 MAT(matriz,2,1)
#Define m33 MAT(matriz,2,2)
#Define m34 MAT(matriz,2,3)
#Define m41 MAT(matriz,3,0)
#Define m42 MAT(matriz,3,1)
#Define m43 MAT(matriz,3,2)
#define m44 MAT(matriz,3,3)

Sub RT_MatrizInversa(matriz As Double ptr, salida As Double Ptr) 

   Dim As GLdouble det 
   Dim As GLdouble d12, d13, d23, d24, d34, d41 
   Dim As GLdouble tmp(16)

   d12 = (m31*m42-m41*m32) 
   d13 = (m31*m43-m41*m33) 
   d23 = (m32*m43-m42*m33) 
   d24 = (m32*m44-m42*m34) 
   d34 = (m33*m44-m43*m34) 
   d41 = (m34*m41-m44*m31) 
   tmp(0) =  (m22 * d34 - m23 * d24 + m24 * d23) 
   tmp(1) = -(m21 * d34 + m23 * d41 + m24 * d13) 
   tmp(2) =  (m21 * d24 + m22 * d41 + m24 * d12) 
   tmp(3) = -(m21 * d23 - m22 * d13 + m23 * d12) 

   det = m11 * tmp(0) + m12 * tmp(1) + m13 * tmp(2) + m14 * tmp(3) 

      Dim As GLdouble invDet = 1.0 / det 

      tmp(0) *= invDet 
      tmp(1) *= invDet 
      tmp(2) *= invDet 
      tmp(3) *= invDet 
      tmp(4) = -(m12 * d34 - m13 * d24 + m14 * d23) * invDet 
      tmp(5) =  (m11 * d34 + m13 * d41 + m14 * d13) * invDet 
      tmp(6) = -(m11 * d24 + m12 * d41 + m14 * d12) * invDet 
      tmp(7) =  (m11 * d23 - m12 * d13 + m13 * d12) * invDet 

      d12 = m11*m22-m21*m12 
      d13 = m11*m23-m21*m13 
      d23 = m12*m23-m22*m13 
      d24 = m12*m24-m22*m14 
      d34 = m13*m24-m23*m14 
      d41 = m14*m21-m24*m11 
      tmp(8)  =  (m42 * d34 - m43 * d24 + m44 * d23) * invDet 
      tmp(9)  = -(m41 * d34 + m43 * d41 + m44 * d13) * invDet 
      tmp(10) =  (m41 * d24 + m42 * d41 + m44 * d12) * invDet 
      tmp(11) = -(m41 * d23 - m42 * d13 + m43 * d12) * invDet 
      tmp(12) = -(m32 * d34 - m33 * d24 + m34 * d23) * invDet 
      tmp(13) =  (m31 * d34 + m33 * d41 + m34 * d13) * invDet 
      tmp(14) = -(m31 * d24 + m32 * d41 + m34 * d12) * invDet 
      tmp(15) =  (m31 * d23 - m32 * d13 + m33 * d12) * invDet 

      For f As integer=0 To 15
      	salida[f]=tmp(f)
      Next

End Sub


' -------------------------  control de tecla CONTROL segun FB ---------------
' captura eventos para el sistema RT_ de movimientos
Sub FB_teclacontrol()

	' para enviar una tecla "falsa" a la ventana GLUT y simular su pulsacion
	' de modo que la deteccion de la tecla CONTROL sea real
	' requiere "windows.bi"
	' >>>>>>>>>>>>>   https://www.freebasic.net/forum/viewtopic.php?t=26079  <<<<<<<<<<<<<
	Type IINPUT
	   itype As Integer
	   Union
	      mi As MOUSEINPUT
	      ki As KEYBDINPUT   
	      hi As HARDWAREINPUT
	   End Union
	End Type
	Dim As IINPUT ip
	ip.itype = INPUT_KEYBOARD
	ip.ki.wVk = VK_A 'VK_CONTROL ' enviamos "A" por enviar algo, lo que sea
	SendInput(1,Cast(LPINPUT,@ip),SizeOf(ip))

End Sub





' -------------------------   rutinas OPEN GL ---------------------------------

' control de errores GL
sub GL_ERROR()
     Dim As GLenum code = glGetError()
     while (code<>GL_NO_ERROR)
         Print "ERROR GL:";gluErrorString(code)
         code = glGetError()
     Wend
End Sub
    
'  dibuja MUNDO
Sub GL_MUNDO() 

   glPushMatrix()   
       
      ' punto desde donde se mira,   punto hacia donde se mira,   vector de direccion de vision
      ' lo ideal es que el punto HACIA (el del centro) apunte al punto de rotacion
      ' y que el punto DESDE este por delante (en esta caso X) al menos 0.1
      gluLookAt(1,0,0,  0,0,0  ,0,1,0)
         
      ' clasica tetera amarilla
      glTranslatef(12,0,0)
      glColor3f(.4,.4,.4) ' gris para el alambre
      glutWireTeapot (5.0)   ' tetera alambre 
      glColor3f(0.6,0.6,0.0) ' amarillo
      glutSolidTeapot (5.0)   ' tetera solido 
                     
                     
      ' centro de la esfera del eje         
      glTranslatef(-12,0,0)
	      
	      ' esfera central gris de los ejes 
	      glColor3f(0.3,0.3,0.3)
	      glutSolidSphere(0.3, 20, 20) 
	      
	      ' flecha roja
	      glPushMatrix() ' guarda la matriz, de modo que la rotacion que viene ahora, solo afecte al cono rojo
		      glPushName(1) 
		         glColor3f(1,0,0) ' rojo
		         glRotatef(90,0,1,0) 
		         glutSolidCone(0.2, 4.0, 20, 20) 
		      glPopName() 
	      glPopMatrix() ' recupera la matriz general
	      
	      ' flecha verde
	      glPushMatrix () ' guarda la matriz, de modo que la rotacion que viene ahora, solo afecte al cono verde
		      glPushName(2)
		         glColor3f(0,1,0) ' verde
		         glRotatef(-90,1,0,0) 
		         glutSolidCone(0.2, 4.0, 20, 20) 
		      glPopName() 
	      glPopMatrix() ' recupera la matriz general
	       
	      ' flecha azul
	      ' este eje no hace falta rotar como los otros dos, por eso no lleva PUSH/POP MATRIX
		      glPushName(3) 
		      	glColor3f(0,0,1) ' azul
		         glutSolidCone(0.2, 4.0, 20, 20)
		      glPopName() 
            
        ' pone un puntito blanco brillante en el punto de rotacion
        ' las coordenadas se ponen al reves (2,1,0) por que estamos dentro de un PUSHMATRIX
        glTranslatef(RT_PuntoRot(2),RT_PuntoRot(1),RT_PuntoRot(0))   
 	     glColor3f(1,1,1)
	     glutSolidSphere(0.1, 20, 20)            
            
   glPopMatrix() 

End Sub


' eventos de dibujado
Sub GL_DIBUJA cdecl() 
   GL_ERROR() 
	   glClear(GL_COLOR_BUFFER_BIT  Or  GL_DEPTH_BUFFER_BIT) 
	   GL_MUNDO() 
	   glutSwapBuffers() 
   GL_ERROR()
End Sub

' lecturas del teclado con OPENGL
' nota: mX y mY son posicion de Raton, pero aqui no se emplean
Sub GL_Teclado cdecl(tecla As ubyte, mX As Integer, mY As integer)
	Dim As integer ctrl
	'Print tecla
	ctrl = glutGetModifiers()
	ctrl_pulsado=0
	if (ctrl = GLUT_ACTIVE_CTRL) Then 
       ctrl_pulsado=1
	EndIf
	
	' si pulsamos ESCAPE
	If ( tecla = 27 ) Then
		If  MessageBox (NULL, "¿Estas seguro de querer salir?", "Finalizar Programa", 1)=1 Then End 0
	End If
End Sub


' inicializa la ventana principal OPENGL
Sub GL_Inicializa(ancho As Integer , alto As integer)
	' Initializa GLUT y crea la ventana grafica
	glutInitDisplayMode(GLUT_DOUBLE  Or  GLUT_RGB  Or  GLUT_DEPTH) 
	glutInitWindowSize(ancho,alto) 
	glutCreateWindow("Movimientos y rotaciones con Raton estilo CAD") 
	
	' llamadas a GLUT
	glutDisplayFunc(@GL_DIBUJA) 
	glScalef(0.25,0.25,0.25) 
	
	' intercepta las llamadas al teclado, para capturar la tecla CTRL
	glutKeyboardFunc(@GL_Teclado)

End Sub
