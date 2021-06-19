IDEAL
MODEL small
STACK 100h
DATASEG ; <------------------------------------------------------------ DATA segment (Variables, params)
    ; --------------------------
    ; variables
    ; --------------------------
    p_0000        db 'zi0000.bmp',0
    p_0001        db 'zi0001.bmp',0
    p_0020        db 'zi0020.bmp',0
    p_0021        db 'zi0021.bmp',0
    p_0200        db 'zi0200.bmp',0
    p_0201        db 'zi0201.bmp',0
    p_0220        db 'zi0220.bmp',0
    p_0221        db 'zi0221.bmp',0
    p_1000        db 'zi1000.bmp',0
    p_1001        db 'zi1001.bmp',0
    p_1020        db 'zi1020.bmp',0
    p_1021        db 'zi1021.bmp',0
    p_1200        db 'zi1200.bmp',0
    p_1201        db 'zi1201.bmp',0
    p_1220        db 'zi1220.bmp',0
    p_1221        db 'zi1221.bmp',0
	
    gmover        db 'GOmer.bmp',0

  	len           equ 77
    thanks        db '****** Thanks for Playing :) the  MEMORY CARD GAME - By Omer Shubeli    ******',13,10,'$'

    filehandle    dw ?
    Header        db 54    dup (0) ; BMP Header - first 54B           
    Palette       db 256*4 dup (0) ; BMP colors board (palette)  - 256 colors each is 4B total of 1KB
    ScrLine       db 320   dup (0) ; BMP Line (e.g. 200 lines) each contains 320 pixels that each contain 1B (represent color index 0-255 to be read from Palette) - total of 320B
    ErrorMsg      db 'Error', 13, 10 ,'$'
                                    	                                
CODESEG  ; <------------------------------------------------------------ CODE Segment (Func's + code)
; ------------------------------------------------
; Function  : PrintMsg                 
; Operation : prints [dx] 
; ------------------------------------------------ 
;proc PrintMsg                          
    ;mov dx, offset tel                                 
	
	;push seg message --> from book "how to string with enter's"
    ;pop ds
    ;mov dx, offset message
	
;	mov ah, 9                       
;	int 10h 
 ;   ret	
;endp PrintMsg                        
                    
; ------------------------------------------------
; Function  : Print                 
; Operation : prints [si] 
;             digit by digit        
; ------------------------------------------------ 
proc Print                          
	mov cx, len                     
   ;mov si, offset tel              
PrintDigit:                         
	mov al, [si]                    
	mov bl, 00000010b               
	push cx   ;                       
	mov cx, 1    
	
	mov ah, 9 ; display string                      
	int 10h                         
	
	mov ah, 3 ; auxilary input                      
	int 10h                         
	
	inc dl                          
	
	mov ah, 2  ; char output                     
	int 10h                         
	
	inc si                          
	pop cx                          
	loop PrintDigit 

    mov dl, 10
    mov ah, 02h
    int 21h
	
    mov dl, 13
    mov ah, 02h
    int 21h
	
	ret                             
endp Print 
                         					                                    
; ------------------------------------------------
; Function  : InitMouse              
; Operation : returns Mouse click position      
; ------------------------------------------------ 
proc InitMouse
	mov ax,0  ; init mouse
	int 33h
	
	mov ax,1  ; show mouse on screen
	int 33h
	
	ret
endp InitMouse                          
									
; ------------------------------------------------
; Function  : GetMouse              
; Operation : returns Mouse click position      
; ------------------------------------------------ 
proc GetMouse
 Wait_for_mouse_left_click:
    mov ax,3  ; get mouse-click location and status
	int 33h
	cmp bx, 1 ; bx[1:0] -> 0- no push; 1 - left click; 2 - right click
	jne Wait_for_mouse_left_click
	
	; cx      -> mouse location line number (0..639) in graphic mode we have 0..319 only
	; dx      -> mouse location column number (0..199)
	
	shr cx,1 ; adjust cx to (0..319) by divide by 2	
	
   ;mov ah,0 ; Press any key to continue
   ;int 16h
	
    call GetAnyKey ; moved into the fuction to ease the code complexity
	
	ret
endp GetMouse

; ------------------------------------------------
; Function  : GetAnyKey              
; Operation : Stall till uset hit any key      
; ------------------------------------------------ 
proc GetAnyKey
	mov ah,0 ; Press any key to continue
	int 16h
	ret
endp GetAnyKey

; ------------------------------------------------
; Function  : CloseFile              
; Operation : Opens "filename"      
; ------------------------------------------------ 
proc CloseFile
	mov ah,3Eh ; close file
	mov bx, [filehandle]
	int 21h
	ret
endp CloseFile

; ------------------------------------------------
; Function  : ShowBMP              
; Operation : Opens BMP move it to Video memory      
; ------------------------------------------------ 
proc ShowBMP
     call OpenFile                   
     call ReadHeader                 
     call ReadPalette                
     call CopyPal                    
     call CopyBitmap                 
	 ret
endp ShowBMP

; ------------------------------------------------
; Function  : OpenFile  (step 1)            
; Operation : Opens "filename"      
; ------------------------------------------------ 
proc OpenFile                       
; Open file                         
  mov ah, 3Dh  ; open file                     
  xor al, al                        
  ;mov dx, offset filename   --> this line is loaded when we call the proc         
  int 21h                           
  jc openerror                      
  mov [filehandle], ax              
  ret                               

openerror :                         
  mov dx, offset ErrorMsg            
  mov ah, 9h                        
  int 21h                           
  ret                               
 endp OpenFile                      
                                                                  
; ------------------------------------------------
; Function  : ReadHeader  (step 2)            
; Operation : Read BMP 54B header      
; ------------------------------------------------                                      
proc ReadHeader                     
 ; Read BMP file header, 54 bytes    
  mov ah,3fh ; read file                       
  mov bx, [filehandle]              
  mov cx,54  ; size to read: 54 bytes                       
  mov dx,offset Header              
  int 21h                           
  ret                               
endp ReadHeader                     
                                                                     
; ------------------------------------------------
; Function  : ReadPalette  (step 3)            
; Operation : Read Color Board (Palette) 1024B       
; ------------------------------------------------                                               
proc ReadPalette                    
 ; Read BMP file color palette, 256 colors * 4 bytes (400h)
  mov ah,3fh   ; read file                     
  mov cx,400h  ; size to read:1024 bytws                     
  mov dx,offset Palette             
  int 21h                           
  ret                               
endp ReadPalette                    
                                    
; ------------------------------------------------
; Function  : CopyPal     (step 4)        
; Operation : Copy Palette to video memory ports      
; ------------------------------------------------                                     
proc CopyPal                        
 ; Copy the colors palette to the video memory
 ; The number of the first color should be sent to port 3C8h
 ; The palette is sent to port 3C9h  
  mov si,offset Palette             
  mov cx,256                        
  mov dx,3C8h  ; port number is 3C8h                     
  mov al,0                          
  ; Copy starting color to port 3C8h
  out dx,al                         
  ; Copy palette itself to port 3C9h
  inc dx                            
                                                                
PalLoop:                            
  ; Note: Colors in a BMP file are saved as BGR values rather than RGB
  
  mov al,[si+2] ; <-------------- Get Red value .    [R]
  shr al,2 ; Max. is 255, but video palette maximal
  ; value is 0..63. Therefore dividing by 4
  out dx,al ; Send it .              
  
  mov al,[si+1] ; <-------------- Get Green value .  [G]
  shr al,2                           
  out dx,al ; Send it .              
  
  mov al,[si]   ; <-------------- Get Blue value .   [B]  
  shr al,2                           
  out dx,al ; Send it .              
  
  add si,4 ; Point to next color .   (each color is total 4B)
  ; (There is a null chr. after every color.)
  loop PalLoop                       
  ret                                
endp CopyPal                        
                                    
; ------------------------------------------------
; Function  : CopyBitmap  (step 4 and last)            
; Operation : Copy Palette to video memory ports      
; ------------------------------------------------                                         
proc CopyBitmap                     
 ; BMP graphics are saved upside-down .
 ; Read the graphic line by line (200 lines in VGA format),
 ; displaying the lines from bottom to top.
  mov ax, 0A000h    ; the video memory start address (graphic mode - A000-19FFF= 64KB)               
  mov es, ax        ; Make es (Extra Segmant) point to video memory
  mov cx,200                                                         
                                                                        
PrintBMPLoop : ; loop 200 times from cx=0 till cx=199 for 200 lines                     
  push cx                           
  ; di = cx*320, point to the correct screen line
  mov di,cx  ; Make Destination index point to A000:0000 + offset)                     
  shl cx,6   ; the offset is 200*320B in first iteration, 199*320B in 2nd...                        
  shl di,8   ; We sum cx*64 (shl 6) + cx*256 (shl 8) to get cx*320.                       
  add di,cx                         
  ; Read one line                   
  mov ah,3fh  ; Read file DOS INT                      
  mov cx,320                        
  mov dx,offset ScrLine             
  int 21h                           
  ; Copy one line into video memory 
  cld ; Clear direction flag, for movsb
  mov cx,320                        
  mov si,offset ScrLine             
                                                                                                            
  rep movsb ; Copy line to the screen
            ; rep movsb is same as the following code :
            ; mov es:di, ds:si      
            ; inc si                
            ; inc di                
            ; dec cx                
  ;loop until cx=0                   
  pop cx                             
  loop PrintBMPLoop                  
  ret                                
endp CopyBitmap                     
                                    
; ------------------------------------------------
; Function  : GetMouseClick1and2              
; Operation : get user click 1 and show related pic BMP      
;             call user click 2       
; ------------------------------------------------                                               
proc GetMouseClick1and2                    
    ; --------------------------    
    ; User CLICK #1            
    ; --------------------------    
    ; Get Mouse click  <---------------------------- CLICK 1
    ;call InitMouse
    call GetMouse
    call CloseFile ; cx and dx are not changed  in "CloseFile"
	
    ; Check click
    cmp cx, 9Fh ;if cx > 159 Right
    ja Right_side
	
    ;left side
    cmp dx, 63h ;if cx > 99 Bottom    	
	ja Bottom_left

    ;Up_left                 
    mov dx, offset p_1000   ; <-- OP 1       
    call ShowBMP                
	call UL_Click_2 ; get User click 2. 
	;If match - show matched BMP (UL+BR) and set match flag (1), 
	;otherwise show initial p_0000
	ret
	
Bottom_left:	          
    mov dx, offset p_0020   ; <-- OP 2        
    call ShowBMP                
	call BL_Click_2 ; get User click 2. 
	;If match - show matched BMP (BL+UR) and set match flag (2), 
	;otherwise show initial p_0000
	ret
	
Right_side:
    cmp dx, 63h ;if cx > 99 Bottom    	
	ja Bottom_right 
	
    ;Up_right
    mov dx, offset p_0200   ; <-- OP 3        
    call ShowBMP                
	call UR_Click_2 ; get User click 2. 
	;If match - show matched BMP (UR+BL) and set match flag (2), 
	;otherwise show initial p_0000
	ret
	
Bottom_right:	
    mov dx, offset p_0001   ; <-- OP 4       
    call ShowBMP                
	call BR_Click_2 ; get User click 2. 
	;If match - show matched BMP (BR+UL) and set match flag (1), 
	;otherwise show initial p_0000
	ret
	
endp GetMouseClick1and2                    
	
; ------------------------------------------------
; Function  : UL_Click_2              
; Operation : get user click 2       
;             call either Match or No match proc
; ------------------------------------------------                                               
proc UL_Click_2                    
    ; --------------------------    
    ; User CLICK #2            
    ; --------------------------    	
    ; Get Mouse click  <---------------------------- 1. CLICK 2 UL ("p_1000" is now shown)
    ;call InitMouse
    call GetMouse
    call CloseFile ; cx and dx are not changed  in "CloseFile"
   
    ; Check click
    cmp cx, 9Fh ;if cx > 159 Right
    ja UL_C2_Right_side
	
    ;left side (must be Bottom left)	          
    mov dx, offset p_1020   ; <-- OP 1 (go to begining... )        
    call ShowBMP                
	call Show_upside_down
	ret
	
UL_C2_Right_side:
    cmp dx, 63h ;if dx > 99 Bottom    	
	ja UL_C2_Bottom_right
	
    ;UL_C2_Up_right 	
    mov dx, offset p_1200   ; <-- OP 2 (go to begining... )      
    call ShowBMP                
	call Show_upside_down
	ret
	
UL_C2_Bottom_right:	
    mov dx, offset p_1001   ; <-- OP 3       
    call ShowBMP                
	call Match_1
	ret
	
endp UL_Click_2                    

; ------------------------------------------------
; Function  : BL_Click_2              
; Operation : get user click 2       
;             call either Match or No match proc
; ------------------------------------------------                                               
proc BL_Click_2               
    ; Get Mouse click  <---------------------------- 2. CLICK 2 BL ("p_0020" is now shown)
    ;call InitMouse
    call GetMouse
    call CloseFile ; cx and dx are not changed  in "CloseFile"
    
    ; Check click
    cmp cx, 9Fh ;if cx > 159 Right
    ja BL_C2_Right_side
	
    ;left side   (must be Up left)        
    mov dx, offset p_1020   ; <-- OP 1 (go to begining... )        
    call ShowBMP                
	call Show_upside_down
	ret
	
BL_C2_Right_side:           
    cmp dx, 63h ;if dx > 99 Bottom    	
	ja BL_C2_Bottom_right
	
    ;BL_C2_Up_right	
    mov dx, offset p_0220   ; <-- OP 2        
    call ShowBMP                
	call Match_2
	ret
	
BL_C2_Bottom_right:	
    mov dx, offset p_0021   ; <-- OP 3  (go to begining... )     
    call ShowBMP                
	call Show_upside_down
	ret
	
endp BL_Click_2               

; ------------------------------------------------
; Function  : UR_Click_2              
; Operation : get user click 2       
;             call either Match or No match proc
; ------------------------------------------------                                               
proc UR_Click_2        
    ; Get Mouse click  <---------------------------- 3. CLICK 2 UR ("p_0200" is now shown)
    ;call InitMouse
    call GetMouse
    call CloseFile ; cx and dx are not changed  in "CloseFile"
    
    ; Check click
    cmp cx, 0a0h ;if cx < 160 Left
    jb UR_C2_Left_side
	
    ;right side (must be Bottom right)          
    ;mov dx, offset p_0201   ; <-- OP 1 (go to begining... )        
    call ShowBMP                
	call Show_upside_down
	ret
	
UR_C2_Left_side:           
    cmp dx, 63h ;if dx > 99 Bottom    	
	ja UR_C2_Bottom_left
	
    ;UR_C2_Up_left
    mov dx, offset p_1200   ; <-- OP 2  (go to begining... )     
    call ShowBMP                
	call Show_upside_down
	ret
	
UR_C2_Bottom_left:	
    mov dx, offset p_0220   ; <-- OP 3       
    call ShowBMP                
	call Match_2 
	ret

endp UR_Click_2        

; ------------------------------------------------
; Function  : BR_Click_2              
; Operation : get user click 2       
;             call either Match or No match proc
; ------------------------------------------------                                               
proc BR_Click_2
    ; Get Mouse click  <---------------------------- 4. CLICK 2 BR ("p_0001" is now shown)
    ;call InitMouse
    call GetMouse
    call CloseFile ; cx and dx are not changed  in "CloseFile"
   
    ; Check click
    cmp cx, 0a0h ;if cx < 160 Left
    jb BR_C2_Left_side
	
    ;right side (must be Up right)          
    mov dx, offset p_0201   ; <-- OP 1 (go to begining... )        
    call ShowBMP                
	call Show_upside_down
	ret
	
BR_C2_Left_side:           
    cmp dx, 63h ;if dx > 99 Bottom    	
	ja BR_C2_Bottom_left
	
    ;BR_C2_Up_left
    mov dx, offset p_1001   ; <-- OP 2       
    call ShowBMP                
	call Match_1 
	ret
	
BR_C2_Bottom_left:	
    mov dx, offset p_0021   ; <-- OP 3  (go to begining... )     
    call ShowBMP                
	call Show_upside_down
	ret

endp BR_Click_2

; ------------------------------------------------
; Function  : Show_upside_down              
; Operation : We have no match  
;             We show initial BMP (all turned)
; ------------------------------------------------      
proc Show_upside_down
    ;-------------------------
	; All wrong cases go here
    ;-------------------------
    call GetAnyKey ; wait for user to recall the game status and then move on
    call CloseFile 

    mov dx, offset p_0000       
    call ShowBMP                	
    ret
	
endp Show_upside_down

; ------------------------------------------------
; Function  : Match_1              
; Operation : We have a match !
;             Set match flag
; ------------------------------------------------
proc Match_1
   ; call GetAnyKey
	
    mov cx, 1 ; indication that Match 1 was found	
    ret             

endp Match_1                    

; ------------------------------------------------
; Function  : Match_2              
; Operation : We have a match !
;             Set match flag
; ------------------------------------------------
proc Match_2
    ;call GetAnyKey
	
    mov cx, 2 ; indication that Match 2 was found	
    ret             

endp Match_2                    
                                    								                                    								
; ------------------------------------------------
; Function  : Match1_GetMouseClick3and4              
; Operation : get user click 3 and 4
;             can be either UR or BL
;             (assumption: User click on turned cards only)
; ------------------------------------------------
proc Match1_GetMouseClick3and4
    ; --------------------------    
    ; User CLICK #3            
    ; --------------------------    
    ; Get Mouse click  <---------------------------- CLICK 3
    call GetMouse
    call CloseFile ; cx and dx are not changed  in "CloseFile"

    ; Check click
    cmp cx, 9Fh ;if cx > 159 Right
    ja Match_1_Right_side
	
	; Match 1 left side selected
    mov dx, offset p_1021   ; <-- OP 1  
    jmp Show_match1_click_3
	
Match_1_Right_side:
    mov dx, offset p_1201   ; <-- OP 2       

Show_match1_click_3:	
    call ShowBMP            
	call FullMatch_Click_4 ; get User click 4 and show Full matched BMP 
    ret             

endp Match1_GetMouseClick3and4    

; ------------------------------------------------
; Function  : Match2_GetMouseClick3and4              
; Operation : get user click 3 and 4
;             can be either UR or BL
;             (assumption: User click on turned cards only)
; ------------------------------------------------
proc Match2_GetMouseClick3and4
    ; --------------------------    
    ; User CLICK #3            
    ; --------------------------    
    ; Get Mouse click  <---------------------------- CLICK 3
    call GetMouse
    call CloseFile ; cx and dx are not changed  in "CloseFile"

    ; Check click
    cmp cx, 9Fh ;if cx > 159 Right
    ja Match_2_Right_side
	
	; Match 2 left side selected
    mov dx, offset p_1220   ; <-- OP 1       	
    jmp Show_match2_click_3

Match_2_Right_side:
    mov dx, offset p_0221   ; <-- OP 2       
	
Show_match2_click_3:	 
    call ShowBMP            
	call FullMatch_Click_4 ; get User click 4 and show Full matched BMP 
    ret             

endp Match2_GetMouseClick3and4    

; ------------------------------------------------
; Function  : FullMatch_Click_4              
; Operation : get user click 3 and 4
;             cat be either UR or BL
; ------------------------------------------------
proc FullMatch_Click_4
    ; --------------------------    
    ; User CLICK #4            
    ; --------------------------    
    ; Get Mouse click  <---------------------------- CLICK 4
    call GetMouse
    call CloseFile ; cx and dx are not changed  in "CloseFile"

    mov dx, offset p_1221  ; Full Match
    call ShowBMP            
    ret             

endp FullMatch_Click_4    

; ------------------------------------------------
; Function  : GameOver              
; Operation : Show "Game over" or "play again"
; ------------------------------------------------
proc GameOver
    call GetAnyKey

    mov dx, offset gmover  
    call ShowBMP            
	
	call GetMouse  ; get location: cx and dx
    call CloseFile ; Close "Game over screen" (cx and dx are unchanged)
	
    ret             

endp GameOver    

; ------------------------------------------------
; Main code Starts Here
; ------------------------------------------------                                                        
start:                                                                
    ; set data segmant register
	mov ax, @data                   
	mov ds, ax  
	
	; Graphic mode                  
    mov ax, 13h                     
    int 10h

	;init mouse (once)
    call InitMouse
	
Start_game:
    ; Show cards upside-down 
    mov dx, offset p_0000           
    call ShowBMP                
	
	; loop till we get User first two cards Match
    mov cx, 0
 First_two_clicks_loop:
    call GetMouseClick1and2
	cmp cx, 0
	je   First_two_clicks_loop 
	
	; check which Match
	cmp cx, 2
 	je   Is_Match2
	
	; ---> OP1: Cards "As" are the Match - get next card
	call  Match1_GetMouseClick3and4	
	jmp Game_is_over
	
Is_Match2:
    ; ---> OP2: Cards "2" are the Match - get next card
    call  Match2_GetMouseClick3and4       

Game_is_over:	
	call GameOver

    cmp dx, 70h ;if dx > 112 -> "TRY AGAIN" (below) is chosen	
	ja Start_game
	
   ; --------------------------    
   ; Ending..            
   ; -------------------------- 	
Back_to_text_mode:             
    mov ah, 0                       
    mov al, 2                       
    int 10h  
   
    mov si, offset thanks      
    call Print    
exit:                               
	mov ax, 4c00h                   
	int 21h                         
END start                           
  
                     
                                    
                                    
                                    
