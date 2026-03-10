# Terraform Module — Yandex Cloud VM

Модуль разворачивает инфраструктуру в Yandex Cloud: виртуальную сеть, подсеть, загрузочный диск и одну или несколько compute-инстанций на базе Ubuntu 20.04 LTS.

---

## Что делает модуль

- Создаёт VPC-сеть и подсеть (`192.168.10.0/24`) для указанного окружения
- Создаёт загрузочный диск типа `network-ssd` на базе образа `ubuntu-2004-lts`
- Запускает `N` compute-инстанций (`standard-v2`) с NAT и SSH-доступом

---

## Параметры (Input Variables)

| Переменная | Тип | Описание |
|---|---|---|
| `env_name` | `string` | Имя окружения (`dev`, `stage`, `prod`). Используется как префикс для всех ресурсов |
| `cloud_id` | `string` | ID облака в Yandex Cloud |
| `folder_id` | `string` | ID каталога в Yandex Cloud |
| `zone` | `string` | Зона доступности (например, `ru-central1-d`) |
| `cores` | `number` | Количество vCPU для каждой инстанции |
| `memory` | `number` | Объём RAM в ГБ для каждой инстанции |
| `disk_size` | `number` | Размер загрузочного диска в ГБ |
| `instance_count` | `number` | Количество создаваемых инстанций |

---

## Выходные значения (Outputs)

| Output | Тип | Описание |
|---|---|---|
| `vm_external_ip` | `list(string)` | Список внешних (NAT) IP-адресов всех созданных инстанций |
| `vm_name` | `list(string)` | Список имён инстанций в формате `<env_name>-app-<index>` |
| `vm_id` | `list(string)` | Список ID инстанций в Yandex Cloud |

---

## Структура проекта

```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── modules/
│   └── vm/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── envs/
    ├── dev/
    │   └── terraform.tfvars
    ├── stage/
    │   └── terraform.tfvars
    └── prod/
        └── terraform.tfvars
```

---

## Запуск

### 1. Получить список сервисных аккаунтов

```shell
yc iam service-account list
```

### 2. Экспортировать переменные окружения

```shell
export YC_TOKEN=$(yc iam create-token --impersonate-service-account-id <service_account_id>)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
export TF_VAR_ssh_pub_key_path=<public_key_path>
```

### 3. Инициализировать и применить конфигурацию

Укажите нужное окружение вместо `<env>`:

```shell
# dev
terraform init && terraform apply -var-file=./envs/dev/terraform.tfvars

# stage
terraform init && terraform apply -var-file=./envs/stage/terraform.tfvars

# prod
terraform init && terraform apply -var-file=./envs/prod/terraform.tfvars
```

---

## Требования

| Инструмент | Версия |
|---|---|
| Terraform | `>= 0.13` |
| Provider `yandex-cloud/yandex` | последняя совместимая |
| Yandex CLI (`yc`) | любая актуальная |

