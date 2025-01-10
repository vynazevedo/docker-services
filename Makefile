MAKEFLAGS += --no-print-directory

# === Variáveis ===
WORKSPACE_DIR=workspace
PROJECTS := {}

PROJECT ?= all

# === Verificação de Ambiente ===
check-infra: ## Verifica infraestrutura compartilhada
	@echo "Verificando infraestrutura compartilhada..."
	@docker network inspect pricing_network >/dev/null 2>&1 || \
		docker network create pricing_network
	@if ! docker ps | grep -q pricing-shared-localstack; then \
		echo "Iniciando infraestrutura compartilhada..."; \
		docker-compose up -d; \
		echo "Aguardando servicos iniciarem..."; \
		sleep 10; \
	else \
		echo "Infraestrutura ja esta rodando"; \
	fi

# === Comandos de Infraestrutura ===
infra-start: ## Inicia infraestrutura compartilhada
	docker-compose up -d

infra-stop: ## Para infraestrutura compartilhada
	docker-compose down

# === Comandos para Projetos ===
execute-command = @if [ "$(PROJECT)" = "all" ]; then \
	for project in $(PROJECTS); do \
		echo "=== $$project ==="; \
		cd $(WORKSPACE_DIR)/$$project && make $(1) && cd ../..; \
	done; \
else \
	echo "=== $(PROJECT) ==="; \
	cd $(WORKSPACE_DIR)/$(PROJECT) && make $(1); \
fi

check-deps: ## Verifica dependências necessárias
	@echo "Verificando dependencias..."
	@docker compose version | grep -q "v2." && \
   	(docker compose version | awk '{print $$4}' | awk -F. '$$2 > 29 || ($$2 == 29 && $$3 >= 7)' || \
   	(echo "Error: Docker Compose v2.29.7 ou superior é necessário"; exit 1))
	@if ! node -v | grep -q "v18" ; then \
		echo "Error: Node.js 18 e necessario para este projeto"; \
		exit 1; \
	fi
	@command -v serverless >/dev/null 2>&1 || { \
		echo "Instalando serverless@3.38.0 globalmente..."; \
		npm i -g serverless@3.38.0 || sudo npm i -g serverless@3.38.0; \
	}
	@npm list -g serverless-offline >/dev/null 2>&1 || { \
		echo "Instalando serverless-offline globalmente..."; \
		npm i -g serverless-offline || sudo npm i -g serverless-offline; \
	}
	@npm list -g serverless-localstack >/dev/null 2>&1 || { \
		echo "Instalando serverless-localstack globalmente..."; \
		npm i -g serverless-localstack || sudo npm i -g serverless-localstack; \
	}


start: check-deps check-infra ## Inicia projeto(s)
	$(call execute-command,$@)

stop: ## Para projeto(s)
	$(call execute-command,$@)

clean: ## Remove recursos
	$(call execute-command,$@)

test: check-deps check-infra ## Executa testes
	$(call execute-command,$@)

test-all: check-infra ## Executa todos os testes
	$(call execute-command,$@)

dev: check-deps check-infra ## Pipeline de desenvolvimento
	$(call execute-command,$@)

# === Status ===
status: ## Status de todos os serviços
	@echo "=== Infraestrutura Compartilhada ==="
	@docker ps --filter "name=pricing-shared" --format "Nome: {{.Names}}\nID: {{.ID}}\nStatus: {{.Status}}\nPortas: {{.Ports}}\n"

	@if [ "$(PROJECT)" = "all" ]; then \
		echo "=== Todos os Projetos ==="; \
		for project in $(PROJECTS); do \
			echo " $$project:"; \
			cd $(WORKSPACE_DIR)/$$project && make status && cd ../..; \
		done; \
	else \
		echo "=== Projeto $(PROJECT) ==="; \
		cd $(WORKSPACE_DIR)/$(PROJECT) && make status; \
	fi

help: ## Lista comandos disponíveis
	@echo "Uso: make [comando] [PROJECT=nome-do-projeto]"
	@echo ""
	@echo "Comandos disponiveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: check-deps check-infra infra-start infra-stop start stop clean test dev status help
.DEFAULT_GOAL := help
