#include "rwmake.ch"
#include "topconn.ch"

//--------------------------------------------------------------------------------------+
//{Protheus.doc} ADV008                                                             |
//Como Clonar uma Matriz                                                                |
//@author    Celso Tarabori                                                             |
//@Version   P12                                                                        |
//@Since     23/04/2020                                                                 |
//--------------------------------------------------------------------------------------+ 

User Function ADV008()

LOCAL aMatriz   := {}
LOCAL aMatriz1  := {}
LOCAL aMatriz2  := {}
LOCAL cMensagem :=''
LOCAL cMensagem1 :=''

//Comando ADD - adiciona um item em uma matriz 
// Sintaxe 
// AADD ( <aDest> , <xExpr> )

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

aMatriz1 := aClone (aMatriz) //Comando para aClone

cMensagem1 +=  CVALTOCHAR(aMatriz1[1])
cMensagem1 +=  CVALTOCHAR(aMatriz1[2])
cMensagem1 +=  CVALTOCHAR(aMatriz1[3])
cMensagem1 +=  CVALTOCHAR(aMatriz1[4])
cMensagem1 +=  CVALTOCHAR(aMatriz1[5])

MSGINFO(cMensagem1, "Clone da Matriz" )
  Return
Return