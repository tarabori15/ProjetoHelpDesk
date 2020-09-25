#INCLUDE "PROTHEUS.CH"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )

#DEFINE CSSBOTAO	"QPushButton { color: #024670; "+;
    "    border-image: url(rpo:fwstd_btn_nml.png) 3 3 3 3 stretch; "+;
    "    border-top-width: 3px; "+;
    "    border-left-width: 3px; "+;
    "    border-right-width: 3px; "+;
    "    border-bottom-width: 3px }"+;
    "QPushButton:pressed {	color: #FFFFFF; "+;
    "    border-image: url(rpo:fwstd_btn_prd.png) 3 3 3 3 stretch; "+;
    "    border-top-width: 3px; "+;
    "    border-left-width: 3px; "+;
    "    border-right-width: 3px; "+;
    "    border-bottom-width: 3px }"

//--------------------------------------------------------------------
/*/{Protheus.doc} UPDHELP
Função de update de dicionários para compatibilização

@author TOTVS Protheus
@since  16/11/2019
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
User Function UPDHELP( cEmpAmb, cFilAmb )

    Local   aSay      := {}
    Local   aButton   := {}
    Local   aMarcadas := {}
    Local   cTitulo   := "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS"
    Local   cDesc1    := "Esta rotina tem como função fazer  a atualização  dos dicionários do Sistema ( SX?/SIX )"
    Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja não podem haver outros"
    Local   cDesc3    := "usuários  ou  jobs utilizando  o sistema.  É EXTREMAMENTE recomendavél  que  se  faça um"
    Local   cDesc4    := "BACKUP  dos DICIONÁRIOS  e da  BASE DE DADOS antes desta atualização, para que caso "
    Local   cDesc5    := "ocorram eventuais falhas, esse backup possa ser restaurado."
    Local   cDesc6    := ""
    Local   cDesc7    := ""
    Local   cMsg      := ""
    Local   lOk       := .F.
    Local   lAuto     := ( cEmpAmb <> NIL .or. cFilAmb <> NIL )

    Private oMainWnd  := NIL
    Private oProcess  := NIL

    #IFDEF TOP
        TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
    #ENDIF

    __cInterNet := NIL
    __lPYME     := .F.

    Set Dele On

// Mensagens de Tela Inicial
    aAdd( aSay, cDesc1 )
    aAdd( aSay, cDesc2 )
    aAdd( aSay, cDesc3 )
    aAdd( aSay, cDesc4 )
    aAdd( aSay, cDesc5 )
//aAdd( aSay, cDesc6 )
//aAdd( aSay, cDesc7 )

// Botoes Tela Inicial
    aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
    aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

    If lAuto
        lOk := .T.
    Else
        FormBatch(  cTitulo,  aSay,  aButton )
    EndIf

    If lOk

        If FindFunction( "MPDicInDB" ) .AND. MPDicInDB()
            cMsg := "Este update NÃO PODE ser executado neste Ambiente." + CRLF + CRLF + ;
                "Os arquivos de dicionários se encontram no Banco de Dados e este update está preparado " + ;
                "para atualizar apenas ambientes com dicionários no formato ISAM (.dbf ou .dtc)."

            If lAuto
                AutoGrLog( Replicate( "-", 128 ) )
                AutoGrLog( Replicate( " ", 128 ) )
                AutoGrLog( "LOG DA ATUALIZAÇÃO DOS DICIONÁRIOS" )
                AutoGrLog( Replicate( " ", 128 ) )
                AutoGrLog( Replicate( "-", 128 ) )
                AutoGrLog( Replicate( " ", 128 ) )
                AutoGrLog( cMsg )
                ConOut( DToC(Date()) + "|" + Time() + cMsg )
            Else
                MsgInfo( cMsg )
            EndIf

            Return NIL
        EndIf

        If lAuto
            aMarcadas :={{ cEmpAmb, cFilAmb, "" }}
        Else

            If !FWAuthAdmin()
                Final( "Atualização não Realizada." )
            EndIf

            aMarcadas := EscEmpresa()
        EndIf

        If !Empty( aMarcadas )
            If lAuto .OR. MsgNoYes( "Confirma a atualização dos dicionários ?", cTitulo )
                oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas, lAuto ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
                oProcess:Activate()

                If lAuto
                    If lOk
                        MsgStop( "Atualização Realizada.", "UPDHELP" )
                    Else
                        MsgStop( "Atualização não Realizada.", "UPDHELP" )
                    EndIf
                    dbCloseAll()
                Else
                    If lOk
                        Final( "Atualização Realizada." )
                    Else
                        Final( "Atualização não Realizada." )
                    EndIf
                EndIf

            Else
                Final( "Atualização não Realizada." )

            EndIf

        Else
            Final( "Atualização não Realizada." )

        EndIf

    EndIf

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSTProc
Função de processamento da gravação dos arquivos

@author TOTVS Protheus
@since  16/11/2019
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSTProc( lEnd, aMarcadas, lAuto )
    Local   aInfo     := {}
    Local   aRecnoSM0 := {}
    Local   cAux      := ""
    Local   cFile     := ""
    Local   cFileLog  := ""
    Local   cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
    Local   cTCBuild  := "TCGetBuild"
    Local   cTexto    := ""
    Local   cTopBuild := ""
    Local   lOpen     := .F.
    Local   lRet      := .T.
    Local   nI        := 0
    Local   nPos      := 0
    Local   nRecno    := 0
    Local   nX        := 0
    Local   oDlg      := NIL
    Local   oFont     := NIL
    Local   oMemo     := NIL

    Private aArqUpd   := {}

    If ( lOpen := MyOpenSm0(.T.) )

        dbSelectArea( "SM0" )
        dbGoTop()

        While !SM0->( EOF() )
            // Só adiciona no aRecnoSM0 se a empresa for diferente
            If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
                    .AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
                aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
            EndIf
            SM0->( dbSkip() )
        End

        SM0->( dbCloseArea() )

        If lOpen

            For nI := 1 To Len( aRecnoSM0 )

                If !( lOpen := MyOpenSm0(.F.) )
                    MsgStop( "Atualização da empresa " + aRecnoSM0[nI][2] + " não efetuada." )
                    Exit
                EndIf

                SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

                RpcSetType( 3 )
                RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

                lMsFinalAuto := .F.
                lMsHelpAuto  := .F.

                AutoGrLog( Replicate( "-", 128 ) )
                AutoGrLog( Replicate( " ", 128 ) )
                AutoGrLog( "LOG DA ATUALIZAÇÃO DOS DICIONÁRIOS" )
                AutoGrLog( Replicate( " ", 128 ) )
                AutoGrLog( Replicate( "-", 128 ) )
                AutoGrLog( " " )
                AutoGrLog( " Dados Ambiente" )
                AutoGrLog( " --------------------" )
                AutoGrLog( " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt )
                AutoGrLog( " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) )
                AutoGrLog( " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) )
                AutoGrLog( " DataBase...........: " + DtoC( dDataBase ) )
                AutoGrLog( " Data / Hora Ínicio.: " + DtoC( Date() )  + " / " + Time() )
                AutoGrLog( " Environment........: " + GetEnvServer()  )
                AutoGrLog( " StartPath..........: " + GetSrvProfString( "StartPath", "" ) )
                AutoGrLog( " RootPath...........: " + GetSrvProfString( "RootPath" , "" ) )
                AutoGrLog( " Versão.............: " + GetVersao(.T.) )
                AutoGrLog( " Usuário TOTVS .....: " + __cUserId + " " +  cUserName )
                AutoGrLog( " Computer Name......: " + GetComputerName() )

                aInfo   := GetUserInfo()
                If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
                    AutoGrLog( " " )
                    AutoGrLog( " Dados Thread" )
                    AutoGrLog( " --------------------" )
                    AutoGrLog( " Usuário da Rede....: " + aInfo[nPos][1] )
                    AutoGrLog( " Estação............: " + aInfo[nPos][2] )
                    AutoGrLog( " Programa Inicial...: " + aInfo[nPos][5] )
                    AutoGrLog( " Environment........: " + aInfo[nPos][6] )
                    AutoGrLog( " Conexão............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
                EndIf
                AutoGrLog( Replicate( "-", 128 ) )
                AutoGrLog( " " )

                If !lAuto
                    AutoGrLog( Replicate( "-", 128 ) )
                    AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )
                EndIf

                oProcess:SetRegua1( 8 )

                //------------------------------------
                // Atualiza o dicionário SX2
                //------------------------------------
                oProcess:IncRegua1( "Dicionário de arquivos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
                FSAtuSX2()

                //------------------------------------
                // Atualiza o dicionário SX3
                //------------------------------------
                FSAtuSX3()

                //------------------------------------
                // Atualiza o dicionário SIX
                //------------------------------------
                oProcess:IncRegua1( "Dicionário de índices" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
                FSAtuSIX()

                oProcess:IncRegua1( "Dicionário de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
                oProcess:IncRegua2( "Atualizando campos/índices" )

                // Alteração física dos arquivos
                __SetX31Mode( .F. )

                If FindFunction(cTCBuild)
                    cTopBuild := &cTCBuild.()
                EndIf

                For nX := 1 To Len( aArqUpd )

                    If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
                        If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
                                !aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
                            TcInternal( 25, "CLOB" )
                        EndIf
                    EndIf

                    If Select( aArqUpd[nX] ) > 0
                        dbSelectArea( aArqUpd[nX] )
                        dbCloseArea()
                    EndIf

                    X31UpdTable( aArqUpd[nX] )

                    If __GetX31Error()
                        Alert( __GetX31Trace() )
                        MsgStop( "Ocorreu um erro desconhecido durante a atualização da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicionário e da tabela.", "ATENÇÃO" )
                        AutoGrLog( "Ocorreu um erro desconhecido durante a atualização da estrutura da tabela : " + aArqUpd[nX] )
                    EndIf

                    If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
                        TcInternal( 25, "OFF" )
                    EndIf

                Next nX

                //------------------------------------
                // Atualiza o dicionário SX6
                //------------------------------------
                oProcess:IncRegua1( "Dicionário de parâmetros" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
                FSAtuSX6()

                //------------------------------------
                // Atualiza o dicionário SXB
                //------------------------------------
                oProcess:IncRegua1( "Dicionário de consultas padrão" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
                FSAtuSXB()

                //------------------------------------
                // Atualiza os helps
                //------------------------------------
                oProcess:IncRegua1( "Helps de Campo" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
                FSAtuHlp()

                AutoGrLog( Replicate( "-", 128 ) )
                AutoGrLog( " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time() )
                AutoGrLog( Replicate( "-", 128 ) )

                RpcClearEnv()

            Next nI

            If !lAuto

                cTexto := LeLog()

                Define Font oFont Name "Mono AS" Size 5, 12

                Define MsDialog oDlg Title "Atualização concluida." From 3, 0 to 340, 417 Pixel

                @ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
                oMemo:bRClicked := { || AllwaysTrue() }
                oMemo:oFont     := oFont

                Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
                Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
                    MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel

                Activate MsDialog oDlg Center

            EndIf

        EndIf

    Else

        lRet := .F.

    EndIf

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX2
Função de processamento da gravação do SX2 - Arquivos

@author TOTVS Protheus
@since  16/11/2019
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX2()
    Local aEstrut   := {}
    Local aSX2      := {}
    Local cAlias    := ""
    Local cCpoUpd   := "X2_ROTINA /X2_UNICO  /X2_DISPLAY/X2_SYSOBJ /X2_USROBJ /X2_POSLGT /"
    Local cEmpr     := ""
    Local cPath     := ""
    Local nI        := 0
    Local nJ        := 0

    AutoGrLog( "Ínicio da Atualização" + " SX2" + CRLF )

    aEstrut := { "X2_CHAVE"  , "X2_PATH"   , "X2_ARQUIVO", "X2_NOME"   , "X2_NOMESPA", "X2_NOMEENG", "X2_MODO"   , ;
        "X2_TTS"    , "X2_ROTINA" , "X2_PYME"   , "X2_UNICO"  , "X2_DISPLAY", "X2_SYSOBJ" , "X2_USROBJ" , ;
        "X2_POSLGT" , "X2_CLOB"   , "X2_AUTREC" , "X2_MODOEMP", "X2_MODOUN" , "X2_MODULO" }


    dbSelectArea( "SX2" )
    SX2->( dbSetOrder( 1 ) )
    SX2->( dbGoTop() )
    cPath := SX2->X2_PATH
    cPath := IIf( Right( AllTrim( cPath ), 1 ) <> "\", PadR( AllTrim( cPath ) + "\", Len( cPath ) ), cPath )
    cEmpr := Substr( SX2->X2_ARQUIVO, 4 )

//
// Tabela ZZA
//
    aAdd( aSX2, { ;
        'ZZA'																	, ; //X2_CHAVE
    cPath																	, ; //X2_PATH
    'ZZA'+cEmpr																, ; //X2_ARQUIVO
    'Casdastro de Tecnicos'													, ; //X2_NOME
    'Casdastro de Tecnicos'													, ; //X2_NOMESPA
    'Casdastro de Tecnicos'													, ; //X2_NOMEENG
    'E'																		, ; //X2_MODO
    ''																		, ; //X2_TTS
    ''																		, ; //X2_ROTINA
    ''																		, ; //X2_PYME
    ''																		, ; //X2_UNICO
    ''																		, ; //X2_DISPLAY
    ''																		, ; //X2_SYSOBJ
    ''																		, ; //X2_USROBJ
    ''																		, ; //X2_POSLGT
    ''																		, ; //X2_CLOB
    ''																		, ; //X2_AUTREC
    'E'																		, ; //X2_MODOEMP
    'E'																		, ; //X2_MODOUN
    0																		} ) //X2_MODULO

//
// Tabela ZZB
//
    aAdd( aSX2, { ;
        'ZZB'																	, ; //X2_CHAVE
    cPath																	, ; //X2_PATH
    'ZZB'+cEmpr																, ; //X2_ARQUIVO
    'SLA de Atendimento'													, ; //X2_NOME
    'SLA de Atendimento'													, ; //X2_NOMESPA
    'SLA de Atendimento'													, ; //X2_NOMEENG
    'E'																		, ; //X2_MODO
    ''																		, ; //X2_TTS
    ''																		, ; //X2_ROTINA
    ''																		, ; //X2_PYME
    ''																		, ; //X2_UNICO
    ''																		, ; //X2_DISPLAY
    ''																		, ; //X2_SYSOBJ
    ''																		, ; //X2_USROBJ
    ''																		, ; //X2_POSLGT
    ''																		, ; //X2_CLOB
    ''																		, ; //X2_AUTREC
    'E'																		, ; //X2_MODOEMP
    'E'																		, ; //X2_MODOUN
    0																		} ) //X2_MODULO

//
// Tabela ZZC
//
    aAdd( aSX2, { ;
        'ZZC'																	, ; //X2_CHAVE
    cPath																	, ; //X2_PATH
    'ZZC'+cEmpr																, ; //X2_ARQUIVO
    'Tipos de Chamados'														, ; //X2_NOME
    'Tipos de Chamados'														, ; //X2_NOMESPA
    'Tipos de Chamados'														, ; //X2_NOMEENG
    'E'																		, ; //X2_MODO
    ''																		, ; //X2_TTS
    ''																		, ; //X2_ROTINA
    ''																		, ; //X2_PYME
    ''																		, ; //X2_UNICO
    ''																		, ; //X2_DISPLAY
    ''																		, ; //X2_SYSOBJ
    ''																		, ; //X2_USROBJ
    ''																		, ; //X2_POSLGT
    ''																		, ; //X2_CLOB
    ''																		, ; //X2_AUTREC
    'E'																		, ; //X2_MODOEMP
    'E'																		, ; //X2_MODOUN
    0																		} ) //X2_MODULO

//
// Tabela ZZD
//
    aAdd( aSX2, { ;
        'ZZD'																	, ; //X2_CHAVE
    cPath																	, ; //X2_PATH
    'ZZD'+cEmpr																, ; //X2_ARQUIVO
    'Tabela de Chamados'													, ; //X2_NOME
    'Tabela de Chamados'													, ; //X2_NOMESPA
    'Tabela de Chamados'													, ; //X2_NOMEENG
    'E'																		, ; //X2_MODO
    ''																		, ; //X2_TTS
    ''																		, ; //X2_ROTINA
    ''																		, ; //X2_PYME
    ''																		, ; //X2_UNICO
    ''																		, ; //X2_DISPLAY
    ''																		, ; //X2_SYSOBJ
    ''																		, ; //X2_USROBJ
    ''																		, ; //X2_POSLGT
    ''																		, ; //X2_CLOB
    ''																		, ; //X2_AUTREC
    'E'																		, ; //X2_MODOEMP
    'E'																		, ; //X2_MODOUN
    0																		} ) //X2_MODULO

//
// Atualizando dicionário
//
    oProcess:SetRegua2( Len( aSX2 ) )

    dbSelectArea( "SX2" )
    dbSetOrder( 1 )

    For nI := 1 To Len( aSX2 )

        oProcess:IncRegua2( "Atualizando Arquivos (SX2)..." )

        If !SX2->( dbSeek( aSX2[nI][1] ) )

            If !( aSX2[nI][1] $ cAlias )
                cAlias += aSX2[nI][1] + "/"
                AutoGrLog( "Foi incluída a tabela " + aSX2[nI][1] )
            EndIf

            RecLock( "SX2", .T. )
            For nJ := 1 To Len( aSX2[nI] )
                If FieldPos( aEstrut[nJ] ) > 0
                    If AllTrim( aEstrut[nJ] ) == "X2_ARQUIVO"
                        FieldPut( FieldPos( aEstrut[nJ] ), SubStr( aSX2[nI][nJ], 1, 3 ) + cEmpAnt +  "0" )
                    Else
                        FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
                    EndIf
                EndIf
            Next nJ
            MsUnLock()

        Else

            If  !( StrTran( Upper( AllTrim( SX2->X2_UNICO ) ), " ", "" ) == StrTran( Upper( AllTrim( aSX2[nI][12]  ) ), " ", "" ) )
                RecLock( "SX2", .F. )
                SX2->X2_UNICO := aSX2[nI][12]
                MsUnlock()

                If MSFILE( RetSqlName( aSX2[nI][1] ),RetSqlName( aSX2[nI][1] ) + "_UNQ"  )
                    TcInternal( 60, RetSqlName( aSX2[nI][1] ) + "|" + RetSqlName( aSX2[nI][1] ) + "_UNQ" )
                EndIf

                AutoGrLog( "Foi alterada a chave única da tabela " + aSX2[nI][1] )
            EndIf

            RecLock( "SX2", .F. )
            For nJ := 1 To Len( aSX2[nI] )
                If FieldPos( aEstrut[nJ] ) > 0
                    If PadR( aEstrut[nJ], 10 ) $ cCpoUpd
                        FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
                    EndIf

                EndIf
            Next nJ
            MsUnLock()

        EndIf

    Next nI

    AutoGrLog( CRLF + "Final da Atualização" + " SX2" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX3
Função de processamento da gravação do SX3 - Campos

@author TOTVS Protheus
@since  16/11/2019
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX3()
    Local aEstrut   := {}
    Local aSX3      := {}
    Local cAlias    := ""
    Local cAliasAtu := ""
    Local cMsg      := ""
    Local cSeqAtu   := ""
    Local cX3Campo  := ""
    Local cX3Dado   := ""
    Local lTodosNao := .F.
    Local lTodosSim := .F.
    Local nI        := 0
    Local nJ        := 0
    Local nOpcA     := 0
    Local nPosArq   := 0
    Local nPosCpo   := 0
    Local nPosOrd   := 0
    Local nPosSXG   := 0
    Local nPosTam   := 0
    Local nPosVld   := 0
    Local nSeqAtu   := 0
    Local nTamSeek  := Len( SX3->X3_CAMPO )

    AutoGrLog( "Ínicio da Atualização" + " SX3" + CRLF )

    aEstrut := { { "X3_ARQUIVO", 0 }, { "X3_ORDEM"  , 0 }, { "X3_CAMPO"  , 0 }, { "X3_TIPO"   , 0 }, { "X3_TAMANHO", 0 }, { "X3_DECIMAL", 0 }, { "X3_TITULO" , 0 }, ;
        { "X3_TITSPA" , 0 }, { "X3_TITENG" , 0 }, { "X3_DESCRIC", 0 }, { "X3_DESCSPA", 0 }, { "X3_DESCENG", 0 }, { "X3_PICTURE", 0 }, { "X3_VALID"  , 0 }, ;
        { "X3_USADO"  , 0 }, { "X3_RELACAO", 0 }, { "X3_F3"     , 0 }, { "X3_NIVEL"  , 0 }, { "X3_RESERV" , 0 }, { "X3_CHECK"  , 0 }, { "X3_TRIGGER", 0 }, ;
        { "X3_PROPRI" , 0 }, { "X3_BROWSE" , 0 }, { "X3_VISUAL" , 0 }, { "X3_CONTEXT", 0 }, { "X3_OBRIGAT", 0 }, { "X3_VLDUSER", 0 }, { "X3_CBOX"   , 0 }, ;
        { "X3_CBOXSPA", 0 }, { "X3_CBOXENG", 0 }, { "X3_PICTVAR", 0 }, { "X3_WHEN"   , 0 }, { "X3_INIBRW" , 0 }, { "X3_GRPSXG" , 0 }, { "X3_FOLDER" , 0 }, ;
        { "X3_CONDSQL", 0 }, { "X3_CHKSQL" , 0 }, { "X3_IDXSRV" , 0 }, { "X3_ORTOGRA", 0 }, { "X3_TELA"   , 0 }, { "X3_POSLGT" , 0 }, { "X3_IDXFLD" , 0 }, ;
        { "X3_AGRUP"  , 0 }, { "X3_MODAL"  , 0 }, { "X3_PYME"   , 0 } }

    aEval( aEstrut, { |x| x[2] := SX3->( FieldPos( x[1] ) ) } )


//
// Campos Tabela ZZA
//
    aAdd( aSX3, { ;
        'ZZA'																	, ; //X3_ARQUIVO
    '01'																	, ; //X3_ORDEM
    'ZZA_FILIAL'															, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    2																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Filial'																, ; //X3_TITULO
    'Sucursal'																, ; //X3_TITSPA
    'Branch'																, ; //X3_TITENG
    'Filial do Sistema'														, ; //X3_DESCRIC
    'Sucursal'																, ; //X3_DESCSPA
    'Branch of the System'													, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    ''																		, ; //X3_F3
    1																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'N'																		, ; //X3_BROWSE
    ''																		, ; //X3_VISUAL
    ''																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    '033'																	, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    ''																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    ''																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZA'																	, ; //X3_ARQUIVO
    '02'																	, ; //X3_ORDEM
    'ZZA_COD'																, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    6																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Cod.Tecnicos'															, ; //X3_TITULO
    'Cod.Tecnicos'															, ; //X3_TITSPA
    'Cod.Tecnicos'															, ; //X3_TITENG
    'Cod.Tecnicos'															, ; //X3_DESCRIC
    'Cod.Tecnicos'															, ; //X3_DESCSPA
    'Cod.Tecnicos'															, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    'GETSXENUM("ZZA","ZZA_COD")'											, ; //X3_RELACAO
    ''																		, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'A'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZA'																	, ; //X3_ARQUIVO
    '03'																	, ; //X3_ORDEM
    'ZZA_NOME'																, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    30																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Nome Tec'																, ; //X3_TITULO
    'Nome Tec'																, ; //X3_TITSPA
    'Nome Tec'																, ; //X3_TITENG
    'Nome Tec'																, ; //X3_DESCRIC
    'Nome Tec'																, ; //X3_DESCSPA
    'Nome Tec'																, ; //X3_DESCENG
    '!@'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    ''																		, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'A'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZA'																	, ; //X3_ARQUIVO
    '04'																	, ; //X3_ORDEM
    'ZZA_TIPO'																, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    1																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Tipo'																	, ; //X3_TITULO
    'Tipo'																	, ; //X3_TITSPA
    'Tipo'																	, ; //X3_TITENG
    'Criticidade do chamado'												, ; //X3_DESCRIC
    'Criticidade do chamado'												, ; //X3_DESCSPA
    'Criticidade do chamado'												, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    ''																		, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'A'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    '1=Alta;2=Media;3=Baixa;4=Ambos'										, ; //X3_CBOX
    '1=Alta;2=Media;3=Baixa;4=Ambos'										, ; //X3_CBOXSPA
    '1=Alta;2=Media;3=Baixa;4=Ambos'										, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

//
// Campos Tabela ZZB
//
    aAdd( aSX3, { ;
        'ZZB'																	, ; //X3_ARQUIVO
    '01'																	, ; //X3_ORDEM
    'ZZB_FILIAL'															, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    2																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Filial'																, ; //X3_TITULO
    'Sucursal'																, ; //X3_TITSPA
    'Branch'																, ; //X3_TITENG
    'Filial do Sistema'														, ; //X3_DESCRIC
    'Sucursal'																, ; //X3_DESCSPA
    'Branch of the System'													, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    ''																		, ; //X3_F3
    1																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'N'																		, ; //X3_BROWSE
    ''																		, ; //X3_VISUAL
    ''																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    '033'																	, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    ''																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    ''																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZB'																	, ; //X3_ARQUIVO
    '02'																	, ; //X3_ORDEM
    'ZZB_COD'																, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    3																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Cod . SLA'																, ; //X3_TITULO
    'Cod . SLA'																, ; //X3_TITSPA
    'Cod . SLA'																, ; //X3_TITENG
    'Codigo do SLA'															, ; //X3_DESCRIC
    'Codigo do SLA'															, ; //X3_DESCSPA
    'Codigo do SLA'															, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    'GETSXENUM("ZZB","ZZB_COD")'											, ; //X3_RELACAO
    ''																		, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'V'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZB'																	, ; //X3_ARQUIVO
    '03'																	, ; //X3_ORDEM
    'ZZB_PRIORI'															, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    1																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Prioridade'															, ; //X3_TITULO
    'Prioridade'															, ; //X3_TITSPA
    'Prioridade'															, ; //X3_TITENG
    'Prioridade do chamado'													, ; //X3_DESCRIC
    'Prioridade do chamado'													, ; //X3_DESCSPA
    'Prioridade do chamado'													, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    ''																		, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'A'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    'A=Alta;M=Medio;B=Baixo'												, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZB'																	, ; //X3_ARQUIVO
    '04'																	, ; //X3_ORDEM
    'ZZB_DESC'																, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    30																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Descrisão'																, ; //X3_TITULO
    'Descrisão'																, ; //X3_TITSPA
    'Descrisão'																, ; //X3_TITENG
    'Descrisão do SLA'														, ; //X3_DESCRIC
    'Descrisão do SLA'														, ; //X3_DESCSPA
    'Descrisão do SLA'														, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    ''																		, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'A'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    '€'																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

//
// Campos Tabela ZZC
//
    aAdd( aSX3, { ;
        'ZZC'																	, ; //X3_ARQUIVO
    '01'																	, ; //X3_ORDEM
    'ZZC_FILIAL'															, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    2																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Filial'																, ; //X3_TITULO
    'Sucursal'																, ; //X3_TITSPA
    'Branch'																, ; //X3_TITENG
    'Filial do Sistema'														, ; //X3_DESCRIC
    'Sucursal'																, ; //X3_DESCSPA
    'Branch of the System'													, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    ''																		, ; //X3_F3
    1																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'N'																		, ; //X3_BROWSE
    ''																		, ; //X3_VISUAL
    ''																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    '033'																	, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    ''																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    ''																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZC'																	, ; //X3_ARQUIVO
    '02'																	, ; //X3_ORDEM
    'ZZC_COD'																, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    3																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Cod.tipo.Cha'															, ; //X3_TITULO
    'Cod.tipo.Cha'															, ; //X3_TITSPA
    'Cod.tipo.Cha'															, ; //X3_TITENG
    'Codigo do tipo de chamado'												, ; //X3_DESCRIC
    'Codigo do tipo de chamado'												, ; //X3_DESCSPA
    'Codigo do tipo de chamado'												, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    'GETSXENUM("ZZC","ZZC_COD")'											, ; //X3_RELACAO
    ''																		, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'V'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZC'																	, ; //X3_ARQUIVO
    '03'																	, ; //X3_ORDEM
    'ZZC_DESC'																, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    20																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Descrisao'																, ; //X3_TITULO
    'Descrisao'																, ; //X3_TITSPA
    'Descrisao'																, ; //X3_TITENG
    'Descrisao do Chamado'													, ; //X3_DESCRIC
    'Descrisao do Chamado'													, ; //X3_DESCSPA
    'Descrisao do Chamado'													, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    ''																		, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'A'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

//
// Campos Tabela ZZD
//
    aAdd( aSX3, { ;
        'ZZD'																	, ; //X3_ARQUIVO
    '01'																	, ; //X3_ORDEM
    'ZZD_FILIAL'															, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    2																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Filial'																, ; //X3_TITULO
    'Sucursal'																, ; //X3_TITSPA
    'Branch'																, ; //X3_TITENG
    'Filial do Sistema'														, ; //X3_DESCRIC
    'Sucursal'																, ; //X3_DESCSPA
    'Branch of the System'													, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    ''																		, ; //X3_F3
    1																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'N'																		, ; //X3_BROWSE
    ''																		, ; //X3_VISUAL
    ''																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    '033'																	, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    ''																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    ''																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZD'																	, ; //X3_ARQUIVO
    '02'																	, ; //X3_ORDEM
    'ZZD_COD'																, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    6																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Cod Chamado'															, ; //X3_TITULO
    'Cod Chamado'															, ; //X3_TITSPA
    'Cod Chamado'															, ; //X3_TITENG
    'Codigo do Chamado'														, ; //X3_DESCRIC
    'Codigo do Chamado'														, ; //X3_DESCSPA
    'Codigo do Chamado'														, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    'GETSXENUM("ZZD","ZZD_COD")'											, ; //X3_RELACAO
    ''																		, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'V'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZD'																	, ; //X3_ARQUIVO
    '03'																	, ; //X3_ORDEM
    'ZZD_DATA'																, ; //X3_CAMPO
    'D'																		, ; //X3_TIPO
    8																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Dt.Chamado'															, ; //X3_TITULO
    'Dt.Chamado'															, ; //X3_TITSPA
    'Dt.Chamado'															, ; //X3_TITENG
    'Data do Chamado'														, ; //X3_DESCRIC
    'Data do Chamado'														, ; //X3_DESCSPA
    'Data do Chamado'														, ; //X3_DESCENG
    ''																		, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    ' DDATABASE'															, ; //X3_RELACAO
    ''																		, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'V'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZD'																	, ; //X3_ARQUIVO
    '04'																	, ; //X3_ORDEM
    'ZZD_TIPO'																, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    3																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Tp. Chamado'															, ; //X3_TITULO
    'Tp. Chamado'															, ; //X3_TITSPA
    'Tp. Chamado'															, ; //X3_TITENG
    'Tipo do chamado'														, ; //X3_DESCRIC
    'Tipo do chamado'														, ; //X3_DESCSPA
    'Tipo do chamado'														, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    'ZZCCOD'																, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'A'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    '€'																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZD'																	, ; //X3_ARQUIVO
    '05'																	, ; //X3_ORDEM
    'ZZD_TECNIC'															, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    6																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Tecnico Resp'															, ; //X3_TITULO
    'Tecnico Resp'															, ; //X3_TITSPA
    'Tecnico Resp'															, ; //X3_TITENG
    'Tecnico Responsavel'													, ; //X3_DESCRIC
    'Tecnico Responsavel'													, ; //X3_DESCSPA
    'Tecnico Responsavel'													, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    'ZZACOD'																, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'A'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    '€'																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZD'																	, ; //X3_ARQUIVO
    '06'																	, ; //X3_ORDEM
    'ZZD_DTRESO'															, ; //X3_CAMPO
    'D'																		, ; //X3_TIPO
    8																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Dt.Resolucao'															, ; //X3_TITULO
    'Dt.Resolucao'															, ; //X3_TITSPA
    'Dt.Resolucao'															, ; //X3_TITENG
    'Data da Resoluçao'														, ; //X3_DESCRIC
    'Data da Resoluçao'														, ; //X3_DESCSPA
    'Data da Resoluçao'														, ; //X3_DESCENG
    ''																		, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    ''																		, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'A'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZD'																	, ; //X3_ARQUIVO
    '07'																	, ; //X3_ORDEM
    'ZZD_PRIORI'															, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    1																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Prioridade'															, ; //X3_TITULO
    'Prioridade'															, ; //X3_TITSPA
    'Prioridade'															, ; //X3_TITENG
    'Prioridade do Chamado'													, ; //X3_DESCRIC
    'Prioridade do Chamado'													, ; //X3_DESCSPA
    'Prioridade do Chamado'													, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    'ZZBPRI'																, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'A'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    ''																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZD'																	, ; //X3_ARQUIVO
    '09'																	, ; //X3_ORDEM
    'ZZD_PROB'																, ; //X3_CAMPO
    'M'																		, ; //X3_TIPO
    10																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Problema'																, ; //X3_TITULO
    'Problema'																, ; //X3_TITSPA
    'Problema'																, ; //X3_TITENG
    'Problema'																, ; //X3_DESCRIC
    'Problema'																, ; //X3_DESCSPA
    'Problema'																, ; //X3_DESCENG
    ''																		, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    ''																		, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'A'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    '€'																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZD'																	, ; //X3_ARQUIVO
    '10'																	, ; //X3_ORDEM
    'ZZD_RESOL'																, ; //X3_CAMPO
    'M'																		, ; //X3_TIPO
    10																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Solucao'																, ; //X3_TITULO
    'Solucao'																, ; //X3_TITSPA
    'Solucao'																, ; //X3_TITENG
    'Solucao do Chamado'													, ; //X3_DESCRIC
    'Solucao do Chamado'													, ; //X3_DESCSPA
    'Solucao do Chamado'													, ; //X3_DESCENG
    ''																		, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    ''																		, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'A'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    '€'																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME

    aAdd( aSX3, { ;
        'ZZD'																	, ; //X3_ARQUIVO
    '11'																	, ; //X3_ORDEM
    'ZZD_STATUS'															, ; //X3_CAMPO
    'C'																		, ; //X3_TIPO
    1																		, ; //X3_TAMANHO
    0																		, ; //X3_DECIMAL
    'Status'																, ; //X3_TITULO
    'Status'																, ; //X3_TITSPA
    'Status'																, ; //X3_TITENG
    'Status do Chamado'														, ; //X3_DESCRIC
    'Status do Chamado'														, ; //X3_DESCSPA
    'Status do Chamado'														, ; //X3_DESCENG
    '@!'																	, ; //X3_PICTURE
    ''																		, ; //X3_VALID
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
        Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
    ''																		, ; //X3_RELACAO
    ''																		, ; //X3_F3
    0																		, ; //X3_NIVEL
    Chr(254) + Chr(192)														, ; //X3_RESERV
    ''																		, ; //X3_CHECK
    ''																		, ; //X3_TRIGGER
    'U'																		, ; //X3_PROPRI
    'S'																		, ; //X3_BROWSE
    'A'																		, ; //X3_VISUAL
    'R'																		, ; //X3_CONTEXT
    '€'																		, ; //X3_OBRIGAT
    ''																		, ; //X3_VLDUSER
    ''																		, ; //X3_CBOX
    ''																		, ; //X3_CBOXSPA
    ''																		, ; //X3_CBOXENG
    ''																		, ; //X3_PICTVAR
    ''																		, ; //X3_WHEN
    ''																		, ; //X3_INIBRW
    ''																		, ; //X3_GRPSXG
    ''																		, ; //X3_FOLDER
    ''																		, ; //X3_CONDSQL
    ''																		, ; //X3_CHKSQL
    ''																		, ; //X3_IDXSRV
    'N'																		, ; //X3_ORTOGRA
    ''																		, ; //X3_TELA
    ''																		, ; //X3_POSLGT
    'N'																		, ; //X3_IDXFLD
    ''																		, ; //X3_AGRUP
    ''																		, ; //X3_MODAL
    ''																		} ) //X3_PYME


//
// Atualizando dicionário
//
    nPosArq := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ARQUIVO" } )
    nPosOrd := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ORDEM"   } )
    nPosCpo := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_CAMPO"   } )
    nPosTam := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_TAMANHO" } )
    nPosSXG := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_GRPSXG"  } )
    nPosVld := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_VALID"   } )

    aSort( aSX3,,, { |x,y| x[nPosArq]+x[nPosOrd]+x[nPosCpo] < y[nPosArq]+y[nPosOrd]+y[nPosCpo] } )

    oProcess:SetRegua2( Len( aSX3 ) )

    dbSelectArea( "SX3" )
    dbSetOrder( 2 )
    cAliasAtu := ""

    For nI := 1 To Len( aSX3 )

        //
        // Verifica se o campo faz parte de um grupo e ajusta tamanho
        //
        If !Empty( aSX3[nI][nPosSXG] )
            SXG->( dbSetOrder( 1 ) )
            If SXG->( MSSeek( aSX3[nI][nPosSXG] ) )
                If aSX3[nI][nPosTam] <> SXG->XG_SIZE
                    aSX3[nI][nPosTam] := SXG->XG_SIZE
                    AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo] + " NÃO atualizado e foi mantido em [" + ;
                        AllTrim( Str( SXG->XG_SIZE ) ) + "]" + CRLF + ;
                        " por pertencer ao grupo de campos [" + SXG->XG_GRUPO + "]" + CRLF )
                EndIf
            EndIf
        EndIf

        SX3->( dbSetOrder( 2 ) )

        If !( aSX3[nI][nPosArq] $ cAlias )
            cAlias += aSX3[nI][nPosArq] + "/"
            aAdd( aArqUpd, aSX3[nI][nPosArq] )
        EndIf

        If !SX3->( dbSeek( PadR( aSX3[nI][nPosCpo], nTamSeek ) ) )

            //
            // Busca ultima ocorrencia do alias
            //
            If ( aSX3[nI][nPosArq] <> cAliasAtu )
                cSeqAtu   := "00"
                cAliasAtu := aSX3[nI][nPosArq]

                dbSetOrder( 1 )
                SX3->( dbSeek( cAliasAtu + "ZZ", .T. ) )
                dbSkip( -1 )

                If ( SX3->X3_ARQUIVO == cAliasAtu )
                    cSeqAtu := SX3->X3_ORDEM
                EndIf

                nSeqAtu := Val( RetAsc( cSeqAtu, 3, .F. ) )
            EndIf

            nSeqAtu++
            cSeqAtu := RetAsc( Str( nSeqAtu ), 2, .T. )

            RecLock( "SX3", .T. )
            For nJ := 1 To Len( aSX3[nI] )
                If     nJ == nPosOrd  // Ordem
                    SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), cSeqAtu ) )

                ElseIf aEstrut[nJ][2] > 0
                    SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ] ) )

                EndIf
            Next nJ

            dbCommit()
            MsUnLock()

            AutoGrLog( "Criado campo " + aSX3[nI][nPosCpo] )

        EndIf

        oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3)..." )

    Next nI

    AutoGrLog( CRLF + "Final da Atualização" + " SX3" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSIX
Função de processamento da gravação do SIX - Indices

@author TOTVS Protheus
@since  16/11/2019
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSIX()
    Local aEstrut   := {}
    Local aSIX      := {}
    Local lAlt      := .F.
    Local lDelInd   := .F.
    Local nI        := 0
    Local nJ        := 0

    AutoGrLog( "Ínicio da Atualização" + " SIX" + CRLF )

    aEstrut := { "INDICE" , "ORDEM" , "CHAVE", "DESCRICAO", "DESCSPA"  , ;
        "DESCENG", "PROPRI", "F3"   , "NICKNAME" , "SHOWPESQ" }

//
// Tabela ZZA
//
    aAdd( aSIX, { ;
        'ZZA'																	, ; //INDICE
    '1'																		, ; //ORDEM
    'ZZA_FILIAL+ZZA_COD+ZZA_NOME+ZZA_TIPO'									, ; //CHAVE
    'Cod.Tecnicos+Nome Tec+Tipo'											, ; //DESCRICAO
    'Cod.Tecnicos+Nome Tec+Tipo'											, ; //DESCSPA
    'Cod.Tecnicos+Nome Tec+Tipo'											, ; //DESCENG
    'U'																		, ; //PROPRI
    ''																		, ; //F3
    'ZZACOD'																, ; //NICKNAME
    'S'																		} ) //SHOWPESQ

//
// Tabela ZZB
//
    aAdd( aSIX, { ;
        'ZZB'																	, ; //INDICE
    '1'																		, ; //ORDEM
    'ZZB_FILIAL+ZZB_COD+ZZB_PRIORI+ZZB_DESC'								, ; //CHAVE
    'Cod . SLA+Prioridade+Descrisão'										, ; //DESCRICAO
    'Cod . SLA+Prioridade+Descrisão'										, ; //DESCSPA
    'Cod . SLA+Prioridade+Descrisão'										, ; //DESCENG
    'U'																		, ; //PROPRI
    ''																		, ; //F3
    'SLAZZB'																, ; //NICKNAME
    'S'																		} ) //SHOWPESQ

//
// Tabela ZZC
//
    aAdd( aSIX, { ;
        'ZZC'																	, ; //INDICE
    '1'																		, ; //ORDEM
    'ZZC_FILIAL+ZZC_COD+ZZC_DESC'											, ; //CHAVE
    'Cod.tipo.Cha+Descrisao'												, ; //DESCRICAO
    'Cod.tipo.Cha+Descrisao'												, ; //DESCSPA
    'Cod.tipo.Cha+Descrisao'												, ; //DESCENG
    'U'																		, ; //PROPRI
    ''																		, ; //F3
    'TIPO'																	, ; //NICKNAME
    'N'																		} ) //SHOWPESQ

//
// Tabela ZZD
//
    aAdd( aSIX, { ;
        'ZZD'																	, ; //INDICE
    '1'																		, ; //ORDEM
    'ZZD_FILIAL+ZZD_COD+ZZD_DATA+ZZD_TIPO+ZZD_TECNIC+ZZD_DTRESO+ZZD_PRIORI'		, ; //CHAVE
    'Cod Chamado+Dt.Chamado+Tp. Chamado+Tecnico Resp+Dt.Resolucao+Prioridad'	, ; //DESCRICAO
    'Cod Chamado+Dt.Chamado+Tp. Chamado+Tecnico Resp+Dt.Resolucao+Prioridad'	, ; //DESCSPA
    'Cod Chamado+Dt.Chamado+Tp. Chamado+Tecnico Resp+Dt.Resolucao+Prioridad'	, ; //DESCENG
    'U'																		, ; //PROPRI
    ''																		, ; //F3
    ''																		, ; //NICKNAME
    'N'																		} ) //SHOWPESQ

//
// Atualizando dicionário
//
    oProcess:SetRegua2( Len( aSIX ) )

    dbSelectArea( "SIX" )
    SIX->( dbSetOrder( 1 ) )

    For nI := 1 To Len( aSIX )

        lAlt    := .F.
        lDelInd := .F.

        If !SIX->( dbSeek( aSIX[nI][1] + aSIX[nI][2] ) )
            AutoGrLog( "Índice criado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
        Else
            lAlt := .T.
            aAdd( aArqUpd, aSIX[nI][1] )
            If !StrTran( Upper( AllTrim( CHAVE )       ), " ", "" ) == ;
                    StrTran( Upper( AllTrim( aSIX[nI][3] ) ), " ", "" )
                AutoGrLog( "Chave do índice alterado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
                lDelInd := .T. // Se for alteração precisa apagar o indice do banco
            EndIf
        EndIf

        RecLock( "SIX", !lAlt )
        For nJ := 1 To Len( aSIX[nI] )
            If FieldPos( aEstrut[nJ] ) > 0
                FieldPut( FieldPos( aEstrut[nJ] ), aSIX[nI][nJ] )
            EndIf
        Next nJ
        MsUnLock()

        dbCommit()

        If lDelInd
            TcInternal( 60, RetSqlName( aSIX[nI][1] ) + "|" + RetSqlName( aSIX[nI][1] ) + aSIX[nI][2] )
        EndIf

        oProcess:IncRegua2( "Atualizando índices..." )

    Next nI

    AutoGrLog( CRLF + "Final da Atualização" + " SIX" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX6
Função de processamento da gravação do SX6 - Parâmetros

@author TOTVS Protheus
@since  16/11/2019
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX6()
    Local aEstrut   := {}
    Local aSX6      := {}
    Local cAlias    := ""
    Local cMsg      := ""
    Local lContinua := .T.
    Local lReclock  := .T.
    Local lTodosNao := .F.
    Local lTodosSim := .F.
    Local nI        := 0
    Local nJ        := 0
    Local nOpcA     := 0
    Local nTamFil   := Len( SX6->X6_FIL )
    Local nTamVar   := Len( SX6->X6_VAR )

    AutoGrLog( "Ínicio da Atualização" + " SX6" + CRLF )

    aEstrut := { "X6_FIL"    , "X6_VAR"    , "X6_TIPO"   , "X6_DESCRIC", "X6_DSCSPA" , "X6_DSCENG" , "X6_DESC1"  , ;
        "X6_DSCSPA1", "X6_DSCENG1", "X6_DESC2"  , "X6_DSCSPA2", "X6_DSCENG2", "X6_CONTEUD", "X6_CONTSPA", ;
        "X6_CONTENG", "X6_PROPRI" , "X6_VALID"  , "X6_INIT"   , "X6_DEFPOR" , "X6_DEFSPA" , "X6_DEFENG" , ;
        "X6_PYME"   }

    aAdd( aSX6, { ;
        '  '																	, ; //X6_FIL
    'FS_GCTCOT'																, ; //X6_VAR
    'C'																		, ; //X6_TIPO
    'Tipo Contrato para cotacao'											, ; //X6_DESCRIC
    'Tipo Contrato para cotizacion'											, ; //X6_DSCSPA
    'Contract type for quotation'											, ; //X6_DSCENG
    ''																		, ; //X6_DESC1
    ''																		, ; //X6_DSCSPA1
    ''																		, ; //X6_DSCENG1
    ''																		, ; //X6_DESC2
    ''																		, ; //X6_DSCSPA2
    ''																		, ; //X6_DSCENG2
    '001'																	, ; //X6_CONTEUD
    '001'																	, ; //X6_CONTSPA
    '001'																	, ; //X6_CONTENG
    'S'																		, ; //X6_PROPRI
    ''																		, ; //X6_VALID
    ''																		, ; //X6_INIT
    '001'																	, ; //X6_DEFPOR
    '001'																	, ; //X6_DEFSPA
    '001'																	, ; //X6_DEFENG
    'S'																		} ) //X6_PYME

//
// Atualizando dicionário
//
    oProcess:SetRegua2( Len( aSX6 ) )

    dbSelectArea( "SX6" )
    dbSetOrder( 1 )

    For nI := 1 To Len( aSX6 )
        lContinua := .F.
        lReclock  := .F.

        If !SX6->( dbSeek( PadR( aSX6[nI][1], nTamFil ) + PadR( aSX6[nI][2], nTamVar ) ) )
            lContinua := .T.
            lReclock  := .T.
            AutoGrLog( "Foi incluído o parâmetro " + aSX6[nI][1] + aSX6[nI][2] + " Conteúdo [" + AllTrim( aSX6[nI][13] ) + "]" )
        EndIf

        If lContinua
            If !( aSX6[nI][1] $ cAlias )
                cAlias += aSX6[nI][1] + "/"
            EndIf

            RecLock( "SX6", lReclock )
            For nJ := 1 To Len( aSX6[nI] )
                If FieldPos( aEstrut[nJ] ) > 0
                    FieldPut( FieldPos( aEstrut[nJ] ), aSX6[nI][nJ] )
                EndIf
            Next nJ
            dbCommit()
            MsUnLock()
        EndIf

        oProcess:IncRegua2( "Atualizando Arquivos (SX6)..." )

    Next nI

    AutoGrLog( CRLF + "Final da Atualização" + " SX6" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSXB
Função de processamento da gravação do SXB - Consultas Padrao

@author TOTVS Protheus
@since  16/11/2019
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function 12()
    Local aEstrut   := {}
    Local aSXB      := {}
    Local cAlias    := ""
    Local cMsg      := ""
    Local lTodosNao := .F.
    Local lTodosSim := .F.
    Local nI        := 0
    Local nJ        := 0
    Local nOpcA     := 0

    AutoGrLog( "Ínicio da Atualização" + " SXB" + CRLF )

    aEstrut := { "XB_ALIAS"  , "XB_TIPO"   , "XB_SEQ"    , "XB_COLUNA" , "XB_DESCRI" , "XB_DESCSPA", "XB_DESCENG", ;
        "XB_WCONTEM", "XB_CONTEM" }


//
// Consulta ZZACOD
//
    aAdd( aSXB, { ;
        'ZZACOD'																, ; //XB_ALIAS
    '1'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    'DB'																	, ; //XB_COLUNA
    'ZZACOD-Zzacod'															, ; //XB_DESCRI
    'ZZACOD-Zzacod'															, ; //XB_DESCSPA
    'ZZACOD-Zzacod'															, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'ZZA'																	} ) //XB_CONTEM

    aAdd( aSXB, { ;
        'ZZACOD'																, ; //XB_ALIAS
    '2'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    '01'																	, ; //XB_COLUNA
    'Cod.tecnicos+nome Te'													, ; //XB_DESCRI
    'Cod.tecnicos+nome Te'													, ; //XB_DESCSPA
    'Cod.tecnicos+nome Te'													, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'CODNOME'																} ) //XB_CONTEM

    aAdd( aSXB, { ;
        'ZZACOD'																, ; //XB_ALIAS
    '4'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    '01'																	, ; //XB_COLUNA
    'Cod.Tecnicos'															, ; //XB_DESCRI
    'Cod.Tecnicos'															, ; //XB_DESCSPA
    'Cod.Tecnicos'															, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'ZZA_COD'																} ) //XB_CONTEM

    aAdd( aSXB, { ;
        'ZZACOD'																, ; //XB_ALIAS
    '4'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    '02'																	, ; //XB_COLUNA
    'Nome Tec'																, ; //XB_DESCRI
    'Nome Tec'																, ; //XB_DESCSPA
    'Nome Tec'																, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'ZZA_NOME'																} ) //XB_CONTEM

    aAdd( aSXB, { ;
        'ZZACOD'																, ; //XB_ALIAS
    '5'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    ''																		, ; //XB_COLUNA
    ''																		, ; //XB_DESCRI
    ''																		, ; //XB_DESCSPA
    ''																		, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'ZZA->ZZA_COD'															} ) //XB_CONTEM

//
// Consulta ZZBPRI
//
    aAdd( aSXB, { ;
        'ZZBPRI'																, ; //XB_ALIAS
    '1'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    'DB'																	, ; //XB_COLUNA
    'ZZBPRIORI'																, ; //XB_DESCRI
    'ZZBPRIORI'																, ; //XB_DESCSPA
    'ZZBPRIORI'																, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'ZZB'																	} ) //XB_CONTEM

    aAdd( aSXB, { ;
        'ZZBPRI'																, ; //XB_ALIAS
    '2'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    '01'																	, ; //XB_COLUNA
    'Cod . Sla+prioridade'													, ; //XB_DESCRI
    'Cod . Sla+prioridade'													, ; //XB_DESCSPA
    'Cod . Sla+prioridade'													, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'SLAZZB'																} ) //XB_CONTEM

    aAdd( aSXB, { ;
        'ZZBPRI'																, ; //XB_ALIAS
    '4'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    '01'																	, ; //XB_COLUNA
    'Cod . SLA'																, ; //XB_DESCRI
    'Cod . SLA'																, ; //XB_DESCSPA
    'Cod . SLA'																, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'ZZB_COD'																} ) //XB_CONTEM

    aAdd( aSXB, { ;
        'ZZBPRI'																, ; //XB_ALIAS
    '4'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    '02'																	, ; //XB_COLUNA
    'Prioridade'															, ; //XB_DESCRI
    'Prioridade'															, ; //XB_DESCSPA
    'Prioridade'															, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'ZZB_PRIORI'															} ) //XB_CONTEM

    aAdd( aSXB, { ;
        'ZZBPRI'																, ; //XB_ALIAS
    '5'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    ''																		, ; //XB_COLUNA
    ''																		, ; //XB_DESCRI
    ''																		, ; //XB_DESCSPA
    ''																		, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'ZZB->ZZB_PRIORI'														} ) //XB_CONTEM

//
// Consulta ZZCCOD
//
    aAdd( aSXB, { ;
        'ZZCCOD'																, ; //XB_ALIAS
    '1'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    'DB'																	, ; //XB_COLUNA
    'ZZCCOD'																, ; //XB_DESCRI
    'ZZCCOD'																, ; //XB_DESCSPA
    'ZZCCOD'																, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'ZZC'																	} ) //XB_CONTEM

    aAdd( aSXB, { ;
        'ZZCCOD'																, ; //XB_ALIAS
    '2'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    '01'																	, ; //XB_COLUNA
    'Cod.tipo.cha+descris'													, ; //XB_DESCRI
    'Cod.tipo.cha+descris'													, ; //XB_DESCSPA
    'Cod.tipo.cha+descris'													, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'TIPO'																	} ) //XB_CONTEM

    aAdd( aSXB, { ;
        'ZZCCOD'																, ; //XB_ALIAS
    '4'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    '01'																	, ; //XB_COLUNA
    'Cod.tipo.Cha'															, ; //XB_DESCRI
    'Cod.tipo.Cha'															, ; //XB_DESCSPA
    'Cod.tipo.Cha'															, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'ZZC_COD'																} ) //XB_CONTEM

    aAdd( aSXB, { ;
        'ZZCCOD'																, ; //XB_ALIAS
    '4'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    '02'																	, ; //XB_COLUNA
    'Descrisao'																, ; //XB_DESCRI
    'Descrisao'																, ; //XB_DESCSPA
    'Descrisao'																, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'ZZC_DESC'																} ) //XB_CONTEM

    aAdd( aSXB, { ;
        'ZZCCOD'																, ; //XB_ALIAS
    '5'																		, ; //XB_TIPO
    '01'																	, ; //XB_SEQ
    ''																		, ; //XB_COLUNA
    ''																		, ; //XB_DESCRI
    ''																		, ; //XB_DESCSPA
    ''																		, ; //XB_DESCENG
    ''																		, ; //XB_WCONTEM
    'ZZC->ZZC_COD'															} ) //XB_CONTEM

//
// Atualizando dicionário
//
    oProcess:SetRegua2( Len( aSXB ) )

    dbSelectArea( "SXB" )
    dbSetOrder( 1 )

    For nI := 1 To Len( aSXB )

        If !Empty( aSXB[nI][1] )

            If !SXB->( dbSeek( PadR( aSXB[nI][1], Len( SXB->XB_ALIAS ) ) + aSXB[nI][2] + aSXB[nI][3] + aSXB[nI][4] ) )

                If !( aSXB[nI][1] $ cAlias )
                    cAlias += aSXB[nI][1] + "/"
                    AutoGrLog( "Foi incluída a consulta padrão " + aSXB[nI][1] )
                EndIf

                RecLock( "SXB", .T. )

                For nJ := 1 To Len( aSXB[nI] )
                    If FieldPos( aEstrut[nJ] ) > 0
                        FieldPut( FieldPos( aEstrut[nJ] ), aSXB[nI][nJ] )
                    EndIf
                Next nJ

                dbCommit()
                MsUnLock()

            Else

                //
                // Verifica todos os campos
                //
                For nJ := 1 To Len( aSXB[nI] )

                    //
                    // Se o campo estiver diferente da estrutura
                    //
                    If aEstrut[nJ] == SXB->( FieldName( nJ ) ) .AND. ;
                            !StrTran( AllToChar( SXB->( FieldGet( nJ ) ) ), " ", "" ) == ;
                            StrTran( AllToChar( aSXB[nI][nJ]            ), " ", "" )

                        cMsg := "A consulta padrão " + aSXB[nI][1] + " está com o " + SXB->( FieldName( nJ ) ) + ;
                            " com o conteúdo" + CRLF + ;
                            "[" + RTrim( AllToChar( SXB->( FieldGet( nJ ) ) ) ) + "]" + CRLF + ;
                            ", e este é diferente do conteúdo" + CRLF + ;
                            "[" + RTrim( AllToChar( aSXB[nI][nJ] ) ) + "]" + CRLF +;
                            "Deseja substituir ? "

                        If      lTodosSim
                            nOpcA := 1
                        ElseIf  lTodosNao
                            nOpcA := 2
                        Else
                            nOpcA := Aviso( "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS", cMsg, { "Sim", "Não", "Sim p/Todos", "Não p/Todos" }, 3, "Diferença de conteúdo - SXB" )
                            lTodosSim := ( nOpcA == 3 )
                            lTodosNao := ( nOpcA == 4 )

                            If lTodosSim
                                nOpcA := 1
                                lTodosSim := MsgNoYes( "Foi selecionada a opção de REALIZAR TODAS alterações no SXB e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma a ação [Sim p/Todos] ?" )
                            EndIf

                            If lTodosNao
                                nOpcA := 2
                                lTodosNao := MsgNoYes( "Foi selecionada a opção de NÃO REALIZAR nenhuma alteração no SXB que esteja diferente da base e NÃO MOSTRAR mais a tela de aviso." + CRLF + "Confirma esta ação [Não p/Todos]?" )
                            EndIf

                        EndIf

                        If nOpcA == 1
                            RecLock( "SXB", .F. )
                            FieldPut( FieldPos( aEstrut[nJ] ), aSXB[nI][nJ] )
                            dbCommit()
                            MsUnLock()

                            If !( aSXB[nI][1] $ cAlias )
                                cAlias += aSXB[nI][1] + "/"
                                AutoGrLog( "Foi alterada a consulta padrão " + aSXB[nI][1] )
                            EndIf

                        EndIf

                    EndIf

                Next

            EndIf

        EndIf

        oProcess:IncRegua2( "Atualizando Consultas Padrões (SXB)..." )

    Next nI

    AutoGrLog( CRLF + "Final da Atualização" + " SXB" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuHlp
Função de processamento da gravação dos Helps de Campos

@author TOTVS Protheus
@since  16/11/2019
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuHlp()
    Local aHlpPor   := {}
    Local aHlpEng   := {}
    Local aHlpSpa   := {}

    AutoGrLog( "Ínicio da Atualização" + " " + "Helps de Campos" + CRLF )


    oProcess:IncRegua2( "Atualizando Helps de Campos ..." )

//
// Helps Tabela ZZA
//
    aHlpPor := {}
    aAdd( aHlpPor, 'Codigo dos Tecnicos' )
    aHlpEng := {}
    aHlpSpa := {}

    PutHelp( "PZZA_COD   ", aHlpPor, aHlpEng, aHlpSpa, .T. )
    AutoGrLog( "Atualizado o Help do campo " + "ZZA_COD" )

    aHlpPor := {}
    aAdd( aHlpPor, 'Nome do Tecnico' )
    aHlpEng := {}
    aHlpSpa := {}

    PutHelp( "PZZA_NOME  ", aHlpPor, aHlpEng, aHlpSpa, .T. )
    AutoGrLog( "Atualizado o Help do campo " + "ZZA_NOME" )

    aHlpPor := {}
    aAdd( aHlpPor, 'Criticidade do chamado' )
    aHlpEng := {}
    aHlpSpa := {}

    PutHelp( "PZZA_TIPO  ", aHlpPor, aHlpEng, aHlpSpa, .T. )
    AutoGrLog( "Atualizado o Help do campo " + "ZZA_TIPO" )

//
// Helps Tabela ZZB
//
    aHlpPor := {}
    aAdd( aHlpPor, 'Informe a descrisão do SLA' )
    aHlpEng := {}
    aHlpSpa := {}

    PutHelp( "PZZB_DESC  ", aHlpPor, aHlpEng, aHlpSpa, .T. )
    AutoGrLog( "Atualizado o Help do campo " + "ZZB_DESC" )

//
// Helps Tabela ZZC
//
//
// Helps Tabela ZZD
//
    aHlpPor := {}
    aAdd( aHlpPor, 'Tipo do chamado' )
    aHlpEng := {}
    aHlpSpa := {}

    PutHelp( "PZZD_TIPO  ", aHlpPor, aHlpEng, aHlpSpa, .T. )
    AutoGrLog( "Atualizado o Help do campo " + "ZZD_TIPO" )

    aHlpPor := {}
    aAdd( aHlpPor, 'Data da Resoluçao' )
    aHlpEng := {}
    aHlpSpa := {}

    PutHelp( "PZZD_DTRESO", aHlpPor, aHlpEng, aHlpSpa, .T. )
    AutoGrLog( "Atualizado o Help do campo " + "ZZD_DTRESO" )

    aHlpPor := {}
    aAdd( aHlpPor, 'Prioridade do Chamado' )
    aHlpEng := {}
    aHlpSpa := {}

    PutHelp( "PZZD_PRIORI", aHlpPor, aHlpEng, aHlpSpa, .T. )
    AutoGrLog( "Atualizado o Help do campo " + "ZZD_PRIORI" )

    aHlpPor := {}
    aAdd( aHlpPor, 'Problema' )
    aHlpEng := {}
    aHlpSpa := {}

    PutHelp( "PZZD_PROB  ", aHlpPor, aHlpEng, aHlpSpa, .T. )
    AutoGrLog( "Atualizado o Help do campo " + "ZZD_PROB" )

    aHlpPor := {}
    aAdd( aHlpPor, 'Status do Chamado' )
    aHlpEng := {}
    aHlpSpa := {}

    PutHelp( "PZZD_STATUS", aHlpPor, aHlpEng, aHlpSpa, .T. )
    AutoGrLog( "Atualizado o Help do campo " + "ZZD_STATUS" )

    AutoGrLog( CRLF + "Final da Atualização" + " " + "Helps de Campos" + CRLF + Replicate( "-", 128 ) + CRLF )

Return {}


//--------------------------------------------------------------------
/*/{Protheus.doc} EscEmpresa
Função genérica para escolha de Empresa, montada pelo SM0

@return aRet Vetor contendo as seleções feitas.
             Se não for marcada nenhuma o vetor volta vazio

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function EscEmpresa()

//---------------------------------------------
// Parâmetro  nTipo
// 1 - Monta com Todas Empresas/Filiais
// 2 - Monta só com Empresas
// 3 - Monta só com Filiais de uma Empresa
//
// Parâmetro  aMarcadas
// Vetor com Empresas/Filiais pré marcadas
//
// Parâmetro  cEmpSel
// Empresa que será usada para montar seleção
//---------------------------------------------
    Local   aRet      := {}
    Local   aSalvAmb  := GetArea()
    Local   aSalvSM0  := {}
    Local   aVetor    := {}
    Local   cMascEmp  := "??"
    Local   cVar      := ""
    Local   lChk      := .F.
    Local   lOk       := .F.
    Local   lTeveMarc := .F.
    Local   oNo       := LoadBitmap( GetResources(), "LBNO" )
    Local   oOk       := LoadBitmap( GetResources(), "LBOK" )
    Local   oDlg, oChkMar, oLbx, oMascEmp, oSay
    Local   oButDMar, oButInv, oButMarc, oButOk, oButCanc

    Local   aMarcadas := {}


    If !MyOpenSm0(.F.)
        Return aRet
    EndIf


    dbSelectArea( "SM0" )
    aSalvSM0 := SM0->( GetArea() )
    dbSetOrder( 1 )
    dbGoTop()

    While !SM0->( EOF() )

        If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
            aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
        EndIf

        dbSkip()
    End

    RestArea( aSalvSM0 )

    Define MSDialog  oDlg Title "" From 0, 0 To 280, 395 Pixel

    oDlg:cToolTip := "Tela para Múltiplas Seleções de Empresas/Filiais"

    oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualização"

    @ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
    oLbx:SetArray(  aVetor )
    oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
        aVetor[oLbx:nAt, 2], ;
        aVetor[oLbx:nAt, 4]}}
    oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
    oLbx:cToolTip   :=  oDlg:cTitle
    oLbx:lHScroll   := .F. // NoScroll

    @ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos" Message "Marca / Desmarca"+ CRLF + "Todos" Size 40, 007 Pixel Of oDlg;
        on Click MarcaTodos( lChk, @aVetor, oLbx )

// Marca/Desmarca por mascara
    @ 113, 51 Say   oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
    @ 112, 80 MSGet oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
        Message "Máscara Empresa ( ?? )"  Of oDlg
    oSay:cToolTip := oMascEmp:cToolTip

    @ 128, 10 Button oButInv    Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx, @lChk, oChkMar ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
        Message "Inverter Seleção" Of oDlg
    oButInv:SetCss( CSSBOTAO )
    @ 128, 50 Button oButMarc   Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
        Message "Marcar usando" + CRLF + "máscara ( ?? )"    Of oDlg
    oButMarc:SetCss( CSSBOTAO )
    @ 128, 80 Button oButDMar   Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
        Message "Desmarcar usando" + CRLF + "máscara ( ?? )" Of oDlg
    oButDMar:SetCss( CSSBOTAO )
    @ 112, 157  Button oButOk   Prompt "Processar"  Size 32, 12 Pixel Action (  RetSelecao( @aRet, aVetor ), IIf( Len( aRet ) > 0, oDlg:End(), MsgStop( "Ao menos um grupo deve ser selecionado", "UPDHELP" ) ) ) ;
        Message "Confirma a seleção e efetua" + CRLF + "o processamento" Of oDlg
    oButOk:SetCss( CSSBOTAO )
    @ 128, 157  Button oButCanc Prompt "Cancelar"   Size 32, 12 Pixel Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) ;
        Message "Cancela o processamento" + CRLF + "e abandona a aplicação" Of oDlg
    oButCanc:SetCss( CSSBOTAO )

    Activate MSDialog  oDlg Center

    RestArea( aSalvAmb )
    dbSelectArea( "SM0" )
    dbCloseArea()

Return  aRet


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaTodos
Função auxiliar para marcar/desmarcar todos os ítens do ListBox ativo

@param lMarca  Contéudo para marca .T./.F.
@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaTodos( lMarca, aVetor, oLbx )
    Local  nI := 0

    For nI := 1 To Len( aVetor )
        aVetor[nI][1] := lMarca
    Next nI

    oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} InvSelecao
Função auxiliar para inverter a seleção do ListBox ativo

@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function InvSelecao( aVetor, oLbx )
    Local  nI := 0

    For nI := 1 To Len( aVetor )
        aVetor[nI][1] := !aVetor[nI][1]
    Next nI

    oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} RetSelecao
Função auxiliar que monta o retorno com as seleções

@param aRet    Array que terá o retorno das seleções (é alterado internamente)
@param aVetor  Vetor do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function RetSelecao( aRet, aVetor )
    Local  nI    := 0

    aRet := {}
    For nI := 1 To Len( aVetor )
        If aVetor[nI][1]
            aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } )
        EndIf
    Next nI

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaMas
Função para marcar/desmarcar usando máscaras

@param oLbx     Objeto do ListBox
@param aVetor   Vetor do ListBox
@param cMascEmp Campo com a máscara (???)
@param lMarDes  Marca a ser atribuída .T./.F.

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )
    Local cPos1 := SubStr( cMascEmp, 1, 1 )
    Local cPos2 := SubStr( cMascEmp, 2, 1 )
    Local nPos  := oLbx:nAt
    Local nZ    := 0

    For nZ := 1 To Len( aVetor )
        If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
            If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
                aVetor[nZ][1] := lMarDes
            EndIf
        EndIf
    Next

    oLbx:nAt := nPos
    oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} VerTodos
Função auxiliar para verificar se estão todos marcados ou não

@param aVetor   Vetor do ListBox
@param lChk     Marca do CheckBox do marca todos (referncia)
@param oChkMar  Objeto de CheckBox do marca todos

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function VerTodos( aVetor, lChk, oChkMar )
    Local lTTrue := .T.
    Local nI     := 0

    For nI := 1 To Len( aVetor )
        lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
    Next nI

    lChk := IIf( lTTrue, .T., .F. )
    oChkMar:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MyOpenSM0
Função de processamento abertura do SM0 modo exclusivo

@author TOTVS Protheus
@since  16/11/2019
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MyOpenSM0(lShared)
    Local lOpen := .F.
    Local nLoop := 0

    If FindFunction( "OpenSM0Excl" )
        For nLoop := 1 To 20
            If OpenSM0Excl(,.F.)
                lOpen := .T.
                Exit
            EndIf
            Sleep( 500 )
        Next nLoop
    Else
        For nLoop := 1 To 20
            dbUseArea( .T., , "SIGAMAT.EMP", "SM0", lShared, .F. )

            If !Empty( Select( "SM0" ) )
                lOpen := .T.
                dbSetIndex( "SIGAMAT.IND" )
                Exit
            EndIf
            Sleep( 500 )
        Next nLoop
    EndIf

    If !lOpen
        MsgStop( "Não foi possível a abertura da tabela " + ;
            IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), "ATENÇÃO" )
    EndIf

Return lOpen


//--------------------------------------------------------------------
/*/{Protheus.doc} LeLog
Função de leitura do LOG gerado com limitacao de string

@author TOTVS Protheus
@since  16/11/2019
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function LeLog()
    Local cRet  := ""
    Local cFile := NomeAutoLog()
    Local cAux  := ""

    FT_FUSE( cFile )
    FT_FGOTOP()

    While !FT_FEOF()

        cAux := FT_FREADLN()

        If Len( cRet ) + Len( cAux ) < 1048000
            cRet += cAux + CRLF
        Else
            cRet += CRLF
            cRet += Replicate( "=" , 128 ) + CRLF
            cRet += "Tamanho de exibição maxima do LOG alcançado." + CRLF
            cRet += "LOG Completo no arquivo " + cFile + CRLF
            cRet += Replicate( "=" , 128 ) + CRLF
            Exit
        EndIf

        FT_FSKIP()
    End

    FT_FUSE()

Return cRet


/////////////////////////////////////////////////////////////////////////////
