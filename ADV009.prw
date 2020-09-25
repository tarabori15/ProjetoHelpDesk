#include "protheus.ch"
#INCLUDE "rwmake.ch"
#INCLUDE "topconn.ch"

//--------------------------------------------------------------------------------------+
//{Protheus.doc} ADV009                                                                 |
//Como clonar uma matriz - aScan.                                                       |
//@author    Celso Tarabori                                                             |
//@Version   P12                                                                        |
//@Since     23/04/2020                                                                 |
//--------------------------------------------------------------------------------------+ 

User Function ADV009()
LOCAL aMatriz :={} //Declara uma matriz vazia
LOCAL aLetras :={} // Matriz para gravar a quantidade por letra
LOCAL x := 0

//Comando ADD - adiciona um item em uma matriz 
// Sintaxe 
// ADD {<aDest>,<xExpr>}

AADD(aMatriz ,"A" )
AADD(aMatriz ,"D" )
AADD(aMatriz ,"V" )
AADD(aMatriz ,"P" )
AADD(aMatriz ,"L" )
AADD(aMatriz ,"S" )
AADD(aMatriz ,"E" )
AADD(aMatriz ,"M" )
AADD(aMatriz ,"C" )
AADD(aMatriz ,"O" )
AADD(aMatriz ,"M" )
AADD(aMatriz ,"P" )
AADD(aMatriz ,"L" )
AADD(aMatriz ,"I" )
AADD(aMatriz ,"C" )
AADD(aMatriz ,"A" )
AADD(aMatriz ,"C" )
AADD(aMatriz ,"A" )
AADD(aMatriz ,"O" )

//contar a quantidade por letras
For x:= 1 to len(aMatriz)
	//verifica se letra já existe e soma a quantidade
	If aScan( aLetras, { |z| z[2] == aMatriz[x] } ) == 0
		AADD(aLetras,{1,aMatriz[x]}) 
	Else
		nPos:= aScan( aLetras, { |z| z[2] == aMatriz[x] } )
		aLetras[nPos][1]+= 1    
	Endif
 
Next x
Return