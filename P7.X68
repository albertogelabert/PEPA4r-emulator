*-----------------------------------------------------------
* Title      : PRAFIN15
* Written by : Alberto Gelabert Mena
* Date       : 24/05/2015
* Description: Emulador de la PEPA4r
*-----------------------------------------------------------

        ORG $1000
EPROG:  DC.W $0700, $020F, $0606, $0C0B, $020E, $0605, $0C0B, $0418, $050D
        DC.W $0C0B, $0E07, $0601, $0010, $0F00, $0008, $0004, $0000
EIR:    DC.W 0 ;eregistre d'instruccio
EPC:    DC.W 0 ;ecomptador de programa
ER0:    DC.W 0 ;eregistre R0
ER1:    DC.W 0 ;eregistre R1
ER2:    DC.W 0 ;eregistre R2
ER3:    DC.W 0 ;eregistre R3
ESR:    DC.W 0 ;eregistre d'estat (00000000 00000ZNC)
    
FETCH:
        MOVE.W EPC,D0
        MULU #2,D0
        MOVE.W D0,A0 
        MOVE.W EPROG(A0),EIR
        MOVE.W EIR,D1
        ADD #1,EPC
        SUB #2,SP       //RESERVAMOS ESPACIO PARA RTDO (W)
        MOVE.W EIR,-(SP)
        JSR DESCO       
        ADD #2,SP       //ELIMINAMOS EIR(D0) DE LA PILA
        MOVE (SP)+,D1   //RECUPERAMOS RTDO
        MULU #6,D1      //JMP OCUPA 6B, POR ESO MULT. POR 6
        MOVEA.L D1,A1
        JMP JMPLIST(A1)
        
JMPLIST:
        JMP ESTO
        JMP ELOA
        JMP ECMP
        JMP EADD
        JMP ESUB
        JMP ENAN
        JMP EADQ        
        JMP ETRA
        JMP ESET
        JMP EJMZ
        JMP EJMN
        JMP EJMI
        JMP EHLT
        
EHLT:
        SIMHALT
     
EJMI:
        MOVE.W EIR,D0
        AND #$00FF,D0       //M
        MOVE D0,EPC
        JMP FETCH
        
EJMZ:
        MOVE ESR,D1
        BTST #2,D1          //miramos Z
        BEQ FETCH           //z=0 no hacemos nada
        MOVE.W EIR,D0       //z=1
        AND.W #$00FF,D0     //M
        MOVE D0,EPC
        JMP FETCH

EJMN:
        MOVE ESR,D1
        BTST #1,D1          //miramos N
        BEQ FETCH           //N=0
        MOVE.W EIR,D0       //N=1
        AND.W #$00FF,D0     //M
        MOVE.W D0,EPC
        JMP FETCH
        
ESTO:
        MOVE.W EIR,D0
        AND.W #$00FF,D0     //M
        MULU #2,D0          //x2, en 68k va de 2 en 2
        MOVE.W D0,A0
        MOVE.W ER1,EPROG(A0) //M<-[R1]
        JMP FETCH   
        
ELOA:
        MOVE.W EIR,D0
        AND.W #$00FF,D0     //M
        MULU #2,D0
        MOVE.W D0,A0 
        MOVE.W EPROG(A0),ER1 //R1<-[M]        
        JMP FETCH   
        
                
        
      ******************* SET ****************  
ESET:
        MOVE.W EIR,D0
        AND #$00FC,D0       //CCCCCC
        LSR #2,D0 
        MOVE.W EIR,D1
        AND  #$0003,D1      //aa
        CMP #3,D1
        BEQ SETaR3
        CMP #2,D1
        BEQ SETaR2
        CMP #1,D1
        BEQ SETaR1
        MOVE.W D0,ER0       //Ra<-CCCCCC
        AND #$3F,ER0
        JMP FETCH      
    SETaR3:
            MOVE.W D0,ER3   //Ra<-CCCCCC
            AND #$3F,ER3
            JMP FETCH
    SETaR2:
            MOVE.W D0,ER2   //Ra<-CCCCCC
            AND #$3F,ER2
            JMP FETCH
    SETaR1:
            MOVE.W D0,ER1   //Ra<-CCCCCC
            AND #$3F,ER1
            JMP FETCH

    ********************* TRA ***********************
ETRA:
        MOVE EIR,D0    
        MOVE EIR,D1         
        AND #$3,D1      //bb
        AND #$C,D0      //aa
        LSR #2,D0
        CMP #3,D0       //MIRO CUAL ES EL REG. ORIGEN 
        BEQ TRAR3       
        CMP #2,D0
        BEQ TRAR2
        CMP #1,D0
        BEQ TRAR1
        MOVE.W ER0,D0
MIRARBB:        
        CMP #3,D1       //MIRO CUAL ES EL REG. DEST
        BEQ TRAR3B      
        CMP #2,D1
        BEQ TRAR2B
        CMP #1,D1
        BEQ TRAR1B
        MOVE.W D0,ER0
        JSR FLAGZ
        JSR FLAGN
        JMP FETCH
      
TRAR3:
        MOVE.W ER3,D0       //ya tengo el dato del reg. origen
        JMP MIRARBB
TRAR2:
        MOVE.W ER2,D0
        JMP MIRARBB
TRAR1:
        MOVE.W ER1,D0
        JMP MIRARBB
TRAR3B:
        MOVE.W D0,ER3       // meto [Reg origen] en el destino
        JMP FLAGSTRA
TRAR2B:
        MOVE.W D0,ER2
        JMP FLAGSTRA
TRAR1B:
        MOVE.W D0,ER1
FLAGSTRA:
        JSR FLAGZ
        JSR FLAGN
        JMP FETCH
        
    ******************** CMP *************************
ECMP:
        MOVE EIR,D0
        AND #$C,D0      //aa
        LSR #2,D0       //MUEVO 2 POS. A LA DCHA. PARA TENER EL VALOR
        CMP #3,D0
        BEQ CMPR3
        CMP #2,D0
        BEQ CMPR2
        CMP #1,D0
        BEQ CMPR1
        MOVE.W ER0,D0
        JMP DOCMP
        CMPR3:
            MOVE.W ER3,D0
            JMP DOCMP
        CMPR2: 
            MOVE.W ER2,D0
            JMP DOCMP
        CMPR1:
            MOVE.W ER1,D0
DOCMP:  
        NEG D0          //-[Ra]
        ADD ER0,D0      //ERO+(-[Ra])
        JSR FLAGZ
        JSR FLAGN
        JSR FLAGC
        JMP FETCH
    
    ********************** ADQ ************************
EADQ:
        MOVE.W EIR,D0
        AND #$C,D0          //dd
        LSR #2,D0           //MUEVO 2 POS. DCHA. PARA TENER EL VALOR
        BTST #0,D0          
        BEQ MIRARBIT1
        BNE MIRARBIT1B
    MIRARBIT1B:
            BTST #1,D0
            BNE ADDQMENOS1
            BEQ ADDQ1
    MIRARBIT1:
            BTST #1,D0
            BEQ ADDQ0
            BNE ADDQMENOS2
    ADDQMENOS1:
            MOVE.W #-1,D0   //VALOR DE dd
            JMP SEGUIRADQ
    ADDQMENOS2:
            MOVE.W #-2,D0   //VALOR DE dd
            JMP SEGUIRADQ
    ADDQ1:
            MOVE.W #1,D0    //VALOR DE dd
            JMP SEGUIRADQ
    ADDQ0:
            MOVE.W #0,D0    //VALOR DE dd
        SEGUIRADQ:
                MOVE.W EIR,D1
                AND #$3,D1  //bb
                CMP #3,D1   //MIRAMOS QUE REGISTRO
                BEQ ADQR3
                CMP #2,D1
                BEQ ADQR2
                CMP #1,D1
                BEQ ADQR1
                MOVE.W ER0,D1
                JMP HACERADQ
    
        ADQR3:
                MOVE.W ER3,D1
                JMP HACERADQ
        ADQR2:
                MOVE.W ER2,D1
                JMP HACERADQ
        ADQR1:
                MOVE.W ER1,D1
HACERADQ:
        ADD.W D1,D0
        MOVE.W D0,ER1
        JSR FLAGZ
        JSR FLAGN
        JSR FLAGC
        AND #$0FFF,ER1  //LIMPIAMOS 4 BITS + SIGN.
        JMP FETCH
        
    ************************ ADD *******************************
EADD:
        MOVE.W EIR,D0
        AND #$C,D0          
        LSR #2,D0        //2 POS. A LA DCHA. PARA TENER EL VALOR
        CMP #3,D0
        BEQ ADDR3
        CMP #2,D0
        BEQ ADDR2
        CMP #1,D0
        BEQ ADDR1
        MOVE.W ER0,D1
        JMP SEGUIRADD
    ADDR3:
            MOVE.W ER3,D1
            JMP SEGUIRADD
    ADDR2:
            MOVE.W ER2,D1
            JMP SEGUIRADD
    ADDR1:
            MOVE.W ER1,D1
SEGUIRADD:
        MOVE.W ER0,D0
        ADD.W D1,D0
        JSR FLAGZ
        JSR FLAGN
        JSR FLAGC
        AND #$0FFF,D0   //LIMPIAMOS 4 BITS + SIGN.
        MOVE.W D0,ER0
        JMP FETCH
        
**************************** SUB **********************************
ESUB:
        MOVE.W EIR,D0
        AND #$C,D0
        LSR #2,D0       //MUEVO 2 POS. DCHA. PARA TENER EL VALOR
        CMP #3,D0
        BEQ SUBR3
        CMP #2,D0
        BEQ SUBR2
        CMP #1,D0
        BEQ SUBR1
        MOVE.W ER0,D1
        JMP SEGUIRSUB
    SUBR3:
            MOVE.W ER3,D1
           JMP SEGUIRSUB
    SUBR2:
            MOVE.W ER2,D1
            JMP SEGUIRSUB
    SUBR1:
            MOVE.W ER1,D1       
SEGUIRSUB:
        MOVE.W ER0,D0
        NEG D1          //-[Ra]
        ADD.W D1,D0     //R0+(-[Ra])
        JSR FLAGZ
        JSR FLAGN
        JSR FLAGC
        AND #$0FFF,D0   //LIMPIAMOS 4 BITS + SIGN.
        MOVE.W D0,ER0
        JMP FETCH
        
**************************** NAN **********************************
ENAN:
        MOVE.W EIR,D0
        AND #$C,D0      //aa
        LSR #2,D0       //MUEVO 2 POS. DCHA. PARA TENER EL VALOR
        CMP #3,D0
        BEQ NANR3
        CMP #2,D0
        BEQ NANR2
        CMP #1,D0
        BEQ NANR1
        MOVE.W D0,D1
        JMP SEGUIRNAN
    NANR3:
            MOVE.W ER3,D1
            JMP SEGUIRNAN
    NANR2:
            MOVE.W ER2,D1
            JMP SEGUIRNAN
    NANR1:
            MOVE.W ER1,D1
SEGUIRNAN:
        MOVE.W ER0,D0
        AND #$0FFF,D1   //LIMPIAMOS 4 BITS +SIGNIFICATIVOS
        AND D1,D0       //NAND-> AND Y NOT
        NOT D0
        JSR FLAGZ
        JSR FLAGN
        AND #$0FFF,D0   //LIMPIAMOS 4 BITS + SIGN.
        MOVE.W D0,ER0
        JMP FETCH
        
        
              
*******************************************************************
**************************** FLAGS ********************************
*******************************************************************

********************* FLAGZ *******************************        

FLAGZ:
        MOVE.L D0,-(SP)     
        MOVE.L D1,-(SP)
        MOVE.W ESR,D1
        MOVE.W 6(SP),D0
        
            AND #$0FFF,D0
            CMP #0,D0           //FLAG Z, SI D0=0, Z SE PONE A 1
            BNE PONERZ0
            BSET #2,D1
            JMP ENGFLAGZ
PONERZ0:    BCLR #2,D1
ENGFLAGZ:        
        MOVE.W D1,ESR
        MOVE.L (SP)+,D1
        MOVE.L (SP)+,D0
        RTS
        
********************* FLAGN *******************************        

FLAGN:
        MOVE.L D0,-(SP)     
        MOVE.L D1,-(SP)
        MOVE.W ESR,D1
        MOVE.W 6(SP),D0
        
            BTST #11,D0         
            BEQ PONERFLAGN0
            BSET #1,D1          ////bit 11=1 -> numero es negativo
            JMP ENDFLAGN
PONERFLAGN0:
            BCLR #1,D1
ENDFLAGN: 
        MOVE.W D1,ESR
        MOVE.L (SP)+,D1
        MOVE.L (SP)+,D0
        RTS

********************* FLAGC *******************************        
FLAGC:
        MOVE.L D0,-(SP)     
        MOVE.L D1,-(SP)
        MOVE.W ESR,D1
        MOVE.W 6(SP),D0
        
            BTST #12,D0
            BEQ PONERFLAGC0
            BTST #13,D0
            BNE PONERFLAGC0
            BSET #0,D1
            JMP ENDFLAGC
PONERFLAGC0:
            BCLR #0,D1
ENDFLAGC:
        MOVE.W D1,ESR
        MOVE.L (SP)+,D1
        MOVE.L (SP)+,D0
        RTS
 
    
*************************************************
******************* DESCO ***********************
*************************************************
DESCO:
        MOVE.L D0,-(SP)
        MOVE.W 8(SP),D0               
        BTST #11,D0
        BNE B11ES1
        BEQ B11ES0
        
B11ES1:
        BTST #9,D0
        BNE B9ES1
        BEQ B9ES0
        
B9ES1:
        BTST #8,D0
        BNE HLT
        BEQ JMI

B9ES0:
        BTST #8,D0
        BNE JMN
        BEQ JMZ
        
B11ES0:
        BTST #10,D0
        BEQ B10ES0B
        BNE B10ES1B
        
B10ES1B:
        BTST #9,D0
        BNE B9ES1B
        BEQ B9ES0B
        
B9ES0B:
        BTST #8,D0
        BNE ADQ
        BEQ B8ES0B
        
B8ES0B:
        BTST #5,D0
        BNE B5ES1
        BEQ ADD
        
B5ES1:
        BTST #4,D0
        BNE NAN
        BEQ SUB
        
B5ES0:
        BTST #4,D0
        BNE ADD
        BEQ CMP
        
B9ES1B:
        BTST #8,D0
        BNE SET
        BEQ TRA
        
B10ES0B:
        BTST #9,D0
        BNE LOA
        BEQ STO
        
STO:
        MOVE.W #0,D0
        JMP JUMPTOSR
LOA:
        MOVE.W #1,D0
        JMP JUMPTOSR
CMP:
        MOVE.W #2,D0
        JMP JUMPTOSR
ADD:
        MOVE.W #3,D0
        JMP JUMPTOSR
SUB:
        MOVE.W #4,D0
        JMP JUMPTOSR
NAN:
        MOVE.W #5,D0
        JMP JUMPTOSR
ADQ:
        MOVE.W #6,D0
        JMP JUMPTOSR
TRA:
        MOVE.W #7,D0
        JMP JUMPTOSR
SET:
        MOVE.W #8,D0
        JMP JUMPTOSR
JMZ:
        MOVE.W #9,D0
        JMP JUMPTOSR
JMN: 
        MOVE.W #10,D0
        JMP JUMPTOSR
JMI:
        MOVE.W #11,D0
        JMP JUMPTOSR
HLT:
        MOVE.W #12,D0
        JMP JUMPTOSR
       
JUMPTOSR:
        MOVE.W D0,10(SP)
        MOVE.L (SP)+,D0     //RECUPERAR VALOR REGISTROS USADOS
        RTS

    SIMHALT             ; halt simulator


    END    FETCH        ; last line of source
















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
