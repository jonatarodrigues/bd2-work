CREATE TABLE [equipamentos] (
  [cod_equipamento] int PRIMARY KEY IDENTITY(1, 1),
  [nome] varchar(50),
  [modelo] varchar(50),
  [fabricante] varchar(50),
  [numero_serie] varchar(30) UNIQUE,
  [peso_kg] numeric(8,2),
  [data_aquisicao] date,
  [valor_aquisicao] numeric(10,2),
  [data_ultima_calibracao] date,
  [data_proxima_calibracao] date,
  [status] varchar(15),
  [cod_fornecedor] smallint
)
GO

CREATE TABLE [fornecedores] (
  [cod_fornecedor] smallint PRIMARY KEY IDENTITY(1, 1),
  [nome] varchar(50),
  [cnpj] char(14) UNIQUE,
  [uf] char(2),
  [telefone] varchar(15),
  [email] varchar(100),
  [ranking] smallint
)
GO

CREATE TABLE [clientes] (
  [cod_cliente] int PRIMARY KEY IDENTITY(1, 1),
  [tipo_pessoa] char(1),
  [nome] varchar(100),
  [cpf_cnpj] varchar(14) UNIQUE,
  [inscricao_estadual] varchar(20),
  [data_nascimento] date,
  [telefone] varchar(15),
  [email] varchar(100) UNIQUE,
  [senha] varchar(30),
  [cep] char(8),
  [logradouro] varchar(100),
  [numero] varchar(10),
  [complemento] varchar(50),
  [bairro] varchar(50),
  [cidade] varchar(50),
  [uf] char(2),
  [data_cadastro] date
)
GO

CREATE TABLE [financeiro] (
  [cod_pagamento] int PRIMARY KEY IDENTITY(1, 1),
  [cod_contrato] int,
  [valor] numeric(10,2),
  [data_vencimento] date,
  [data_pagamento] date,
  [forma_pagamento] varchar(15),
  [status] varchar(15)
)
GO

CREATE TABLE [contratos] (
  [cod_contrato] int PRIMARY KEY IDENTITY(1, 1),
  [cod_cliente] int,
  [cod_funcionario] smallint,
  [data_inicio] date,
  [data_fim_prevista] date,
  [data_devolucao] date,
  [status] varchar(15)
)
GO

CREATE TABLE [itens_contrato] (
  [cod_contrato] int,
  [cod_equipamento] int,
  [valor_acordado] numeric(9,2),
  PRIMARY KEY ([cod_contrato], [cod_equipamento])
)
GO

CREATE TABLE [funcionarios] (
  [cod_funcionario] smallint PRIMARY KEY IDENTITY(1, 1),
  [nome_funcionario] varchar(50),
  [data_contratacao] date,
  [data_demissao] date,
  [data_nasc_funcionario] date,
  [funcao] char(20),
  [descricao_funcao] varchar(200),
  [remuneracao] numeric(9,2)
)
GO

CREATE TABLE [manutencoes] (
  [cod_manutencao] int PRIMARY KEY IDENTITY(1, 1),
  [cod_equipamento] int,
  [cod_funcionario] smallint,
  [cod_fornecedor] smallint,
  [tipo] varchar(15),
  [data_entrada] date,
  [data_saida] date,
  [motivo] varchar(200),
  [custo] numeric(9,2)
)
GO

CREATE TABLE [orcamentos] (
  [cod_orcamento] smallint PRIMARY KEY IDENTITY(1, 1),
  [cod_cliente] int,
  [valor_orcamento] numeric(9,2),
  [descricao] varchar(200),
  [valor_previsto] numeric(9,2),
  [valor_total_gasto] numeric(9,2)
)
GO

CREATE TABLE [chamados] (
  [cod_chamado] int PRIMARY KEY IDENTITY(1, 1),
  [cod_cliente] int,
  [cod_funcionario] smallint,
  [cod_contrato] int,
  [cod_equipamento] int,
  [descricao] varchar(200),
  [prioridade] varchar(10),
  [status] varchar(15),
  [data_abertura] datetime,
  [data_fechamento] datetime
)
GO

CREATE TABLE [logistica] (
  [cod_entrega] int PRIMARY KEY IDENTITY(1, 1),
  [cod_contrato] int,
  [cod_funcionario] smallint,
  [tipo] varchar(10),
  [data_prevista] date,
  [data_realizada] date,
  [cep] char(8),
  [endereco] varchar(200),
  [cidade] varchar(50),
  [uf] char(2),
  [observacao] varchar(200),
  [status] varchar(15)
)
GO

CREATE TABLE [valores_locacao] (
  [cod_valores] int PRIMARY KEY IDENTITY(1, 1),
  [cod_equipamento] int,
  [valor_mensal] numeric(9,2),
  [vigencia_inicio] date,
  [vigencia_fim] date
)
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'disponível / locado / manutenção',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'equipamentos',
@level2type = N'Column', @level2name = 'status';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'F ou J',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'clientes',
@level2type = N'Column', @level2name = 'tipo_pessoa';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'pendente / pago / atrasado',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'financeiro',
@level2type = N'Column', @level2name = 'status';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'ativo / encerrado / atrasado',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'contratos',
@level2type = N'Column', @level2name = 'status';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'preventiva / corretiva',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'manutencoes',
@level2type = N'Column', @level2name = 'tipo';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'baixa / moderado / alta / urgente',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'chamados',
@level2type = N'Column', @level2name = 'prioridade';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'aberto / em andamento / resolvido / fechado',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'chamados',
@level2type = N'Column', @level2name = 'status';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'entrega ou retirada',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'logistica',
@level2type = N'Column', @level2name = 'tipo';
GO

EXEC sp_addextendedproperty
@name = N'Column_Description',
@value = 'agendada / em rota / concluída / cancelada',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table',  @level1name = 'logistica',
@level2type = N'Column', @level2name = 'status';
GO

ALTER TABLE [equipamentos] ADD FOREIGN KEY ([cod_fornecedor]) REFERENCES [fornecedores] ([cod_fornecedor])
GO

ALTER TABLE [financeiro] ADD FOREIGN KEY ([cod_contrato]) REFERENCES [contratos] ([cod_contrato])
GO

ALTER TABLE [contratos] ADD FOREIGN KEY ([cod_cliente]) REFERENCES [clientes] ([cod_cliente])
GO

ALTER TABLE [contratos] ADD FOREIGN KEY ([cod_funcionario]) REFERENCES [funcionarios] ([cod_funcionario])
GO

ALTER TABLE [itens_contrato] ADD FOREIGN KEY ([cod_contrato]) REFERENCES [contratos] ([cod_contrato])
GO

ALTER TABLE [itens_contrato] ADD FOREIGN KEY ([cod_equipamento]) REFERENCES [equipamentos] ([cod_equipamento])
GO

ALTER TABLE [manutencoes] ADD FOREIGN KEY ([cod_equipamento]) REFERENCES [equipamentos] ([cod_equipamento])
GO

ALTER TABLE [manutencoes] ADD FOREIGN KEY ([cod_funcionario]) REFERENCES [funcionarios] ([cod_funcionario])
GO

ALTER TABLE [manutencoes] ADD FOREIGN KEY ([cod_fornecedor]) REFERENCES [fornecedores] ([cod_fornecedor])
GO

ALTER TABLE [orcamentos] ADD FOREIGN KEY ([cod_cliente]) REFERENCES [clientes] ([cod_cliente])
GO

ALTER TABLE [chamados] ADD FOREIGN KEY ([cod_cliente]) REFERENCES [clientes] ([cod_cliente])
GO

ALTER TABLE [chamados] ADD FOREIGN KEY ([cod_funcionario]) REFERENCES [funcionarios] ([cod_funcionario])
GO

ALTER TABLE [chamados] ADD FOREIGN KEY ([cod_contrato]) REFERENCES [contratos] ([cod_contrato])
GO

ALTER TABLE [chamados] ADD FOREIGN KEY ([cod_equipamento]) REFERENCES [equipamentos] ([cod_equipamento])
GO

ALTER TABLE [logistica] ADD FOREIGN KEY ([cod_contrato]) REFERENCES [contratos] ([cod_contrato])
GO

ALTER TABLE [logistica] ADD FOREIGN KEY ([cod_funcionario]) REFERENCES [funcionarios] ([cod_funcionario])
GO

ALTER TABLE [valores_locacao] ADD FOREIGN KEY ([cod_equipamento]) REFERENCES [equipamentos] ([cod_equipamento])
GO
