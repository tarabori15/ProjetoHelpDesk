#include "rwmake.ch"
#include "topconn.ch"

//--------------------------------------------------------------------------------------+
//{Protheus.doc} ADV006                                                                 |
//Como Adicinar itens em uma matriz ADD                                                                  |
//@author    Celso Tarabori                                                             |
//@Version   P12                                                                        |
//@Since     23/04/2020                                                                 |
//--------------------------------------------------------------------------------------+ 

User Function ADV007()
LOCAL aMatriz := {} //Declara uma Matraiz vazia
LOCAL cMensagem := ''

//Comando ADD - adiciona um item em uma matriz 
// Sintaxe 
// ADD {<aDest>,<xExpr>}

AADD (aMatriz,"A")
AADD (aMatriz,"D")
AADD (aMatriz,"V")
AADD (aMatriz,"P")
AADD (aMatriz,"L")
cMensagem +=  CVALTOCHAR(aMatriz[1])
cMensagem +=  CVALTOCHAR(aMatriz[2])
cMensagem +=  CVALTOCHAR(aMatriz[3])
cMensagem +=  CVALTOCHAR(aMatriz[4])
cMensagem +=  CVALTOCHAR(aMatriz[5])

MSGINFO(cMensagem, "Exemplo do Array" )
   Return
Return