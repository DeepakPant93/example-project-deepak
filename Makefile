# =============================
# Project Configuration
# =============================
IMAGE_NAME = deepak93p/example_project_deepak
TAG = latest
CLOUD_REGION = eastus
RESOURCE_GROUP = example-project-deepak-rg
APP_NAME = example-project-deepak-app
APP_ENV_NAME = example-project-deepak-app-env
GITHUB_USERNAME = DeepakPant93
GITHUB_REPO = example-project-deepak
PROJECT_SLUG = example_project_deepak
FOLDER_ID = 1isRnM6FiyMuE8l8ojWD-yzWHe3AdiNFX
GCLOUD_PROJECT_ID = $(shell gcloud config get-value project)
SERVICE_ACCOUNT_NAME = example-project-deepak-dvcsa

# =============================
# Help (Default Target)
# =============================
.PHONY: help
help: ## Display this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

# =============================
# Installation and Setup
# =============================
.PHONY: install
install: ## Install the poetry environment and set up pre-commit hooks
	@echo "🚀 Creating virtual environment using pyenv and poetry"
	@poetry install
	@poetry run pre-commit install
	@poetry run pip install --upgrade dvc dvc-gdrive pydrive2 pyOpenSSL
	@poetry shell

.PHONY: git-init
git-init: ## Initialize git repository
	@echo "🚀 Initializing git repository"
	@git init
	@echo "🚀 Creating initial commit"
	@git add .
	@git commit -m "Initial commit"
	@echo "🚀 Adding remote repository"
	@git remote add origin git@github.com:$(GITHUB_USERNAME)/$(GITHUB_REPO).git
	@echo "🚀 Pushing initial commit"
	@git push -u origin main

.PHONY: setup-env
setup-env: ## Create resource group, container app environment, and service principal
	@echo "🚀 Creating resource group: $(RESOURCE_GROUP)"
	@az group create --name $(RESOURCE_GROUP) --location $(CLOUD_REGION)

	@echo "🚀 Creating container app environment: $(APP_ENV_NAME)"
	@az containerapp env create --name $(APP_ENV_NAME) --resource-group $(RESOURCE_GROUP) --location $(CLOUD_REGION)

	@echo "🚀 Fetching subscription ID"
	@subscription_id=$$(az account show --query "id" -o tsv) && \
	echo "Subscription ID: $$subscription_id" && \
	echo "🚀 Creating service principal for: $(APP_NAME)" && \
	az ad sp create-for-rbac --name "$(APP_NAME)-service-principal" --role contributor --scopes /subscriptions/$$subscription_id --sdk-auth

	@echo "🚀 Creating container app: $(APP_NAME)"
	@az containerapp create --name $(APP_NAME) --resource-group $(RESOURCE_GROUP) --environment $(APP_ENV_NAME) --image 'nginx:latest' --target-port 80 --ingress 'external' --query "properties.configuration.ingress.fqdn"

.PHONY: delete-env
delete-env: ## Delete resource group, container app environment, and service principal
	@echo "🚀 Deleting service principal for: $(APP_NAME)-service-principal"
	@sp_object_id=$$(az ad sp list --display-name "$(APP_NAME)-service-principal" --query "[0].id" -o tsv) && \
	if [ -n "$$sp_object_id" ]; then \
		az ad sp delete --id $$sp_object_id; \
		echo "Service principal deleted"; \
	else \
		echo "Service principal not found, skipping deletion"; \
	fi

	@echo "🚀 Deleting container app: $(APP_NAME)"
	@az containerapp delete --name $(APP_NAME) --resource-group $(RESOURCE_GROUP) --yes --no-wait || echo "Container app not found, skipping deletion"

	@echo "🚀 Deleting container app environment: $(APP_ENV_NAME)"
	@az containerapp env delete --name $(APP_ENV_NAME) --resource-group $(RESOURCE_GROUP) --yes --no-wait || echo "Container app environment not found, skipping deletion"

	@echo "🚀 Deleting resource group: $(RESOURCE_GROUP)"
	@az group delete --name $(RESOURCE_GROUP) --yes --no-wait || echo "Resource group not found, skipping deletion"

.PHONY: dvc-init
dvc-init: ## Initialize DVC and set up service account
	@echo "Initializing the DVC"
	@poetry run dvc init -f

	@echo "Adding remote connection to the Gdrive"
	@poetry run dvc remote add -d gdrive_remote gdrive://$(FOLDER_ID)
	@poetry run dvc remote modify gdrive_remote gdrive_use_service_account true

	@echo "Enabling Google Drive API"
	@gcloud services enable drive.googleapis.com --project $(GCLOUD_PROJECT_ID)

	@echo "Creating the Service Account"
	@gcloud iam service-accounts create $(SERVICE_ACCOUNT_NAME) \
	  --description="Service account for DVC to push data to Google Drive" \
	  --display-name="DVC Service Account" || echo "$(SERVICE_ACCOUNT_NAME) service account already created."

	@echo "Adding IAM Policy Bindings"
	@gcloud projects add-iam-policy-binding $(GCLOUD_PROJECT_ID) \
	  --member="serviceAccount:$(SERVICE_ACCOUNT_NAME)@$(GCLOUD_PROJECT_ID).iam.gserviceaccount.com" \
	  --role="roles/iam.serviceAccountUser"

	@echo "Creating Service Account Key"
	@gcloud iam service-accounts keys create ./.dvc/dvc-service-account-key.json \
	  --iam-account="$(SERVICE_ACCOUNT_NAME)@$(GCLOUD_PROJECT_ID).iam.gserviceaccount.com"

	@echo "Configuring DVC with Service Account Key"
	@poetry run dvc remote modify gdrive_remote gdrive_service_account_json_file_path ./.dvc/dvc-service-account-key.json

	@echo "Successfully added remote link."

.PHONY: dvc-cleanup
dvc-cleanup: ## Clean up DVC and service account
	@echo "Removing DVC remote"
	@poetry run dvc remote remove gdrive_remote || true

	@echo "Deleting Service Account Keys"
	@if [ -f ./.dvc/dvc-service-account-key.json ]; then \
		gcloud iam service-accounts keys delete \
		$$(gcloud iam service-accounts keys list \
			--iam-account="$(SERVICE_ACCOUNT_NAME)@$(GCLOUD_PROJECT_ID).iam.gserviceaccount.com" \
			--format="value(name)" | head -n 1) \
		--iam-account="$(SERVICE_ACCOUNT_NAME)@$(GCLOUD_PROJECT_ID).iam.gserviceaccount.com" -q || true; \
		rm -f ./.dvc/dvc-service-account-key.json; \
	fi

	@echo "Removing IAM Policy Bindings"
	@gcloud projects remove-iam-policy-binding $(GCLOUD_PROJECT_ID) \
		--member="serviceAccount:$(SERVICE_ACCOUNT_NAME)@$(GCLOUD_PROJECT_ID).iam.gserviceaccount.com" \
		--role="roles/iam.serviceAccountUser" || true

	@echo "Deleting Service Account"
	@gcloud iam service-accounts delete \
		"$(SERVICE_ACCOUNT_NAME)@$(GCLOUD_PROJECT_ID).iam.gserviceaccount.com" -q || true

	@echo "Disabling Google Drive API"
	@gcloud services disable drive.googleapis.com --project $(GCLOUD_PROJECT_ID) || true

	@echo "Removing DVC initialization"
	@rm -rf .dvc

	@echo "Cleanup complete"

# =============================
# Code Quality and Testing
# =============================
.PHONY: check
check: ## Run code quality tools
	@echo "🚀 Checking Poetry lock file consistency with 'pyproject.toml'"
	@poetry check --lock
	@echo "🚀 Linting code with pre-commit"
	@poetry run pre-commit run -a
	@echo "🚀 Static type checking with mypy"
	@poetry run mypy
	@echo "🚀 Checking for obsolete dependencies with deptry"
	@poetry run deptry .

.PHONY: test
test: ## Run tests with pytest
	@echo "🚀 Running tests with pytest"
	@poetry run pytest --cov --cov-config=pyproject.toml --cov-report=xml

# =============================
# Build and Release
# =============================
.PHONY: build
build: clean-build ## Build wheel file using poetry
	@echo "🚀 Creating wheel file"
	@poetry build

.PHONY: clean-build
clean-build: ## Clean build artifacts
	@rm -rf dist

.PHONY: publish
publish: ## Publish a release to PyPI
	@echo "🚀 Publishing: Dry run"
	@poetry config pypi-token.pypi $(PYPI_TOKEN)
	@poetry publish --dry-run
	@echo "🚀 Publishing"
	@poetry publish

.PHONY: build-and-publish
build-and-publish: build publish ## Build and publish to PyPI

.PHONY: update
update: ## Update project dependencies
	@echo "🚀 Updating project dependencies"
	@poetry update
	@poetry run pre-commit install --overwrite
	@echo "Dependencies updated successfully"

# =============================
# Run and Documentation
# =============================
.PHONY: run
run: ## Run the project's main application
	@echo "🚀 Running the project"
	@poetry run python $(PROJECT_SLUG)/main.py

.PHONY: docs-test
docs-test: ## Test if documentation can be built without warnings or errors
	@poetry run mkdocs build -s

.PHONY: docs
docs: ## Build and serve the documentation
	@poetry run mkdocs serve

# =============================
# Docker
# =============================
.PHONY: docker-build
docker-build: ## Build Docker image
	@echo "🚀 Building Docker image"
	docker build -t $(IMAGE_NAME):$(TAG) -f Dockerfile .

.PHONY: docker-push
docker-push: ## Push Docker image to Docker Hub
	@echo "🚀 Pushing Docker image to Docker Hub"
	docker push $(IMAGE_NAME):$(TAG)

.PHONY: docker-build-and-push
docker-build-and-push: docker-build docker-push ## Build and push Docker image to Docker Hub

.PHONY: clean-docker
clean-docker: ## Clean up Docker resources related to the app
	@echo "🚀 Deleting Docker image for app: $(IMAGE_NAME)"
	@docker images $(IMAGE_NAME) --format "{{.Repository}}:{{.Tag}}" | xargs -r docker rmi -f || echo "No image to delete"

	@echo "🚀 Deleting unused Docker volumes"
	@docker volume ls -qf dangling=true | xargs -r docker volume rm || echo "No unused volumes to delete"

	@echo "🚀 Deleting unused Docker networks"
	@docker network ls -q --filter "dangling=true" | xargs -r docker network rm || echo "No unused networks to delete"

	@echo "🚀 Cleaning up stopped containers"
	@docker ps -aq --filter "status=exited" | xargs -r docker rm || echo "No stopped containers to clean up"

# =============================
# DVC Operations
# =============================
.PHONY: add-data
add-data: ## Add a data file to DVC and Git, and enable autostage in DVC
	@echo "Adding $(DATA_FILENAME) to DVC tracking..."
	@poetry run dvc add artifacts/$(DATA_FILENAME) || true
	@echo "Staging DVC changes for $(DATA_FILENAME) to Git..."
	@git add artifacts/.gitignore || true
	@git add artifacts/$(DATA_FILENAME) || true
	@echo "Commiting DVC changes for $(DATA_FILENAME) to Git..."
	@git commit -m "Added $(DATA_FILENAME) to DVC and Git"
	@echo "Enabling DVC autostage..."
	@poetry run dvc config core.autostage true
	@echo "Successfully added $(DATA_FILENAME) to DVC and Git."

.PHONY: push-data
push-data: ## Push changes to Git
	@echo "Pushing changes to DVC remote..."
	@poetry run dvc push

pull-data: ## Push changes to Git
	@echo "Pulling changes from DVC remote..."
	@poetry run dvc pull --allow-missing


run-dvc-pipeline: ## Run DVC pipeline
	@echo "Running DVC pipeline..."
	@poetry run dvc repro
	@echo "Pipeline completed"


# =============================
# Debug
# =============================

.PHONY: print-dependency-tree
print-dependency-tree: ## Initialize DVC and set up service account
	@echo "Printing dependency tree..."
	@poetry run pipdeptree -p $(PACKAGE_NAME)


# =============================
# Cleanup
# =============================
.PHONY: cleanup-local
cleanup-local: clean-build clean-docker ## Clean up temporary files and directories and destroy the virtual environment, Docker image from your local machine
	@echo "🚀 Cleaning up temporary files and directories"
	@rm -rf .pytest_cache || true
	@rm -rf dist || true
	@rm -rf build || true
	@rm -rf htmlcov || true
	@rm -rf .venv || true
	@rm -rf .mypy_cache || true
	@rm -rf site || true
	@find . -type d -name "__pycache__" -exec rm -rf {} + || true
	@rm -rf .ruff_cache || true
	@echo "🚀 Clean up completed."

.PHONY: cleanup-all
cleanup-all: cleanup-local dvc-cleanup delete-env ## Clean up temporary files and directories and destroy the virtual environment, Docker image, and Cloud resources
