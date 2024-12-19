//Bibliotecas
#Include "Totvs.ch"
#Include "FWMVCDef.ch"

//Variveis Estaticas
Static cTitulo := ""

/*/{Protheus.doc} User Function SYVAR01
Cadastro dos FTP dos clientes tabela (MS_FTP_VAR)
@author Celso Tarabori
@since 12/01/2024
@version 1.0
/*/

User Function SYVAR01()
	Local aArea   := FWGetArea()
	Local oBrowse
	Local aCampos := {}
	Local aColunas := {}
	Local aPesquisa := {}
	Local cQryUpd := ""
	Local cTRealName := ""
	Private aRotina := {}
	Private cAliasTmp := GetNextAlias()
	Private oTempTable

	//Definicao do menu
	aRotina := MenuDef()

	//Campos da temporária
	aAdd(aCampos, {"TMP_CLI"     , "C", 006, 0})
	aAdd(aCampos, {"TMP_LOJA   " , "C", 002, 0})
	aAdd(aCampos, {"TMP_AMB"     , "C", 025, 0})
	aAdd(aCampos, {"MS_VAR  "    , "C", 025, 0})
	aAdd(aCampos, {"MS_VALOR"    , "C", 200, 0})

	

	//Cria a temporária
	oTempTable := FWTemporaryTable():New(cAliasTmp)
	oTempTable:SetFields(aCampos)
	oTempTable:AddIndex("1", {"TMP_CLI"} )
	oTempTable:Create()
	cTRealName := oTempTable:GetRealName()
	cTitulo := " Armazenamento (MS_FTP_VAR) - " + cTRealName

	//Agora vamos inserir os dados na temporária conforme os que existem no banco de dados
	cQryUpd := ""
	cQryUpd += " INSERT INTO " + cTRealName + CRLF
	cQryUpd += " (TMP_CLI, TMP_LOJA,TMP_AMB,MS_VAR,MS_VALOR) " + CRLF
	cQryUpd += " SELECT  MS_CLIENTE,MS_LOJA,MS_AMBIENTE,MS_VAR,MS_VALOR FROM MS_FTP_VAR"
	u_zExecQry(cQryUpd, .T.)

	//Definindo as colunas que serão usadas no browse
	aAdd(aColunas, {"Cliente"  ,   "TMP_CLI"     , "C", 006, 0, ""})
	aAdd(aColunas, {"Loja"     ,   "TMP_LOJA"    , "C", 002, 0, ""})
	aAdd(aColunas, {"Ambiente" ,   "TMP_AMB"     , "C", 025, 0, ""})
	aAdd(aColunas, {"var"      ,   "MS_VAR  "    , "C", 025, 0, ""})
	aAdd(aColunas, {"Valor"    ,   "MS_VALOR"    , "C", 200, 0, ""})
	
	


	//Adiciona os indices para pesquisar
    /*
        [n,1] Título da pesquisa
        [n,2,n,1] LookUp
        [n,2,n,2] Tipo de dados
        [n,2,n,3] Tamanho
        [n,2,n,4] Decimal
        [n,2,n,5] Título do campo
        [n,2,n,6] Máscara
        [n,2,n,7] Nome Físico do campo - Opcional - é ajustado no programa
        [n,3] Ordem da pesquisa
        [n,4] Exibe na pesquisa
    */
	aAdd(aPesquisa, {"Cliente", {{"", "C", 6, 0, "Cliente", "@!", "TMP_CLI"}} } )

	//Criando o browse da temporária
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias(cAliasTmp)
	oBrowse:SetTemporary(.T.)
	oBrowse:SetFields(aColunas)
	oBrowse:DisableDetails()
	oBrowse:SetDescription(cTitulo)
	oBrowse:SetSeek(.T., aPesquisa)
	oBrowse:Activate()

	oTempTable:Delete()
	FWRestArea(aArea)
Return Nil

/*/{Protheus.doc} MenuDef
Menu de opcoes na funcao SYVAR01
@author Atilio
@since 27/07/2023
@version 1.0
/*/

Static Function MenuDef()
	Local aRotina := {}

	//Adicionando opcoes do menu
	ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.SYVAR01" OPERATION 1 ACCESS 0
	ADD OPTION aRotina TITLE "Incluir" ACTION "VIEWDEF.SYVAR01" OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar" ACTION "VIEWDEF.SYVAR01" OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir" ACTION "VIEWDEF.SYVAR01" OPERATION 5 ACCESS 0

Return aRotina

/*/{Protheus.doc} ModelDef
Modelo de dados na funcao SYVAR01
@author Atilio
@since 27/07/2023
@version 1.0
/*/

Static Function ModelDef()
	Local oModel := Nil
	Local oStTMP := FWFormModelStruct():New()

	//Na estrutura, define os campos e a temporária
	oStTMP:AddTable(cAliasTmp, {'TMP_CLI','TMP_LOJA','TMP_AMB', 'TMP_VAR', 'TMP_VALOR'}, "Temporaria")

	//Adiciona os campos da estrutura
	oStTmp:AddField(;
		"Cliente",;                                                                             // [01]  C   Titulo do campo
	"Cliente",;                                                                                 // [02]  C   ToolTip do campo
	"TMP_CLI",;                                                                                 // [03]  C   Id do Field
	"C",;                                                                                       // [04]  C   Tipo do campo
	06,;                                                                                        // [05]  N   Tamanho do campo
	00,;                                                                                        // [06]  N   Decimal do campo
	Nil,;                                                                                       // [07]  B   Code-block de validação do campo
	Nil,;                                                                                       // [08]  B   Code-block de validação When do campo
	{},;                                                                                        // [09]  A   Lista de valores permitido do campo
	.T.,;                                                                                       // [10]  L   Indica se o campo tem preenchimento obrigatório
	FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTmp+"->TMP_CLI,'')" ),;         // [11]  B   Code-block de inicializacao do campo
	.T.,;                                                                                       // [12]  L   Indica se trata-se de um campo chave
	.F.,;                                                                                       // [13]  L   Indica se o campo pode receber valor em uma operação de update.
	.F.)                                                                                        // [14]  L   Indica se o campo é virtual
	oStTmp:AddField(;
		"Loja",;                                                                                // [01]  C   Titulo do campo
	"Loja",;                                                                                    // [02]  C   ToolTip do campo
	"TMP_LOJA",;                                                                                // [03]  C   Id do Field
	"C",;                                                                                       // [04]  C   Tipo do campo
	002,;                                                                                       // [05]  N   Tamanho do campo
	0,;                                                                                         // [06]  N   Decimal do campo
	Nil,;                                                                                       // [07]  B   Code-block de validação do campo
	Nil,;                                                                                       // [08]  B   Code-block de validação When do campo
	{},;                                                                                        // [09]  A   Lista de valores permitido do campo
	.T.,;                                                                                       // [10]  L   Indica se o campo tem preenchimento obrigatório
	FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTmp+"->TMP_HOST,'')" ),;        // [11]  B   Code-block de inicializacao do campo
	.F.,;                                                                                       // [12]  L   Indica se trata-se de um campo chave
	.F.,;                                                                                       // [13]  L   Indica se o campo pode receber valor em uma operação de update.
	.F.) 
    oStTmp:AddField(;
		"Ambiente",;                                                                            // [01]  C   Titulo do campo
	"Ambiente",;                                                                                // [02]  C   ToolTip do campo
	"TMP_AMB",;                                                                                 // [03]  C   Id do Field
	"C",;                                                                                       // [04]  C   Tipo do campo
	025,;                                                                                       // [05]  N   Tamanho do campo
	0,;                                                                                         // [06]  N   Decimal do campo
	Nil,;                                                                                       // [07]  B   Code-block de validação do campo
	Nil,;                                                                                       // [08]  B   Code-block de validação When do campo
	{},;                                                                                        // [09]  A   Lista de valores permitido do campo
	.T.,;                                                                                       // [10]  L   Indica se o campo tem preenchimento obrigatório
	FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTmp+"->TMP_AMB,'')" ),;         // [11]  B   Code-block de inicializacao do campo
	.F.,;                                                                                       // [12]  L   Indica se trata-se de um campo chave
	.F.,;                                                                                       // [13]  L   Indica se o campo pode receber valor em uma operação de update.
	.F.)                                                                                        // [14]  L   Indica se o campo é virtual
                                                                                       // [14]  L   Indica se o campo é virtual
	oStTmp:AddField(;
		"Var",;                                                                                // [01]  C   Titulo do campo
	"Var",;                                                                                    // [02]  C   ToolTip do campo
	"TMP_VAR",;                                                                                // [03]  C   Id do Field
	"C",;                                                                                       // [04]  C   Tipo do campo
	025,;                                                                                       // [05]  N   Tamanho do campo
	0,;                                                                                         // [06]  N   Decimal do campo
	Nil,;                                                                                       // [07]  B   Code-block de validação do campo
	Nil,;                                                                                       // [08]  B   Code-block de validação When do campo
	{},;                                                                                        // [09]  A   Lista de valores permitido do campo
	.T.,;                                                                                       // [10]  L   Indica se o campo tem preenchimento obrigatório
	FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTmp+"->TMP_HOST,'')" ),;        // [11]  B   Code-block de inicializacao do campo
	.F.,;                                                                                       // [12]  L   Indica se trata-se de um campo chave
	.F.,;                                                                                       // [13]  L   Indica se o campo pode receber valor em uma operação de update.
	.F.)                                                                                        // [14]  L   Indica se o campo é virtual
	oStTmp:AddField(;
		"Valor",;                                                                                // [01]  C   Titulo do campo
	"Valor",;                                                                                    // [02]  C   ToolTip do campo
	"TMP_VALOR",;                                                                                // [03]  C   Id do Field
	"C",;                                                                                       // [04]  C   Tipo do campo
	200,;                                                                                       // [05]  N   Tamanho do campo
	0,;                                                                                         // [06]  N   Decimal do campo
	Nil,;                                                                                       // [07]  B   Code-block de validação do campo
	Nil,;                                                                                       // [08]  B   Code-block de validação When do campo
	{},;                                                                                        // [09]  A   Lista de valores permitido do campo
	.T.,;                                                                                       // [10]  L   Indica se o campo tem preenchimento obrigatório
	FwBuildFeature( STRUCT_FEATURE_INIPAD, "Iif(!INCLUI,"+cAliasTmp+"->TMP_PASS,'')" ),;        // [11]  B   Code-block de inicializacao do campo
	.F.,;                                                                                       // [12]  L   Indica se trata-se de um campo chave
	.F.,;                                                                                       // [13]  L   Indica se o campo pode receber valor em uma operação de update.
	.F.)                                                                                        // [14]  L   Indica se o campo é virtual
	
	//Instanciando o modelo
	oModel := MPFormModel():New("SYVAR01M",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/)
	oModel:AddFields("FORMTMP",/*cOwner*/,oStTMP)
	oModel:SetPrimaryKey({'TMP_CLI'})
	oModel:SetDescription("Modelo de Dados do Cadastro "+cTitulo)
	oModel:GetModel("FORMTMP"):SetDescription("Formulário do Cadastro "+cTitulo)

	//Instala um evento no modelo de dados que irá ficar "observando" as alterações do formulário
	oModel:InstallEvent("VLD_TMPTAB", , zClassTempTab():New(oModel))
Return oModel

/*/{Protheus.doc} ViewDef
Visualizacao de dados na funcao SYVAR01
@author Atilio
@since 27/07/2023
@version 1.0
/*/

Static Function ViewDef()
	Local oModel := FWLoadModel("SYVAR01")
	Local oStTMP := FWFormViewStruct():New()
	Local oView := Nil

	//Adicionando campos da estrutura
	oStTmp:AddField(;
		"TMP_CLI",;             // [01]  C   Nome do Campo
	"01",;                      // [02]  C   Ordem
	"Cliente",;                 // [03]  C   Titulo do campo
	"Cliente",;                 // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"C",;                       // [06]  C   Tipo do campo
	"",;                        // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	Iif(INCLUI, .T., .F.),;     // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opção do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)                        // [18]  L   Indica pulo de linha após o campo
	oStTmp:AddField(;
		"TMP_LOJA",;            // [01]  C   Nome do Campo
	"02",;                      // [02]  C   Ordem
	"Loja",;                    // [03]  C   Titulo do campo
	"Loja",;                    // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"C",;                       // [06]  C   Tipo do campo
	"",;                        // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	.T.,;                       // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opção do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)                        // [18]  L   Indica pulo de linha após o campo
	oStTmp:AddField(;
		"TMP_AMB",;             // [01]  C   Nome do Campo
	"03",;                      // [02]  C   Ordem
	"Ambiente",;                // [03]  C   Titulo do campo
	"Ambiente",;                // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"c",;                       // [06]  C   Tipo do campo
	"",;                        // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	.T.,;                       // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opção do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)
	oStTmp:AddField(;
		"TMP_VAR",;            // [01]  C   Nome do Campo
	"04",;                      // [02]  C   Ordem
	"Var",;                    // [03]  C   Titulo do campo
	"Var",;                    // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"c",;                       // [06]  C   Tipo do campo
	"",;                        // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	.T.,;                       // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opção do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)                        // [18]  L   Indica pulo de linha após o campo
	oStTmp:AddField(;
		"TMP_VALOR",;            // [01]  C   Nome do Campo
	"05",;                      // [02]  C   Ordem
	"Valor",;                    // [03]  C   Titulo do campo
	"Valor",;                    // [04]  C   Descricao do campo
	Nil,;                       // [05]  A   Array com Help
	"c",;                       // [06]  C   Tipo do campo
	"",;                        // [07]  C   Picture
	Nil,;                       // [08]  B   Bloco de PictTre Var
	Nil,;                       // [09]  C   Consulta F3
	.T.,;                       // [10]  L   Indica se o campo é alteravel
	Nil,;                       // [11]  C   Pasta do campo
	Nil,;                       // [12]  C   Agrupamento do campo
	Nil,;                       // [13]  A   Lista de valores permitido do campo (Combo)
	Nil,;                       // [14]  N   Tamanho maximo da maior opção do combo
	Nil,;                       // [15]  C   Inicializador de Browse
	Nil,;                       // [16]  L   Indica se o campo é virtual
	Nil,;                       // [17]  C   Picture Variavel
	Nil)
	
	//Criando a view que será o retorno da função e setando o modelo da rotina
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_TMP", oStTMP, "FORMTMP")
	oView:CreateHorizontalBox("TELA",100)
	oView:EnableTitleView('VIEW_TMP', 'Dados - '+cTitulo )
	oView:SetCloseOnOk({||.T.})
	oView:SetOwnerView("VIEW_TMP","TELA")
Return oView
