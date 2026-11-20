# Normalização do modelo físico (Issue #9)

Análise do modelo em `Modelo_fisico/Database.sql` (12 tabelas) frente à 1ª, 2ª e 3ª formas normais.
Para cada quebra encontrada há duas saídas: **corrigir** (proposta de ajuste no DDL) ou **manter e justificar**.
A decisão final é do grupo; as propostas de DDL ficam para a Issue #11 (script DDL).

## Resumo

| Forma normal | Situação | Observação |
|---|---|---|
| 1FN | ✅ Atende | Exceção discutível: `logistica.endereco` (ver item 1) |
| 2FN | ✅ Atende | Só `itens_contrato` tem PK composta, e `valor_acordado` depende da chave inteira |
| 3FN | ⚠️ 4 quebras + 4 desnormalizações intencionais | Ver itens 3 a 10 |

---

## 1ª Forma Normal: valores atômicos, sem grupos repetidos

- Todas as tabelas têm PK e nenhuma coluna guarda listas (ex.: não existe `equipamentos = "1,2,3"` em contratos).
- O endereço do cliente já está decomposto (`cep`, `logradouro`, `numero`, `complemento`, `bairro`, `cidade`, `uf`).
- A relação **N x N** entre contratos e equipamentos (um contrato tem vários equipamentos; um equipamento passa por vários contratos ao longo do tempo) foi resolvida com a tabela associativa `itens_contrato`, cuja PK é `(cod_contrato, cod_equipamento)`.

**1. `logistica.endereco varchar(200)`** guarda logradouro, número e bairro numa coluna só.
- *Justificativa para manter:* é um **retrato do endereço no momento da entrega**. Ele não é usado em filtros nem em agrupamentos, só é impresso na ordem de entrega. `cep`, `cidade` e `uf` continuam separados para as consultas de rota.
- *Alternativa:* decompor como em `clientes` (custo: mais 4 colunas).

## 2ª Forma Normal: nenhum atributo depende de parte da chave

**2.** A única PK composta é `itens_contrato (cod_contrato, cod_equipamento)`. O único atributo não-chave, `valor_acordado`, depende das duas colunas juntas, porque o mesmo equipamento tem preços diferentes em contratos diferentes. ✅

> `valor_acordado` **não** é redundante com `valores_locacao.valor_mensal`. A tabela de preços é o preço de lista vigente, e `valor_acordado` é o preço negociado no contrato (com desconto) e congelado no tempo. Se a tabela de preços mudar, o contrato antigo não pode mudar junto.

## 3ª Forma Normal: nenhum atributo depende de outro atributo não-chave

### Quebras que recomendamos corrigir

**3. `funcionarios`: `funcao → descricao_funcao`** (dependência transitiva)
A descrição depende da função, não do funcionário. No DML, os 20 funcionários repetem só 5 descrições diferentes. Se a descrição de "Motorista" mudar, é preciso atualizar várias linhas (anomalia de atualização).

```sql
CREATE TABLE cargos (
  cod_cargo  tinyint      PRIMARY KEY IDENTITY(1,1),  -- poucos cargos: tinyint (0..255) basta
  nome       varchar(30)  NOT NULL UNIQUE,
  descricao  varchar(200) NOT NULL
);
-- funcionarios: troca funcao char(20) + descricao_funcao varchar(200) por
--   cod_cargo tinyint NOT NULL REFERENCES cargos(cod_cargo)
```

**4. `equipamentos`: `modelo → nome, fabricante, peso_kg`** (dependência transitiva)
Com várias unidades do mesmo modelo (no DML há 2 "EverFlo 5L" e 2 "CH-3M"), nome, fabricante e peso se repetem a cada unidade. O que é próprio da **unidade** é número de série, data e valor de aquisição, calibração e status.

```sql
CREATE TABLE modelos_equipamento (
  cod_modelo  smallint     PRIMARY KEY IDENTITY(1,1),
  tipo        varchar(50)  NOT NULL,          -- "Concentrador de Oxigênio"
  modelo      varchar(50)  NOT NULL,
  fabricante  varchar(50)  NOT NULL,
  peso_kg     decimal(5,2) NOT NULL,          -- até 999,99 kg
  CONSTRAINT uq_modelo UNIQUE (fabricante, modelo)
);
-- equipamentos: troca nome, modelo, fabricante, peso_kg por cod_modelo smallint FK
```
*Bônus:* `valores_locacao` poderia apontar para o **modelo** (todas as unidades do mesmo modelo têm o mesmo preço de tabela).

**5. `orcamentos`: colunas ambíguas e sem vínculo**
`valor_orcamento`, `valor_previsto` e `valor_total_gasto` não deixam claro o que cada um representa. A tabela também não diz *quais equipamentos* foram orçados nem *qual contrato* surgiu do orçamento. O `valor_total_gasto` seria derivável do contrato.
- No DML adotamos a convenção: `valor_previsto` = preço de tabela; `valor_orcamento` = valor proposto ao cliente; `valor_total_gasto` = valor efetivado (NULL = orçamento não virou contrato).
- *Proposta:* adicionar `cod_contrato int NULL` (FK) e remover `valor_total_gasto`, ou documentar a convenção acima no dicionário de dados.

**6. `chamados`: `cod_contrato → cod_cliente`**
Quando o chamado tem contrato, o cliente já é conhecido pelo contrato.
- *Justificativa para manter:* um chamado pode ser aberto **sem contrato** (ex.: dúvida antes de alugar). Por isso `cod_cliente` fica e `cod_contrato`/`cod_equipamento` devem aceitar NULL. A coerência (cliente do chamado = cliente do contrato) pode ser garantida por trigger. No DML, todos os 20 chamados respeitam essa regra.

### Desnormalizações intencionais (manter e justificar)

São colunas **deriváveis** de outras tabelas, mantidas por desempenho e simplicidade das telas. É a dica #1 da aula de otimização ("desnormalize sempre que tiver oportunidade") somada à #2 ("evite múltiplos JOINs"): cada coluna abaixo poupa joins nas consultas mais frequentes, ao custo de precisar ser mantida atualizada.


| # | Coluna | Pode ser calculada a partir de | Por que manter |
|---|---|---|---|
| 7 | `equipamentos.status` | `itens_contrato` + `contratos.data_devolucao` + `manutencoes.data_saida` | A tela "equipamentos disponíveis" é a mais consultada; calcular o status exigiria 2 joins a cada consulta. **Ótimo candidato para a trigger obrigatória** (ao inserir item de contrato → `locado`; ao devolver → `disponível`). |
| 8 | `equipamentos.data_ultima_calibracao` / `data_proxima_calibracao` | `MAX(manutencoes.data_saida)` das preventivas | Alerta de calibração vencida sem varrer o histórico de manutenções. Podem ser atualizadas pela mesma trigger, ao fechar uma manutenção preventiva. |
| 9 | `contratos.status`, `financeiro.status` | Datas (`data_fim_prevista`, `data_devolucao`, `data_vencimento`, `data_pagamento`) | Leitura direta pelo CRUD. **Risco:** "atrasado" muda com o passar dos dias sem nenhum UPDATE, e por isso as perguntas de negócio usam as datas, não o status. Uma stored procedure executada diariamente (ex.: `EXEC pr_atualiza_atrasos`) pode atualizar esses status. |
| 10 | `clientes.cidade/uf` e `logistica.cidade/uf` | `cep` (o CEP determina cidade e UF) | Dependência transitiva aceita por convenção de mercado: manter uma tabela com todos os CEPs do Brasil (~1 milhão de linhas) não se justifica para este sistema. |

## Generalização x Especialização

**`clientes` (pessoa física x jurídica)**: optou-se por **uma tabela só** (generalização) com `tipo_pessoa`, pois só 2 colunas são exclusivas (`data_nascimento` para PF e `inscricao_estadual` para PJ). Separar em `clientes_pf` / `clientes_pj` obrigaria a um join em toda consulta de cliente. Para garantir a integridade, sugerimos as CHECKs:

```sql
CONSTRAINT ck_clientes_tipo  CHECK (tipo_pessoa IN ('F','J')),
CONSTRAINT ck_clientes_doc   CHECK ((tipo_pessoa = 'F' AND LEN(cpf_cnpj) = 11 AND inscricao_estadual IS NULL)
                                 OR (tipo_pessoa = 'J' AND LEN(cpf_cnpj) = 14 AND data_nascimento IS NULL))
```

**`manutencoes` (interna x terceirizada)**: a mesma tabela atende as duas; `cod_fornecedor` só é preenchido quando o serviço é terceirizado. Sugestão: `CHECK (cod_funcionario IS NOT NULL OR cod_fornecedor IS NOT NULL)`.

## Outras observações para o DDL (Issue #11)

- **CHECK e DEFAULT são obrigatórios** no trabalho e ainda não existem. Os domínios hoje estão só em `sp_addextendedproperty`; devem virar `CHECK (status IN (...))`. Sugestões de DEFAULT: `clientes.data_cadastro DEFAULT GETDATE()`, `equipamentos.status DEFAULT 'disponível'`, `financeiro.status DEFAULT 'pendente'`, `chamados.data_abertura DEFAULT GETDATE()`.
- Os valores usados no DML são exatamente os documentados (`disponível`, `manutenção`, `concluída` com acento). Se a CHECK for criada sem acento, o DML precisa acompanhar.
- Faltam `NOT NULL` nas colunas obrigatórias (nome, datas de início, valores, FKs principais).
- `clientes.senha varchar(30)` guarda a senha em texto puro. Num sistema real, o banco guardaria apenas um hash (resumo criptográfico) da senha, gerado pela aplicação.
- Nomear as constraints (`CONSTRAINT pk_contratos PRIMARY KEY ...`) deixa o plano de execução e o dicionário de dados legíveis; sem nome, aparecem como `PK__contrato__3B2C...`.
- Tipos: `fornecedores.ranking smallint → tinyint`; `funcao char(20) → varchar` (char completa com espaços); `peso_kg numeric(8,2)` (até 999.999,99 kg) `→ decimal(5,2)`.
