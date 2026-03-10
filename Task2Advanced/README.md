# Terraform CI/CD — Yandex Cloud + MinIO + GitLab

Проект разворачивает инфраструктуру в Yandex Cloud через CI/CD-пайплайн с удалённым хранением Terraform state в S3-совместимом хранилище (MinIO).


**Ключевые принципы:**
- State хранится удалённо в MinIO (S3-совместимый backend), не локально
- Секреты передаются через CI/CD Variables, не хранятся в коде
- `terraform apply` выполняется только по ручному подтверждению
- Окружения (dev/stage/prod) изолированы — у каждого свой state-файл

---

## Что создаёт модуль Terraform

- VPC-сеть и подсеть (`192.168.10.0/24`) для указанного окружения
- Загрузочный диск типа `network-ssd` на базе образа `ubuntu-2004-lts`
- N compute-инстанций (`standard-v2`) с NAT и SSH-доступом

---

## Структура проекта

```
.
├── .gitlab-ci.yml              # CI/CD-пайплайн 
├── backend.tf                  # S3-backend + provider 
├── main.tf                     # Корневой модуль — вызов modules/vm
├── variables.tf                # Входные переменные корневого модуля
├── outputs.tf                  # Выходные значения
├── docker-compose.yml          # MinIO (S3-хранилище для state)
├── README.md
├── modules/
│   └── vm/
│       ├── main.tf             # Ресурсы: сеть, диск, инстанции
│       ├── variables.tf
│       └── outputs.tf
└── envs/
    ├── dev/
    │   ├── terraform.tfvars    # Параметры инфраструктуры
    │   └── dev.tfbackend       # Параметры backend (bucket, key)
    ├── stage/
    │   ├── terraform.tfvars
    │   └── stage.tfbackend
    └── prod/
        ├── terraform.tfvars
        └── prod.tfbackend
```

---

## Удалённое хранение состояния (S3 Backend)

State хранится в MinIO — S3-совместимом хранилище, запущенном в Docker.

### Как это работает

Файл `backend.tf` описывает S3-backend с флагами совместимости для MinIO:

```hcl
backend "s3" {
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_s3_checksum            = true
  skip_metadata_api_check     = true
  use_path_style              = true   # обязательно для MinIO
}
```

Конкретные параметры (bucket, key, endpoint, креды) **не указаны в коде** — они передаются через `.tfbackend` файлы и переменные окружения.

### Изоляция окружений

Каждое окружение хранит state в отдельном ключе внутри одного bucket:

| Окружение | Ключ в bucket |
|-----------|---------------|
| dev       | `dev/terraform.tfstate` |
| stage     | `stage/terraform.tfstate` |
| prod      | `prod/terraform.tfstate` |

Инициализация для конкретного окружения:

```bash
terraform init -reconfigure \
  -backend-config=./envs/dev/dev.tfbackend \
  -backend-config="endpoints={s3=\"http://localhost:9000\"}"
```

---

## CI/CD-пайплайн (.gitlab-ci.yml)

### Стадии

| Стадия | Что делает | Запуск |
|--------|-----------|--------|
| **validate** | `terraform fmt -check` + `terraform validate` | Автоматически |
| **plan** | `terraform plan` для каждого окружения (dev, stage, prod) | Автоматически |
| **apply** | `terraform apply` сохранённого плана | Вручную (кнопка ▶️) |

### Безопасность пайплайна

- **Секреты в CI/CD Variables** — `YC_TOKEN`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`. В коде секретов нет.
- **Ручной apply** — стадия apply имеет `when: manual`, применение инфраструктуры требует явного подтверждения через UI.
- **Plan → Apply** — план сохраняется в файл (`-out=plan.tfplan`) и передаётся как артефакт. Apply применяет именно этот план, а не пересчитывает.
- **Изоляция окружений** — каждое окружение имеет отдельный state и отдельную джобу.
- **`TF_IN_AUTOMATION=true`** — подавляет интерактивные подсказки Terraform.

### Переменные CI/CD

| Переменная | Описание | Флаги |
|------------|----------|-------|
| `AWS_ACCESS_KEY_ID` | Логин MinIO | Masked |
| `AWS_SECRET_ACCESS_KEY` | Пароль MinIO | Masked |
| `MINIO_ENDPOINT` | URL MinIO API (`http://localhost:9000`) | — |
| `YC_TOKEN` | IAM-токен Yandex Cloud | Masked, Protected |
| `YC_CLOUD_ID` | ID облака | — |
| `YC_FOLDER_ID` | ID каталога | — |
| `TF_VAR_ssh_pub_key_path` | Путь к SSH-ключу на Runner'е | — |

---

## Параметры инфраструктуры (terraform.tfvars)

| Переменная | Тип | Описание |
|------------|-----|----------|
| `env_name` | `string` | Имя окружения (dev, stage, prod) |
| `zone` | `string` | Зона доступности (например, `ru-central1-d`) |
| `cores` | `number` | Количество vCPU |
| `memory` | `number` | Объём RAM в ГБ |
| `disk_size` | `number` | Размер диска в ГБ |
| `instance_count` | `number` | Количество инстанций |

---

## Выходные значения (Outputs)

| Output | Описание |
|--------|----------|
| `vm_external_ip` | Внешние (NAT) IP-адреса инстанций |
| `vm_name` | Имена инстанций |
| `vm_id` | ID инстанций в Yandex Cloud |




