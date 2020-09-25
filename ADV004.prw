#include "rwmake.ch"
#include "topconn.ch"
#include "protheus.ch"
#include "parmtype.ch"


//---------------------------------------------------------------------------------------
/*{Protheus.doc} ADV004
@Rotina para montagem de tela de chamados do Axcadastro 
@author    Celso Tarabori
@Version   P12
@Since     30/10/2019
*/
//---------------------------------------------------------------------------------------
User Function ADV004()
/*
Axcadastro("ZZD","Cadastro de chamados")
*/

    LOCAL cAlias := "ZZD"

    PRIVATE cCadastro := "Cadastro de chamados"
    PRIVATE aRotina   := { }
    Private aCores    := { }

    AADD(aRotina, { "Pesquisar"  ,"AxPesqui"   ,0,1})
    AADD(aRotina, { "Visualizar" ,"AxVisual"   ,0,2})
    AADD(aRotina, { "Incluir"    ,"AxInclui"   ,0,3})
    AADD(aRotina, { "Alterar"    ,"AxAltera"   ,0,4})
    AADD(aRotina, { "Excluir"    ,"AxDeleta"   ,0,5})
    AADD(aRotina, { "Legenda"    ,"U_ADVLEG()" ,0,6})

//Acores  - Legenda
    AADD(aCores, {"ZZD_STATU == '1'.OR. Empty (ZZD_STATU)","BR_VERDE"})//.OR. Empty (ZD->ZZD_STATUS)"
    AADD(aCores, {"ZZD_STATU == '2'","BR_AZUL"})
    AADD(aCores, {"ZZD_STATU == '3'","BR_AMARELO"})
    AADD(aCores, {"ZZD_STATU == '4'","BR_PRETO"})
    AADD(aCores, {"ZZD_STATU == '5'","BR_VERMELHO"})


    dbSelectArea(cAlias)
    dbSetOrder(1)
    mBrowse(,,,,cAlias,,,,,,aCores)
//mBrowse(6,1,22,75,cAlias)   

Return Nil

//------------------------------------------------------------------------------------------
//(Protheus.doc) ADVLEG
//@Legenda dos chamados
//@author  Celso Tarabori
//@version P12
//@since 

//------------------------------------------------------------------------------------------
Function U_ADVLEG()

    Local aLegenda		:= {}

    aAdd(aLegenda,{ 'BR_VERDE'   ,"Chamado em aberto" })
    aAdd(aLegenda,{ 'BR_AZUL'    ,"Chamado em Atendimento"})
    aAdd(aLegenda,{ 'BR_AMARELO' ,"Chamado aguardando Usuário"})
    aAdd(aLegenda,{ 'BR_PRETO'   ,"Chamado Encerrado"})
    aAdd(aLegenda,{ 'BR_VERMELHO',"Chamado em Atraso" })

    BrwLegenda(cCadastro,"Legenda",aLegenda)

Return
