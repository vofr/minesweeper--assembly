.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Minesweeper",0
area_width EQU 640
area_height EQU 480
area DD 0

counter DD 0 ; numara evenimentele de tip timer

;variable
i DD 0
j DD 0
startX DD 0
startY DD 0
index DD 0
random DD ?
vecinj DD -1, -1, -1 ,0,0,1,1,1
vecini DD -1, 0, 1,-1,1,-1,0,1
nrb dd 0
x dd 0
y dd 0 
placi_descoperite DD 0
finaljoc DD 0

;stari 
stare DD 64  dup (0)
numere_descoperite DD 64 dup(0)

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

TerenArea macro x, y ,longitude, altitude, colour 
local loop_line, loop_colorate
push ecx
push edx
mov eax, y
mov ebx, area_width
mul ebx
add eax, x
shl eax, 2
add eax, area
mov ecx, altitude

loop_line:
	mov esi, ecx
	mov ecx, longitude

loop_colorate:
	mov dword ptr[eax], colour
	add eax, 4
	loop loop_colorate
	mov ecx, esi
	add eax, area_width*4
	sub eax, longitude*4
	loop loop_line
pop edx
pop ecx
endm 

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	TerenArea 50, 50, 400, 400, 0ffeb99h;tabla
	
	TerenArea 46, 46, 404,4, 663300h ;linii
	TerenArea 50, 96, 400,4, 663300h
    TerenArea 50, 146, 400,4, 663300h
    TerenArea 50, 196, 400,4, 663300h
     TerenArea 50, 246, 400,4, 663300h
	TerenArea 50, 296, 400,4, 663300h 
	TerenArea 50, 346, 400,4, 663300h
     TerenArea 50, 396, 400,4, 663300h
     TerenArea 50, 446, 400,4, 663300h
	 
	 	TerenArea 46, 50, 4,400, 663300h ;;coloane
	TerenArea  96, 50, 4,400, 663300h
    TerenArea 146, 50, 4,400, 663300h
    TerenArea 196, 50, 4,400, 663300h
     TerenArea  246, 50, 4,400, 663300h
	TerenArea 296, 50, 4,400, 663300h 
	TerenArea 346, 50, 4,400, 663300h
     TerenArea  396, 50, 4,400, 663300h
     TerenArea 446,50,  4,400, 663300h
	;jmp afisare_litere

mov ecx, 10;10 bombe
	plantam_bombe:
		rdtsc ;nr random
		xor eax, edx
		mov random, eax
		mov eax, 6258971
		mul random
		xor eax, 8374615;;nr random
		mov edx, 0
		mov ebx, 64 
		div ebx; nr random din vectorul de stari
		cmp stare[edx*4], 9 ;0  nr , 9 e bomba
		je new_bomb
		mov dword ptr stare[edx*4], 9
		jmp planted
		new_bomb:
		inc ecx
		planted:			
loop plantam_bombe

	  jmp afisare_litere
	
evt_click:
;intrebi daca ai castiat sau pierdut
cmp finaljoc, 1
je saritura

;slvam coordonata si ordonata(in tabla?)
	mov eax, [ebp+arg2]
	mov i,eax
	mov eax, [ebp+arg3]
    mov j, eax	
	cmp i, 50
	jb evt_timer
	cmp j, 50
	jb evt_timer	
	cmp i, 450
	ja evt_timer
	cmp j, 450
	ja evt_timer
	
	mov ecx, 49;div cu 50 ca sa luam startul patratului
	cautaCoordonataStart:
	mov edx, 0
	mov eax, i
	mov ebx, 50
	div ebx
	cmp edx, 0
	je nuDecrementez
	Dec i 
	nuDecrementez:
		mov edx, 0
	mov eax, j
	mov ebx, 50
	div ebx
	cmp edx, 0
	je nuDecrementezj
	Dec j 
	nuDecrementezj:
	
	loop cautaCoordonataStart
	;TerenArea i, j, 46,46, 003344H
	
	;cauta index
	mov eax,i
    sub eax, 50
	mov edx,0
	mov ebx, 50
	div ebx ;eax=(i-50)/50
	mov index,eax
	mov x, eax
	mov eax, j
	sub eax,50
	mov edx,0
	mov ebx, 50
	div ebx ;eax=(j-50)/50
	mov y, eax
	mov ebx,8
	mul ebx
    add eax,index
	mov index, eax ;coloana+linia*8=>index
	cmp stare[eax*4], 9
	je am_gasit_bomba
	
	
	
	
	;calcul de bombe
	mov nrb, 0
	mov eax, index
	mov edx, 0
	mov ebx, 8
	div ebx
	mov eax, index
	cmp eax, 8;linia sus
	jb vecin_stanga
	cmp edx, 0;coloana stanga
	je vecin_deasupra
	sub eax, 9 ;vecin stanga sus
	cmp stare[eax*4], 9
	jne vecin_deasupra
	inc nrb
	vecin_deasupra:
	mov eax, index
	sub eax, 8
	cmp stare[eax*4], 9
	jne vecin_dreapta_sus
	inc nrb
	vecin_dreapta_sus:
	mov eax, index
	sub eax, 7
	cmp edx, 7;ultima coloana
	je vecin_stanga
	cmp stare[eax*4], 9
	jne vecin_stanga
	inc nrb
	vecin_stanga:
	mov eax, index
	sub eax, 1
	cmp edx, 0;prima coloana
	je vecin_dreapta
	cmp stare[eax*4], 9
	jne vecin_dreapta
	inc nrb
	vecin_dreapta:
	mov eax, index
	add eax, 1
	cmp edx, 7
	je vecin_stanga_jos
	cmp stare[eax*4], 9
	jne vecin_stanga_jos
	inc nrb
	vecin_stanga_jos:
	 mov eax, index
	 cmp eax, 55;ultima linie
	 ja final_numarare 
	 add eax, 7
	cmp edx, 0
	je vecin_jos
	cmp stare[eax*4], 9
	jne vecin_jos
	inc nrb
	vecin_jos:
	mov eax, index
	add eax, 8
	cmp stare[eax*4], 9
	jne vecin_dreapta_jos
	inc nrb
	vecin_dreapta_jos:
	cmp edx, 1
	je final_numarare
	mov eax, index
	add eax, 9
	cmp stare[eax*4], 9
	jne final_numarare
	inc nrb
	final_numarare:
	
	
	mov edx, nrb
	add edx, '0';conversie caracter
	make_text_macro edx, area, i, j
	
	mov eax, index
	cmp numere_descoperite[eax*4], 1
	je final_verificare
	mov dword ptr numere_descoperite[eax*4], 1
	inc placi_descoperite
	final_verificare:
	cmp placi_descoperite, 54
	je win
	
	
	jmp evt_timer
	
	
	
	am_gasit_bomba:
	TerenArea i, j, 46,46, 0ff0000h
	 make_text_macro 'G', area, 460, 120
	 make_text_macro 'A', area, 470, 120
	  make_text_macro 'M', area, 480, 120
	   make_text_macro 'E', area, 490, 120
	    make_text_macro 'O', area, 460, 140
		 make_text_macro 'V', area, 470, 140
		  make_text_macro 'E', area, 480, 140
		   make_text_macro 'R', area, 490, 140
	  mov finaljoc, 1
	 jmp saritura
win:
	make_text_macro 'W', area, 460, 200
	 make_text_macro 'I', area, 470, 200
	 make_text_macro 'N', area, 480, 200
		  mov finaljoc, 1
	 jmp saritura
	;aici sari
evt_timer:
	inc counter
	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	
	;scriem un mesaj
	saritura:

final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	mov ecx, 1000
	iesire:
		make_text_macro 'G', area, 460, 120
	 make_text_macro 'O', area, 470, 120
	  make_text_macro 'O', area, 480, 120
	loop iesire
	push 0
	call exit
	iesire1:
end start