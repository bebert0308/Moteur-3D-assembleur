.686 
.model flat,stdcall 
option casemap:none
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

include \masm32\include\windows.inc 
include \masm32\include\gdi32.inc
include \masm32\include\user32.inc 
include \masm32\include\kernel32.inc 
include \masm32\include\esgi32.inc

includelib \masm32\lib\esgi32.lib
includelib \masm32\lib\gdi32.lib
includelib \masm32\lib\user32.lib 
includelib \masm32\lib\kernel32.lib
include masm32.inc
includelib masm32.lib

ifVisible proto
modulo proto :DWORD, :DWORD
affichageCube proto :DWORD

initRotation proto :DWORD
rotationX proto :DWORD, :DWORD, :DWORD, :DWORD
rotationY proto :DWORD, :DWORD, :DWORD, :DWORD
rotationZ proto :DWORD, :DWORD, :DWORD, :DWORD

Projection proto
affichage proto

.const

largeur	equ	600
hauteur	equ	600

.data 
ps	PAINTSTRUCT	<0>
hdc	HDC	0
ClassName	db "Parent Claas Name",0
ClassName_F db "SimpleWinClass",0 	; classe de type SimpleWinClass (fenêtre simple)
AppName  db "Mon super jolie cube en 3d",0 
nAffichage db "Pas d'affichage",0

ButtonClassName db "button",0
ButtonID  equ 1         	; le n°ID du Control de type Button
ButtonID2  equ 6
ButtonText	db	"Modifier angle",0
ButtonDisplay	db	"Afficher/Cacher faces arrières",0
hwndButton	HWND	?
hwndButton2	HWND	?

EditClassName db "edit",0	; classe de type edit (zone d'édition de texte)
EditX db "0",0
EditY db "0",0
EditZ db "0",0
EditZoom db "500",0
hwndEdit HWND ?	; handle de l'EDIT
hwndEdit2 HWND ?	; handle de l'EDIT
hwndEdit3 HWND ?	; handle de l'EDIT
hwndEdit4 HWND ?	; handle de l'EDIT
EditID equ 2           	; le n°ID du Control de type 'Zone d'édition' (de saisie de texte) 
EditID2 equ 3
EditID3 equ 4
EditID4 equ 5

egal db " = ",0
plus db " + ",0
calcul db " divise par ", 0
space db 10,0

dfe dd 400
zoff dd 500
xoff dd 300
yoff dd 300

angle dd 0
angleX dd 0
angleY dd 0
angleZ dd 0
demiAngle dd 180

var1 dd 0
var2 dd 0
var3 dd 0
var4 dd 0
var5 dd 0
var6 dd 0

counterMod dd 0
counter dd 0
counter2d dd 0
resultat dd 0
indice dd 0

activateHidden dd 1

object3d dd -100,-100,-100,
			100,-100,-100,
			100,100,-100,
			-100,100,-100,
			100,-100,100,
			-100,-100,100,
			-100,100,100,
			100,100,100

faces dd	0,1,2,3,0,
			1,4,7,2,1,
			4,5,6,7,4,
			5,0,3,6,5,
			5,4,1,0,5,
			3,2,7,6,3

.data? 
x	dd	?
y	dd	?
hInstance HINSTANCE ? 
CommandLine LPSTR ? 

object2d dd 16 dup(?)
cos	REAL8	360	dup(?)
sin	REAL8	360	dup(?)
object3dRota dd 24 dup(?)

buffer db 512 dup(?)

.const 

.code 
start:
	invoke initRotation, 0
	invoke Projection
	;call affichage
    
    invoke GetModuleHandle, NULL 
    
    mov    hInstance,eax 
    invoke GetCommandLine
    mov CommandLine,eax 
    invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT 
    invoke ExitProcess,eax

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD 
    LOCAL wc:WNDCLASSEX 
    LOCAL msg:MSG 
    LOCAL hwnd:HWND 
    
    mov   	wc.cbSize, SIZEOF WNDCLASSEX	; taille de la structure de la window class
	mov   	wc.style, CS_HREDRAW or CS_VREDRAW ; style de la fenêtre : redessinée si redim. ou mouv. horizontal ou vertical
	mov   	wc.lpfnWndProc, OFFSET WndProc	;pointeur vers la fonction de gestion de la fenêtre
	mov   	wc.cbClsExtra, NULL	; nombre de bits supplémentaires à allouer après la window class
	mov   	wc.cbWndExtra, NULL	; nombre de bits supplémentaires à allouer après l'instance de fenêtre
	push  	hInst 
    pop   	wc.hInstance ; un handle de l'instance qui contient la fonction de gestion de la fenêtre
	mov   	wc.hbrBackground, COLOR_WINDOW+1	; handle de la class backgroune brush utilisé pour le fond de la fenêtre
	mov   	wc.lpszMenuName, NULL	; pointeur vers une chaîne précisant le nom de la ressource menu name
	mov   	wc.lpszClassName, OFFSET ClassName ; pointeur vers le nom de la classe de la fenêtre
	
    invoke 	LoadIcon, NULL, IDI_APPLICATION ; arg1=handle vers le module contenant l'icone à charger, NULL pour une icone prédéfinie, arg2=nom del'icone à charger ou icone prédéfinie 
	
	mov   	wc.hIcon, eax	; un handle de la classe icon (vers une ressource de type icon)
	mov   	wc.hIconSm, eax	; un handle de la classe small icon (vers une ressource de type icon)
	
	invoke 	LoadCursor, NULL, IDC_ARROW	; arg1=handle vers le module contenant le curseur à charger, NULL pour un curseur prédéfini, arg2=nom du curseur à charger ou curseur prédéfini
	
	mov   	wc.hCursor, eax	; un handle de la classe cursor (vers une ressource de type cursor)
	
	invoke 	RegisterClassEx, addr wc	; enregistre la window class définie au-dessus

    invoke CreateWindowEx,WS_EX_CLIENTEDGE,ADDR ClassName, \ 
                        ADDR AppName, WS_OVERLAPPEDWINDOW + WS_HSCROLL + WS_VSCROLL,\ 
                        CW_USEDEFAULT, CW_USEDEFAULT,\ 
                        largeur,hauteur,NULL,NULL, hInst,NULL
    
    mov   	hwnd, eax	; eax=valeur de retour de CreateWindowEx, copiée dans hwnd 
    
	invoke 	ShowWindow, hwnd, SW_SHOWNORMAL ; handle de la fenêtre
											; mode d'affichage de la fenêtre
    
    messages:
        invoke GetMessage, ADDR msg,NULL,0,0 
        cmp eax,0
        jle fin_boucle 
        invoke TranslateMessage, ADDR msg 
        invoke DispatchMessage, ADDR msg 
    jmp messages
    fin_boucle:
    mov     eax,msg.wParam 
    ret 
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM 
    
    cmp uMsg,WM_DESTROY	; demande de fermeture de la fenêtre (clic sur croix rouge)
    je destroy
    cmp uMsg,WM_CREATE	; à la création de la fenêtre
    je create
    cmp uMsg,WM_COMMAND	; si message reçu d'un menu ou d'un contrôle (bouton, edit, liste...)
    je command
    cmp uMsg,WM_PAINT	; message WM_PAINT envoyé à chaque rafraîchissement de la fenêtre
    je paintHidden
    invoke DefWindowProc,hWnd,uMsg,wParam,lParam ; si aucun des messages précédents
    ret 
    
    destroy:
    	invoke PostQuitMessage,NULL
    	
    jmp fin_messages 

	create:
		invoke CreateWindowEx,WS_EX_CLIENTEDGE, ADDR EditClassName,addr EditX,\ 
                    WS_CHILD or WS_VISIBLE or WS_BORDER or ES_CENTER or\ 
                    ES_AUTOHSCROLL,\ 
                    50,35,100,25,hWnd,EditID,hInstance,NULL	; Création du contrôle EDIT 
        mov  hwndEdit,eax
        invoke CreateWindowEx,WS_EX_CLIENTEDGE, ADDR EditClassName,addr EditY,\ 
                    WS_CHILD or WS_VISIBLE or WS_BORDER or ES_CENTER or\ 
                    ES_AUTOHSCROLL,\ 
                    50,65,100,25,hWnd,EditID2,hInstance,NULL	; Création du contrôle EDIT 
        mov  hwndEdit2,eax
        invoke CreateWindowEx,WS_EX_CLIENTEDGE, ADDR EditClassName,addr EditZ,\ 
                    WS_CHILD or WS_VISIBLE or WS_BORDER or ES_CENTER or\ 
                    ES_AUTOHSCROLL,\ 
                    50,95,100,25,hWnd,EditID3,hInstance,NULL	; Création du contrôle EDIT 
        mov  hwndEdit3,eax
        invoke CreateWindowEx,WS_EX_CLIENTEDGE, ADDR EditClassName,addr EditZoom,\ 
                    WS_CHILD or WS_VISIBLE or WS_BORDER or ES_CENTER or\ 
                    ES_AUTOHSCROLL,\ 
                    50,125,100,25,hWnd,EditID4,hInstance,NULL	; Création du contrôle EDIT 
        mov  hwndEdit4,eax
		invoke CreateWindowEx,NULL, ADDR ButtonClassName,ADDR ButtonText,\ 
                    WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
                    50,155,100,25,hWnd,ButtonID,hInstance,NULL
		mov  hwndButton,eax
		invoke CreateWindowEx,NULL, ADDR ButtonClassName,ADDR ButtonDisplay,\ 
                    WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
                    200,35,200,25,hWnd,ButtonID2,hInstance,NULL
		mov  hwndButton2,eax
		
	command:
        mov eax,wParam ; récupération de l'identifiant de l'expéditeur dans eax.
        
        cmp lParam,0
        je fin_messages ; si lParam=0 alors le message vient d'un menu : on n'en a pas ici
    	
    	; lParam différent de 0 donc message envoyé par un Control
    	
    	cmp ax,ButtonID	; ax = mot de poids faible de wParam = ID du contrôle qui a envoyé le message
        jne suite1 ; si ce n'est pas le bouton qui a envoyé le message
 		
 			; si ax=ButtonID
        	shr eax,16 ; rotation de 16 bits à droite (poids fort devient poids faible : ax = poids fort)
           	cmp ax,BN_CLICKED	; mot de poids fort de wParam = code de notification du contrôle
        	jne fin_messages ; si ce n'est pas un clic sur le bouton qui a envoyé le message
       			; si ax=BN_CLICKED
       			invoke GetWindowText,hwndEdit,ADDR buffer,512	; récupération du contenu de l'EDIT dans buffer
        		invoke atol, addr buffer	; conversion du contenu du buffer en DWORD dans eax
        		mov angleX, eax
        		invoke GetWindowText,hwndEdit2,ADDR buffer,512	; récupération du contenu de l'EDIT dans buffer
        		invoke atol, addr buffer	; conversion du contenu du buffer en DWORD dans eax
        		mov angleY, eax
        		invoke GetWindowText,hwndEdit3,ADDR buffer,512	; récupération du contenu de l'EDIT dans buffer
        		invoke atol, addr buffer	; conversion du contenu du buffer en DWORD dans eax
        		mov angleZ, eax
        		invoke GetWindowText,hwndEdit4,ADDR buffer,512	; récupération du contenu de l'EDIT dans buffer
        		invoke atol, addr buffer	; conversion du contenu du buffer en DWORD dans eax
        		mov zoff, eax
       			invoke initRotation, 1
       			invoke Projection
       			cmp activateHidden, 1
       			je paintHidden
       			jmp paintNotHidden
    suite1:
    	cmp ax,ButtonID2	; ax = mot de poids faible de wParam = ID du contrôle qui a envoyé le message
        jne fin_messages ; si ce n'est pas le bouton qui a envoyé le message
 		
 			; si ax=ButtonID
        	shr eax,16 ; rotation de 16 bits à droite (poids fort devient poids faible : ax = poids fort)
           	cmp ax,BN_CLICKED	; mot de poids fort de wParam = code de notification du contrôle
        	jne fin_messages ; si ce n'est pas un clic sur le bouton qui a envoyé le message
       			cmp activateHidden, 1
       			je paintNotHidden
       			
    paintHidden:
    		mov activateHidden, 1
  			mov eax, RDW_ERASE
            or eax, RDW_INVALIDATE
            invoke RedrawWindow, hWnd, NULL, NULL, eax
  		
       		invoke BeginPaint, hWnd, ADDR ps	; lance le dessin de la fenêtre
			mov hdc, eax	; BeginPaint retourne le handle du contexte où on dessine
			call ifVisible
			
			invoke EndPaint, hWnd, ADDR ps ; fin du dessin de la fenêtre
			jmp fin_messages
    paintNotHidden:
    		mov activateHidden, 0
    		mov eax, RDW_ERASE
            or eax, RDW_INVALIDATE
            invoke RedrawWindow, hWnd, NULL, NULL, eax
  		
       		invoke BeginPaint, hWnd, ADDR ps	; lance le dessin de la fenêtre
			mov hdc, eax	; BeginPaint retourne le handle du contexte où on dessine
    
   			invoke affichageCube,0
   			invoke affichageCube,1
   			invoke affichageCube,2
   			invoke affichageCube,3
   			invoke affichageCube,4
   			invoke affichageCube,5
   			
   			invoke EndPaint, hWnd, ADDR ps ; fin du dessin de la fenêtre
    fin_messages:
    xor    eax,eax 
    ret 
WndProc endp 

initRotation proc param:DWORD

	cmp param, 1
	je startRotation
	
	boucleRadian:
 		fldpi
 		fimul angle ; on multiplie pi avec l'andle
 		fidiv demiAngle ; obtention de angZ en radian
 		fsincos ; calcul du sinus puis cosinus
 		mov ecx,angle
 		fstp cos[ecx*REAL8] ; recuperation du cosinus st(0)
 		fstp sin[ecx*REAL8]	;recuperation du sinus st(1)
 		inc angle
 		cmp angle,360
 		jb boucleRadian
 	
 	startRotation:
 		mov counter, 0
 	boucleRotation:
 		cmp counter,24
 		je finInit
		mov eax,counter
		mov edx,object3d[eax*DWORD];Position en x
		mov var1,edx
		inc counter		
		mov eax,counter
		mov edx,object3d[eax*DWORD];Position en y
		mov var2,edx
 		inc counter		
 		mov eax,counter
		mov edx,object3d[eax*DWORD];Position en z
		mov var3,edx
		
		invoke rotationX,var1,var2,var3,counter
		invoke rotationY,var1,var2,var3,counter
		invoke rotationZ,var1,var2,var3,counter
		
		mov ecx,var1
		mov edx,var2
		mov ebx,var3
		mov eax,counter
		mov object3dRota[eax*DWORD],ebx;z
		dec eax
		mov object3dRota[eax*DWORD],edx;y
		dec eax
		mov object3dRota[eax*DWORD],ecx;x
		inc counter
 		jmp boucleRotation
	
	finInit:
	
	ret
initRotation endp

rotationX proc posX:DWORD, posY:DWORD, posZ:DWORD, counterRot:DWORD
		fild posY
 		mov ecx,angleX
 		fmul cos[ecx*REAL8]
 		fistp var4
 		
 		fild posZ
 		mov ecx,angleX
 		fmul sin[ecx *REAL8]
 		fstp var2
 		fild var4
 		fsub var2
 		fistp var4
 		
 		fild posY
 		mov ecx,angleX
 		fmul sin [ecx*REAL8]
 		fistp var5
 		
 		fild posZ
 		mov ecx,angleX
 		fmul cos[ecx*REAL8]
 		fstp var2
 		fild var5
 		fadd var2
 		fistp var5
 		
  		mov eax,var4
		mov ecx,var5
		mov var2,eax
		mov var3,ecx
	
	ret
rotationX endp

rotationY proc posX:DWORD, posY:DWORD, posZ:DWORD, counterRot:DWORD
		fild posZ
 		mov ecx,angleY
 		fmul sin[ecx*REAL8]
 		fistp var1
 		
 		fild posX
 		mov ecx,angleY
 		fmul cos[ecx *REAL8]
 		fstp var4
 		fild var1
 		fadd var4 
 		fistp var1
 		
 		fild posZ
 		mov ecx,angleY
 		fmul cos [ecx*REAL8]
 		fistp var3
 		
 		fild posX
 		mov ecx,angleY
 		fmul sin[ecx*REAL8]
 		fstp var4
 		fild var3
 		fsub var4
 		fistp var3
 		
 		mov eax,var1
		mov ecx,var3
		mov var1,eax
		mov var3,ecx
	
	ret
rotationY endp

rotationZ proc posX:DWORD, posY:DWORD, posZ:DWORD, counterRot:DWORD
		fild posX
 		mov ecx,angleZ
 		fmul cos[ecx*REAL8] 
 		fistp var1 
 		
 		fild posY
 		mov ecx,angleZ
 		fmul sin[ecx *REAL8]
 		fstp var4 
 		fild var1 
 		fsub var4 
 		fistp var1
 		
 		fild posX
 		mov ecx,angleZ
 		fmul sin [ecx*REAL8]
 		fistp var2 
 		
 		fild posY 
 		mov ecx,angleZ
 		fmul cos[ecx*REAL8]
 		fstp var4 
 		fild var2
 		fadd var4 
 		fistp var2 
 		
		mov eax,var1
		mov ecx,var2
		mov var1,eax
		mov var2,ecx
	
	ret
rotationZ endp

modulo proc nb:DWORD, modu:DWORD
	
	mov eax, nb
	cmp eax, modu
	jb finModulo
	
	boucle:
		sub eax, modu
		cmp eax, modu
		jae boucle
	
	finModulo:
		mov counterMod, eax
		
	ret
modulo endp

affichageCube proc face:DWORD
	
		mov counter2d, 0
		mov eax, face
		mov ecx, 5
		mul ecx
		mov face, eax
		mov ebx, face
		mov eax, faces[ebx * DWORD]
		mov ecx, 2
		mul ecx
		
		mov ecx, object2d[eax * DWORD]
		mov x, ecx
		
		inc eax
		mov ecx, object2d[eax * DWORD]
		mov y, ecx
		inc counter2d
		
	boucle:
		invoke MoveToEx,hdc,x,y,NULL	; place la pointe de crayon aux coordonnées (x,y)
		
		inc face
		mov ebx, face
		mov eax, faces[ebx * DWORD]
		mov ecx, 2
		mul ecx
		
		mov ecx, object2d[eax * DWORD]
		mov x, ecx
		
		inc eax
		mov ecx, object2d[eax * DWORD]
		mov y, ecx
		inc counter2d
		
		invoke LineTo,hdc,x,y			; trace une ligne de la position précédente à (x,y)
	
	verif:
		cmp counter2d, 5
		jb boucle
		
	finAffichageCube:
	
	ret
affichageCube endp

ifVisible proc 
		mov var1, 0
		mov var2, 0
		mov var3, 0
		mov var4, 0
		mov var5, 0
		mov var6, 0
		mov counter, 0
		mov counter2d, 0
	
	boucle:
		
		mov eax, 0
		mov ebx, 0
		mov ecx, 0
		mov edx, 0
		
		mov eax, counter
		mov ecx, 5
		mul ecx
		mov counter2d, eax
		mov ebx, counter2d
		
		;Obtention des variables de la face
		mov eax, faces[ebx * DWORD]
		mov ecx, 2
		mul ecx
		
		;Coordonée du point haut
		mov ecx, object2d[eax * DWORD]
		mov var1, ecx	;X
		
		inc eax
		mov ecx, object2d[eax * DWORD]
		mov var2, ecx	;Y
		
		inc counter2d
		mov ebx, counter2d
		mov eax, faces[ebx * DWORD]
		mov ecx, 2
		mul ecx
		
		;Coordonnée du point en commun
		mov ecx, object2d[eax * DWORD]
		mov var3, ecx	;X
		
		inc eax
		mov ecx, object2d[eax * DWORD]
		mov var4, ecx	;Y
		
		inc counter2d
		mov ebx, counter2d
		mov eax, faces[ebx * DWORD]
		mov ecx, 2
		mul ecx
		
		;Coordonnée du point a droite
		mov ecx, object2d[eax * DWORD]
		mov var5, ecx	;X
		
		inc eax
		mov ecx, object2d[eax * DWORD]
		mov var6, ecx	;Y
		
		;Calcul des coordonées des vecteurs
		mov eax, var3
		mov ebx, var4
		sub var1, eax
		sub var2, ebx
		sub var5, eax
		sub var6, ebx
		
		;Calcul de la normale
		mov eax, var1
		mul var6
		mov var1, eax
		mov eax, var2
		mul var5
		sub var1, eax
		
		cmp var1, 0
		jl ok
		inc counter
		jmp verif
	ok:
		invoke affichageCube,counter
		inc counter
	verif:
		cmp counter, 6
		jb boucle
	
	finIfVisible:
	ret
ifVisible endp

Projection proc

	mov counter2d, 0
	mov counter, 0
	
	boucleCalcul:
		;On récupère l'indice du X
		mov eax, 4
		mul counter
		mov ecx, eax
		
		;On multiplie le X au DF
		mov eax, dfe
		mul object3dRota[ecx]
		push eax
		
		;On récupère l'indice du Z
		mov ebx, 2
		add counter, ebx
		mov eax, 4
		mul counter
		mov ecx, eax
		
		;On Additionne le Z au Zoff
		mov ebx, object3dRota[ecx]
		add ebx, zoff
		mov resultat, ebx
		
		;On divise Z + Zoff a DF * X Et on ajoute Xoff
		pop var1
		mov eax, var1
		cdq
		idiv resultat
		mov var1, eax
		mov eax, var1
		add eax, xoff
		mov resultat, eax
		
		
		;On enregistre le X
		mov ebx, counter2d
		mov ecx, resultat
		mov object2d[ebx * DWORD], ecx
		
		dec counter
		inc counter2d
		
		;On récupère l'indice du Y
		mov eax, 4
		mul counter
		mov ecx, eax
		
		;On multiplie le Y au DF
		mov eax, dfe
		mul object3dRota[ecx]
		push eax
		
		;On récupère l'indice du Z
		inc counter
		mov eax, 4
		mul counter
		mov ecx, eax
		
		;On Additionne le Z au Zoff
		mov ebx, object3dRota[ecx]
		add ebx, zoff
		mov resultat, ebx
		
		;On divise Z + Zoff a DF * Y Et on ajoute Yoff
		pop var1
		mov eax, var1
		cdq
		idiv resultat
		mov var1, eax
		mov eax, var1
		add eax, yoff
		mov resultat, eax
		
		;On enregistre le Y
		mov ebx, counter2d
		mov ecx, resultat
		mov object2d[ebx * DWORD], ecx
		
		inc counter2d
		inc counter
		cmp counter2d, 16
		jl boucleCalcul
		
	finProjection:
	ret
Projection endp

affichage proc
		mov counter, 0
	boucleAffi:
		mov eax, counter
		invoke StdOut_int, object2d[eax*DWORD]
		invoke StdOut, addr space
		
		inc counter
		cmp counter, 16
		jb boucleAffi
	ret
affichage endp

push 0
call ExitProcess      	
end start