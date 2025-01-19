stack_segment   SEGMENT PARA STACK 'stack'
                DW 42 DUP(?)
stack_segment   ENDS

data_segment    SEGMENT PARA 'data'
CR              EQU 13
LF              EQU 10
num_elements    DW 0
array           DW 10 DUP(?)
max_count       DW 0
current_mode    DW 0
msg             DB CR, LF, '1-10 arasinda bir eleman sayisi giriniz: ', 0
HATA	        DB CR, LF, 'Dikkat !!! Sayi vermediniz yeniden giris yapiniz.!!!  ', 0
interval_error  DB CR, LF, 'Gecersiz eleman sayisi!', 0
element_msg     DB CR, LF, 'Eleman giriniz: ', 0
success_msg     DB CR, LF, 'Girilen dizinin modu: ', 0
data_segment    ENDS

code_segment    SEGMENT PARA 'code'
                ASSUME CS: code_segment, SS: stack_segment, DS: data_segment

GIRIS_DIZI      MACRO
                LOCAL ask_count, bad_interval, get_elements
                XOR SI, SI
ask_count:
                LEA AX, msg
                CALL PUT_STR
                CALL GETN
                CMP AX, 0
                JLE bad_interval
                CMP AX, 10
                JG  bad_interval
                MOV CX, AX
                MOV num_elements, AX
                JMP get_elements
bad_interval:
                LEA AX, interval_error
                CALL PUT_STR
                JMP ask_count
get_elements:
                LEA AX, element_msg
                CALL PUT_STR
                CALL GETN
                MOV array[SI], AX
                ADD SI, 2
                LOOP get_elements
                ENDM

MAIN_TASK       PROC FAR
                PUSH DS
                XOR AX, AX
                PUSH AX
                MOV AX, data_segment
                MOV DS, AX
                GIRIS_DIZI
                MOV AX, num_elements
                PUSH AX
                LEA AX, array
                PUSH AX
                CALL FIND_MODE ; Returns mode in AX
                ADD SP, 4
                PUSH AX
                LEA AX, success_msg
                CALL PUT_STR
                POP AX
                CALL PUTN
                RETF
MAIN_TASK       ENDP

; Takes address, count of array, return the mode in AX.
FIND_MODE       PROC NEAR
                PUSH BP
                MOV BP, SP

                XOR SI, SI
                MOV CX, [BP+6] ; get array count
                MOV BX, [BP+4] ; get address of array
outer_loop:
                PUSH BX
                ADD BX, SI
                MOV AX, [BX] ; get ith element
                POP BX
                XOR DI, DI ; DI = 0
                XOR DX, DX ; DX = 0 = count
inner_loop:
                PUSH BX
                ADD BX, DI
                MOV BX, [BX] ; get jth element
                CMP AX, BX ; compare ith element with jth
                POP BX
                JNZ inner_loop_exit
increment_mode_count:
                INC DX ; increment count value
inner_loop_exit:
                ADD DI, 2
                PUSH DI
                SHR DI, 1
                CMP DI, num_elements
                POP DI
                JNZ inner_loop
outer_loop_exit:
                CMP DX, max_count
                JB exit_cont
                MOV max_count, DX
                MOV current_mode, AX
exit_cont:
                ADD SI, 2
                LOOP outer_loop
                MOV AX, current_mode
                POP BP
                RET
FIND_MODE       ENDP

GETC	PROC NEAR
        ;------------------------------------------------------------------------
        ; Klavyeden basılan karakteri AL yazmacına alır ve ekranda gösterir. 
        ; işlem sonucunda sadece AL etkilenir. 
        ;------------------------------------------------------------------------
        MOV AH, 1h
        INT 21H
        RET 
GETC	ENDP 

PUTC	PROC NEAR
        ;------------------------------------------------------------------------
        ; AL yazmacındaki değeri ekranda gösterir. DL ve AH değişiyor. AX ve DX 
        ; yazmaçlarının değerleri korumak için PUSH/POP yapılır. 
        ;------------------------------------------------------------------------
        PUSH AX
        PUSH DX
        MOV DL, AL
        MOV AH,2
        INT 21H
        POP DX
        POP AX
        RET 
PUTC 	ENDP 

GETN 	PROC NEAR
        ;------------------------------------------------------------------------
        ; Klavyeden basılan sayiyi okur, sonucu AX yazmacı üzerinden dondurur. 
        ; DX: sayının işaretli olup/olmadığını belirler. 1 (+), -1 (-) demek 
        ; BL: hane bilgisini tutar 
        ; CX: okunan sayının islenmesi sırasındaki ara değeri tutar. 
        ; AL: klavyeden okunan karakteri tutar (ASCII)
        ; AX zaten dönüş değeri olarak değişmek durumundadır. Ancak diğer 
        ; yazmaçların önceki değerleri korunmalıdır. 
        ;------------------------------------------------------------------------
        PUSH BX
        PUSH CX
        PUSH DX
GETN_START:
        MOV DX, 1	                        ; sayının şimdilik + olduğunu varsayalım 
        XOR BX, BX 	                        ; okuma yapmadı Hane 0 olur. 
        XOR CX,CX	                        ; ara toplam değeri de 0’dır. 
NEW:
        CALL GETC	                        ; klavyeden ilk değeri AL’ye oku. 
        CMP AL,CR 
        JE FIN_READ	                        ; Enter tuşuna basilmiş ise okuma biter
        CMP  AL, '-'	                        ; AL ,'-' mi geldi ? 
        JNE  CTRL_NUM	                        ; gelen 0-9 arasında bir sayı mı?
NEGATIVE:
        MOV DX, -1	                        ; - basıldı ise sayı negatif, DX=-1 olur
        JMP NEW		                        ; yeni haneyi al
CTRL_NUM:
        CMP AL, '0'	                        ; sayının 0-9 arasında olduğunu kontrol et.
        JB error 
        CMP AL, '9'
        JA error		                ; değil ise HATA mesajı verilecek
        SUB AL,'0'	                        ; rakam alındı, haneyi toplama dâhil et 
        MOV BL, AL	                        ; BL’ye okunan haneyi koy 
        MOV AX, 10 	                        ; Haneyi eklerken *10 yapılacak 
        PUSH DX		                        ; MUL komutu DX’i bozar işaret için saklanmalı
        MUL CX		                        ; DX:AX = AX * CX
        POP DX		                        ; işareti geri al 
        MOV CX, AX	                        ; CX deki ara değer *10 yapıldı 
        ADD CX, BX 	                        ; okunan haneyi ara değere ekle 
        JMP NEW 		                ; klavyeden yeni basılan değeri al 
ERROR:
        MOV AX, OFFSET HATA 
        CALL PUT_STR	                        ; HATA mesajını göster 
        JMP GETN_START                          ; o ana kadar okunanları unut yeniden sayı almaya başla 
FIN_READ:
        MOV AX, CX	                        ; sonuç AX üzerinden dönecek 
        CMP DX, 1	                        ; İşarete göre sayıyı ayarlamak lazım 
        JE FIN_GETN
        NEG AX		                        ; AX = -AX
FIN_GETN:
        POP DX
        POP CX
        POP DX
        RET 
GETN 	ENDP 

PUTN 	PROC NEAR
        ;------------------------------------------------------------------------
        ; AX de bulunan sayiyi onluk tabanda hane hane yazdırır. 
        ; CX: haneleri 10’a bölerek bulacağız, CX=10 olacak
        ; DX: 32 bölmede işleme dâhil olacak. Soncu etkilemesin diye 0 olmalı 
        ;------------------------------------------------------------------------
        PUSH CX
        PUSH DX 	
        XOR DX,	DX 	                        ; DX 32 bit bölmede soncu etkilemesin diye 0 olmalı 
        PUSH DX		                        ; haneleri ASCII karakter olarak yığında saklayacağız.
                                                ; Kaç haneyi alacağımızı bilmediğimiz için yığına 0 
                                                ; değeri koyup onu alana kadar devam edelim.
        MOV CX, 10	                        ; CX = 10
        CMP AX, 0
        JGE CALC_DIGITS	
        NEG AX 		                        ; sayı negatif ise AX pozitif yapılır. 
        PUSH AX		                        ; AX sakla 
        MOV AL, '-'	                        ; işareti ekrana yazdır. 
        CALL PUTC
        POP AX		                        ; AX’i geri al 
        
CALC_DIGITS:
        DIV CX  		                ; DX:AX = AX/CX  AX = bölüm DX = kalan 
        ADD DX, '0'	                        ; kalan değerini ASCII olarak bul 
        PUSH DX		                        ; yığına sakla 
        XOR DX,DX	                        ; DX = 0
        CMP AX, 0	                        ; bölen 0 kaldı ise sayının işlenmesi bitti demek
        JNE CALC_DIGITS	                        ; işlemi tekrarla 
        
DISP_LOOP:
                                                ; yazılacak tüm haneler yığında. En anlamlı hane üstte 
                                                ; en az anlamlı hane en alta ve onu altında da 
                                                ; sona vardığımızı anlamak için konan 0 değeri var. 
        POP AX		                        ; sırayla değerleri yığından alalım
        CMP AX, 0 	                        ; AX=0 olursa sona geldik demek 
        JE END_DISP_LOOP 
        CALL PUTC 	                        ; AL deki ASCII değeri yaz
        JMP DISP_LOOP                           ; işleme devam
        
END_DISP_LOOP:
        POP DX 
        POP CX
        RET
PUTN 	ENDP 

PUT_STR	PROC NEAR
        ;------------------------------------------------------------------------
        ; AX de adresi verilen sonunda 0 olan dizgeyi karakter karakter yazdırır.
        ; BX dizgeye indis olarak kullanılır. Önceki değeri saklanmalıdır. 
        ;------------------------------------------------------------------------
	PUSH BX 
        MOV BX,	AX			        ; Adresi BX’e al 
        MOV AL, BYTE PTR [BX]	                ; AL’de ilk karakter var 
PUT_LOOP:   
        CMP AL,0		
        JE  PUT_FIN 			        ; 0 geldi ise dizge sona erdi demek
        CALL PUTC 			        ; AL’deki karakteri ekrana yazar
        INC BX 				        ; bir sonraki karaktere geç
        MOV AL, BYTE PTR [BX]
        JMP PUT_LOOP			        ; yazdırmaya devam 
PUT_FIN:
	POP BX
	RET 
PUT_STR	ENDP

code_segment    ENDS
        END MAIN_TASK