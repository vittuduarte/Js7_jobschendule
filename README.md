# JS7 JobScheduler Docker

Este repositório contém a configuração para executar o JS7 JobScheduler em containers Docker, permitindo uma implantação rápida e consistente em diferentes ambientes.

## Sobre o JS7 JobScheduler

O JS7 JobScheduler é uma solução robusta de orquestração e automação de jobs, que permite agendar, executar e monitorar processos de negócios em tempo real. Com uma arquitetura distribuída, o JS7 oferece alta disponibilidade, escalabilidade e segurança para seus fluxos de trabalho automatizados.

## Características Principais

- **Arquitetura Containerizada**: Toda infraestrutura JS7 encapsulada em containers Docker
- **Configuração Simplificada**: Arquivos de configuração pré-definidos para rápida implantação
- **Escalabilidade**: Fácil escalonamento horizontal para atender demandas crescentes
- **Alta Disponibilidade**: Suporte a configurações redundantes para maior resiliência
- **Portabilidade**: Execute em qualquer ambiente que suporte Docker

## Requisitos

- Docker 20.10.x ou superior
- Docker Compose 2.x ou superior
- Mínimo de 4GB de RAM disponível
- 10GB de espaço em disco

## Estrutura do Repositório

```
.
├── docker-compose.yml          # Definição dos serviços e redes
├── config/                     # Diretório de configurações
│   ├── controller/             # Configurações do JS7 Controller
│   ├── agent/                  # Configurações do JS7 Agent
│   └── joc/                    # Configurações do JOC Cockpit
├── volumes/                    # Volumes persistentes
├── scripts/                    # Scripts utilitários
└── examples/                   # Exemplos de jobs e workflows
```

## Como Usar

### Instalação

1. Clone este repositório:
   ```bash
   git clone https://github.com/seu-usuario/js7-jobscheduler-docker.git
   cd js7-jobscheduler-docker
   ```

2. Configure as variáveis de ambiente (opcional):
   ```bash
   cp .env.example .env
   # Edite o arquivo .env conforme necessário
   ```

3. Inicie os containers:
   ```bash
   docker-compose up -d
   ```

### Componentes Disponíveis

- **JS7 Controller**: Gerencia a orquestração central de jobs
- **JS7 Agent**: Executa os jobs nos ambientes alvo
- **JOC Cockpit**: Interface web para gerenciamento e monitoramento

### Acessando a Interface Web

Após a inicialização, acesse o JOC Cockpit em:
```
http://localhost:4446
```

Credenciais padrão:
- Usuário: `root`
- Senha: `root` (recomendamos alterar após o primeiro acesso)

## Configurações Avançadas

### Clusters e Alta Disponibilidade

Para configurar um ambiente de alta disponibilidade, consulte o arquivo `docker-compose.ha.yml`:

```bash
docker-compose -f docker-compose.ha.yml up -d
```

### Integração com Outros Sistemas

Exemplos de integração com bancos de dados, serviços cloud e outras ferramentas estão disponíveis no diretório `examples/integrations/`.

## Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para enviar pull requests ou abrir issues para melhorias e correções.

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Faça commit de suas alterações (`git commit -m 'Adiciona nova funcionalidade'`)
4. Envie para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

## Suporte

Para problemas, dúvidas ou sugestões, por favor abra uma issue no GitHub.

---

**Nota**: Este projeto não é oficialmente afiliado ao SoftwareAG JS7 JobScheduler. Para suporte oficial, consulte a [documentação oficial](https://js7.softwareag.com).
