SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










-- Cooperativa Nova Alianca Ltda
-- View para buscar saldos de/em poder de terceiros.
-- Autor: Robert Koch
-- Data:  24/06/2016
-- Historico de alteracoes:
-- 11/07/2016 - Robert - Acrescentadas colunas ORIGEM e TES.
-- 16/09/2016 - Robert - Acrescentada coluna B1_TIPO.
-- 13/03/2019 - Andre  - Acrescantada coluna B6_PRUNIT.
-- 05/02/2021 - Daiana - Alterada a descrição do produto. GLPI: 9297
-- 16/11/2021 - Claudia - Incluido campo de usuario emissor. GLPI: 11165
-- 

--SELECT * FROM [VA_VSALDOS_TERCEIROS]

ALTER VIEW [dbo].[VA_VSALDOS_TERCEIROS] AS

	WITH C
	AS
	(SELECT
			SB6.B6_FILIAL
		   ,SB6.B6_EMISSAO
		   ,SB6.B6_PRODUTO
		   ,SB6.B6_TIPO
		   ,SB6.B6_IDENT
		   ,SB6.B6_CLIFOR
		   ,SB6.B6_LOJA
		   ,SB6.B6_DOC
		   ,SB6.B6_SERIE
		   ,SB6.B6_QUANT
		   ,SB6.B6_SALDO
		   ,SB6.B6_PRUNIT

			-- TENTA RELACIONAR COM A TABELA DE NF DE ENTRADA
		   ,(SELECT
					D1_TIPO + D1_TES
				FROM SD1010 SD1
				WHERE SB6.B6_TIPO = 'D'
				AND SD1.D_E_L_E_T_ = ''
				AND SD1.D1_FILIAL = SB6.B6_FILIAL
				AND SD1.D1_DOC = SB6.B6_DOC
				AND SD1.D1_SERIE = SB6.B6_SERIE
				AND SD1.D1_FORNECE = SB6.B6_CLIFOR
				AND SD1.D1_LOJA = SB6.B6_LOJA
				AND SD1.D1_IDENTB6 = SB6.B6_IDENT)
			AS DADOS_SD1
		   ,(SELECT
					SD1.D1_DESCRI
				FROM SD1010 SD1
				WHERE SB6.B6_TIPO = 'D'
				AND SD1.D_E_L_E_T_ = ''
				AND SD1.D1_FILIAL = SB6.B6_FILIAL
				AND SD1.D1_DOC = SB6.B6_DOC
				AND SD1.D1_SERIE = SB6.B6_SERIE
				AND SD1.D1_FORNECE = SB6.B6_CLIFOR
				AND SD1.D1_LOJA = SB6.B6_LOJA
				AND SD1.D1_IDENTB6 = SB6.B6_IDENT)
			AS DESC_SD1

			-- TENTA RELACIONAR COM A TABELA DE NF DE SAIDA
		   ,(SELECT
					D2_TIPO + D2_TES
				FROM SD2010 SD2
				WHERE SB6.B6_TIPO = 'E'
				AND SD2.D_E_L_E_T_ = ''
				AND SD2.D2_FILIAL = SB6.B6_FILIAL
				AND SD2.D2_DOC = SB6.B6_DOC
				AND SD2.D2_SERIE = SB6.B6_SERIE
				AND SD2.D2_CLIENTE = SB6.B6_CLIFOR
				AND SD2.D2_LOJA = SB6.B6_LOJA
				AND SD2.D2_IDENTB6 = SB6.B6_IDENT)
			AS DADOS_SD2



		   ,(SELECT
					C6_DESCRI
				FROM SD2010 SD2
				LEFT JOIN SC6010 SC6
					ON (SC6.D_E_L_E_T_ = ''
					AND SC6.C6_FILIAL = SD2.D2_FILIAL
					AND SC6.C6_ITEM = SD2.D2_ITEMPV
					--AND SC6.C6_PRODUTO = SD2.D2_COD
					AND SC6.C6_NUM = SD2.D2_PEDIDO)
				WHERE SB6.B6_TIPO = 'E'
				AND SD2.D_E_L_E_T_ = ''
				AND SD2.D2_FILIAL = SB6.B6_FILIAL
				AND SD2.D2_DOC = SB6.B6_DOC
				AND SD2.D2_SERIE = SB6.B6_SERIE
				AND SD2.D2_CLIENTE = SB6.B6_CLIFOR
				AND SD2.D2_LOJA = SB6.B6_LOJA
				AND SD2.D2_IDENTB6 = SB6.B6_IDENT)
			AS DESC_SD2

		   ,(SELECT
					C5_VAUSER
				FROM SD2010 SD2
				LEFT JOIN SC5010 SC5
					ON (SC5.D_E_L_E_T_ = ''
					AND SC5.C5_FILIAL = SD2.D2_FILIAL
					AND SC5.C5_NUM = SD2.D2_PEDIDO)
				WHERE SB6.B6_TIPO = 'E'
				AND SD2.D_E_L_E_T_ = ''
				AND SD2.D2_FILIAL = SB6.B6_FILIAL
				AND SD2.D2_DOC = SB6.B6_DOC
				AND SD2.D2_SERIE = SB6.B6_SERIE
				AND SD2.D2_CLIENTE = SB6.B6_CLIFOR
				AND SD2.D2_LOJA = SB6.B6_LOJA
				AND SD2.D2_IDENTB6 = SB6.B6_IDENT)
			AS SOLICITANTE

		FROM SB6010 SB6
		WHERE SB6.D_E_L_E_T_ = ''
		AND SB6.B6_PODER3 = 'R' -- REMESSA (INICIO DA OPERACAO)
		AND SB6.B6_SALDO != 0)
	SELECT
		C.B6_FILIAL
	   ,C.B6_IDENT
	   ,C.B6_TIPO
	   ,C.B6_EMISSAO
	   ,SB1.B1_TIPO
	   ,C.B6_PRODUTO
	   ,CASE
			WHEN DESC_SD1 IS NOT NULL THEN C.DESC_SD1
			WHEN DESC_SD2 IS NOT NULL THEN C.DESC_SD2
			ELSE SB1.B1_DESC
		END AS DESCRICAO
	   ,C.B6_QUANT
	   ,C.B6_SALDO
	   ,C.B6_CLIFOR
	   ,C.B6_LOJA
	   ,C.B6_DOC
	   ,C.B6_SERIE
		-- COMO A TABELA SB6 NAO INDICA SE FOI USADO CLIENTE OU FORNECEDOR, NEM O TIPO DE NOTA, PRECISO TESTAR TODAS AS POSSIBILIDADES.
	   ,CASE
			WHEN DADOS_SD1 IS NOT NULL THEN 'SD1'
			ELSE CASE
					WHEN DADOS_SD2 IS NOT NULL THEN 'SD2'
					ELSE ''
				END
		END AS ORIGEM
	   ,CASE
			WHEN DADOS_SD1 IS NOT NULL THEN SUBSTRING(DADOS_SD1, 1, 1)
			ELSE CASE
					WHEN DADOS_SD2 IS NOT NULL THEN SUBSTRING(DADOS_SD2, 1, 1)
					ELSE ''
				END
		END AS TIPO_NF
	   ,CASE
			WHEN DADOS_SD1 IS NOT NULL THEN CASE
					WHEN SUBSTRING(DADOS_SD1, 1, 1) IN ('B', 'D') THEN A1_NOME
					ELSE A2_NOME
				END
			ELSE CASE
					WHEN DADOS_SD2 IS NOT NULL THEN CASE
							WHEN SUBSTRING(DADOS_SD2, 1, 1) IN ('B', 'D') THEN A2_NOME
							ELSE A1_NOME
						END
				END
		END AS NOME
	   ,CASE
			WHEN DADOS_SD1 IS NOT NULL THEN SUBSTRING(DADOS_SD1, 2, 3)
			ELSE CASE
					WHEN DADOS_SD2 IS NOT NULL THEN SUBSTRING(DADOS_SD2, 2, 3)
					ELSE ''
				END
		END AS TES
	   ,B6_PRUNIT
	   ,C.SOLICITANTE
	FROM SB1010 SB1
		,C
		 LEFT JOIN SA2010 SA2
			 ON (SA2.D_E_L_E_T_ = ''
					 AND SA2.A2_FILIAL = ' '
					 AND SA2.A2_COD = C.B6_CLIFOR
					 AND SA2.A2_LOJA = C.B6_LOJA)
		 LEFT JOIN SA1010 SA1
			 ON (SA1.D_E_L_E_T_ = ''
					 AND SA1.A1_FILIAL = ' '
					 AND SA1.A1_COD = C.B6_CLIFOR
					 AND SA1.A1_LOJA = C.B6_LOJA)
	WHERE SB1.D_E_L_E_T_ = ''
	AND SB1.B1_FILIAL = ' '
	AND SB1.B1_COD = C.B6_PRODUTO
;




GO