WITH NOTAS AS (
SELECT FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, SUM (VALOR_TOTAL) NF_VALOR, SUM (VALOR_FRETE) NF_FRETE, SUM (VLR_FUNRURAL) NF_FUNRURAL
FROM VA_VNOTAS_SAFRA
WHERE SAFRA = '2024'
AND TIPO_NF = 'C'
GROUP BY FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE
)
, TITULOS AS (
SELECT E2_FILIAL, E2_FORNECE, E2_LOJA, E2_NUM, E2_PREFIXO, SUM (E2_VALOR) TIT_VALOR
FROM SE2010
WHERE D_E_L_E_T_ = ''
AND E2_VASAFRA = '2024'
AND E2_TIPO = 'NF'
GROUP BY E2_FILIAL, E2_FORNECE, E2_LOJA, E2_NUM, E2_PREFIXO
)
, J AS (
SELECT * FROM NOTAS
	FULL OUTER JOIN TITULOS
		ON (NOTAS.FILIAL = TITULOS.E2_FILIAL
		AND NOTAS.ASSOCIADO = TITULOS.E2_FORNECE
		AND NOTAS.LOJA_ASSOC = TITULOS.E2_LOJA
		AND NOTAS.DOC = TITULOS.E2_NUM
		AND NOTAS.SERIE = TITULOS.E2_PREFIXO)
)
SELECT *, 
FROM J
--WHERE (DOC IS NULL OR E2_NUM IS NULL)
