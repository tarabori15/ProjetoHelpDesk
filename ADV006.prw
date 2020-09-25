#include "rwmake.ch"
#include "topconn.ch"

//--------------------------------------------------------------------------------------+
//{Protheus.doc} ADV006                                                                 |
//Exemplos de Arrays                                                                    |
//@author    Celso Tarabori                                                             |
//@Version   P12                                                                        |
//@Since     23/04/2020                                                                 |
//--------------------------------------------------------------------------------------+ 
User Function ADV006()

LOCAL aExemplo  := NIL
LOCAL cMensagem :=''

//+--------------------------------------------------------------------------------------
//|Exemplifica o uso da função array                                                    |
//+--------------------------------------------------------------------------------------
aExemplo := {7,7}
aExemplo[1] := ("E","A","S","U","I","H","F")
aExemplo[2] := ("Ç","X","D","F","B","N","X")
aExemplo[3] := ("D","P","E","G","G","H","B")
aExemplo[4] := ("N","A","K","M","R","E","H")
aExemplo[5] := ("R","H","Z","T","P","T","Y")
aExemplo[6] := ("K","X","A","K","J","L","U")
aExemplo[7] := ("M","S","C","V","P","O","O")
cMensagem += CVALTOCHAR(aExemplo[1][1]) 
cMensagem += CVALTOCHAR(aExemplo[2][2]) 
cMensagem += CVALTOCHAR(aExemplo[3][3]) 
cMensagem += CVALTOCHAR(aExemplo[4][4]) 
cMensagem += CVALTOCHAR(aExemplo[5][5]) 
cMensagem += CVALTOCHAR(aExemplo[6][6]) 
cMensagem += CVALTOCHAR(aExemplo[7][7]) 

//+--------------------------------------------------------------------------------------
//|Apresenta uma mensagem com os resultados obtidos                                     |
//+--------------------------------------------------------------------------------------

MSGINFO( cMensagem, "Exemplo do Array" )
  Return
Return