//Bibliotecas
#Include "TOTVS.ch"
  
/*/{Protheus.doc} zClassTempTab
Declara a Classe vinda da FWModelEvent e os m�todos que ser�o utilizados
@author Celso Tarabori
@since 12/01/2023
@version 1.0
@see https://tdn.totvs.com/pages/releaseview.action?pageId=269552294
/*/
  
Class zClassTempTab From FWModelEvent
    Method New() CONSTRUCTOR
    Method BeforeTTS()
    Method InTTS()
    Method AfterTTS()
EndClass
  
/*/{Protheus.doc} New
M�todo para "instanciar" um observador
@author Celso Tarabori
@since 12/01/2023
@version 1.0
@param oModel, Objeto, Objeto instanciado do Modelo de Dados
/*/
  
Method New(oModel) CLASS zClassTempTab
Return
  
/*/{Protheus.doc} BeforeTTS
M�todo acionado antes de fazer as grava��es da transa��o
@author Celso Tarabori
@since 12/01/2023
@version 1.0
@param oModel, Objeto, Objeto instanciado do Modelo de Dados
/*/
  
Method BeforeTTS(oModel) Class zClassTempTab
    //Aqui voc� pode fazer as opera��es antes de gravar
Return
  
/*/{Protheus.doc} InTTS
M�todo acionado durante as grava��es da transa��o
@author Celso Tarabori
@since 12/01/2023
@version 1.0
@param oModel, Objeto, Objeto instanciado do Modelo de Dados
/*/
  
Method InTTS(oModel) Class zClassTempTab
    //Aqui voc� pode fazer as durante a grava��o (como alterar campos)
Return
  
/*/{Protheus.doc} AfterTTS
M�todo acionado ap�s as grava��es da transa��o
@author Celso Tarabori
@since 12/01/2023
@version 1.0
@param oModel, Objeto, Objeto instanciado do Modelo de Dados
/*/
  
Method AfterTTS(oModel) Class zClassTempTab
    //Aqui voc� pode fazer as opera��es ap�s gravar
    Local nOperacao := oModel:GetOperation()
    Local oModelTmp := oModel:GetModel("FORMTMP")
    Local cQryUpd   := ""
 
    //Se for inclus�o
    If nOperacao == 3
        cQryUpd += " INSERT INTO MS_FTP " + CRLF
        cQryUpd += " (MS_CLIENTE,MS_LOJA,MS_HOST,MS_PORT,MS_USER,MS_PASS,MS_AMBIENTE,D_E_L_E_T_) " + CRLF
        cQryUpd += " VALUES " + CRLF
        cQryUpd += " ('" + oModelTmp:GetValue("TMP_CLI") + "', '" + oModelTmp:GetValue("TMP_LOJA") + "', '" + oModelTmp:GetValue("TMP_HOST") + "', " + cValToChar(oModelTmp:GetValue("TMP_PORT"))  + CRLF
        cQryUpd += ",'" + oModelTmp:GetValue("TMP_USER") + "', '" + oModelTmp:GetValue("TMP_PASS") + "', '" + oModelTmp:GetValue("TMP_AMB") + "',' ' ) " + CRLF
 
    //Se for altera��o
    ElseIf nOperacao == 4
        cQryUpd += " UPDATE MS_FTP " + CRLF
        cQryUpd += " SET " + CRLF
        cQryUpd += "    MS_CLIENTE    = '" + oModelTmp:GetValue("TMP_CLI") + "', " + CRLF
        cQryUpd += "    MS_LOJA = '" + oModelTmp:GetValue("TMP_LOJA") + "', " + CRLF
        cQryUpd += "    MS_HOST  ='" + oModelTmp:GetValue("TMP_HOST") + "', " + CRLF
        cQryUpd += "    MS_PORT  = " + cValToChar(oModelTmp:GetValue("TMP_PORT")) +", " + CRLF
        cQryUpd += "    MS_USER  ='" + oModelTmp:GetValue("TMP_USER") + "', " + CRLF
        cQryUpd += "    MS_PASS  ='" + oModelTmp:GetValue("TMP_PASS") + "', " +CRLF
        cQryUpd += "    MS_AMBIENTE  = '" + oModelTmp:GetValue("TMP_AMB") + "'" + CRLF
        cQryUpd += " WHERE MS_CLIENTE = '" + oModelTmp:GetValue("TMP_CLI") + "' " + CRLF
 
    //se for exclus�o
    ElseIf nOperacao == 5
        cQryUpd += " DELETE FROM MS_FTP " + CRLF
        cQryUpd += " WHERE MS_CLIENTE = '" + oModelTmp:GetValue("TMP_CLI") + "' AND " + CRLF
        cQryUpd += "    MS_LOJA = '" + oModelTmp:GetValue("TMP_LOJA") + "'AND " + CRLF
        cQryUpd += "    MS_HOST  ='" + oModelTmp:GetValue("TMP_HOST") + "' AND " + CRLF
        cQryUpd += "    MS_PORT  = " + cValToChar(oModelTmp:GetValue("TMP_PORT")) +"AND " + CRLF
        cQryUpd += "    MS_USER  ='" + oModelTmp:GetValue("TMP_USER") + "'AND " + CRLF
        cQryUpd += "    MS_PASS  ='" + oModelTmp:GetValue("TMP_PASS") + "'AND " +CRLF
        cQryUpd += "    MS_AMBIENTE  = '" + oModelTmp:GetValue("TMP_AMB") + "'" + CRLF
        
    EndIf
 
    //Se houver query, executa atualizando a tabela direto no SQL
    If ! Empty(cQryUpd)
        u_zExecQry(cQryUpd, .T.)
    EndIf
Return
