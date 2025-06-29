# VotingApp - Obligatorio 288126

---

1. Contexto y Objetivo del Proyecto
2. Organización del Proyecto
3. Deploy y configuración
4. Estrategia de ramificación para código de Aplicación
5. Estrategia de ramificación para código de Infraestructura
6. Planificación del Proyecto
7. Testing y Calidad
8. Quality Gates
9. Pipelines CI/CD
10. IaC (Infraestructura como código)
11. Arquitectura de Infraestructura desplegada
12. Serverless Lambda
13. Containerización y Despliegue
14. Observabilidad + Notificaciones SMTP
15. Decisiones de diseño importantes y lecciones aprendidas.

## 1. Contexto y Objetivo del Proyecto

Este proyecto aborda la modernización DevOps de una aplicación de votación electrónica (_VotingApp_) para resolver problemas críticos de despliegue, confiabilidad y calidad de servicio. La solución implementada transforma los procesos tradicionales en un enfoque basado en principios DevOps: integración y entrega continua, colaboración entre equipos, automatización e infraestructura como código.

Para llevar a cabo la infraestructura de la aplicación VotingApp, se eligieron las siguientes tecnologías:

| **Categoría**         | **Tecnología**            | **Descripción**                                                                  |
| --------------------- | ------------------------- | -------------------------------------------------------------------------------- |
| Repositorio de codigo | GitHub                    | Plataforma para alojar y gestionar el código fuente mediante repositorios Git.   |
| Planificacion         | Trello                    | Herramienta de gestión de tareas basada en tableros estilo Kanban.               |
| CI/CD                 | GitHub Actions            | Servicio de automatización para integrar y desplegar código de forma continua.   |
| Testing Funcional     | Postman                   | Plataforma para pruebas de APIs de manera automatizada.                          |
| Code Analyzer         | SonarCloud y Super Linter | Herramientas para análisis estático del código y aseguramiento de calidad.       |
| Control de versiones  | GIT                       | Sistema de control de versiones distribuido para seguimiento de cambios.         |
| Cloud                 | AWS                       | Plataforma de servicios en la nube para alojar y escalar aplicaciones.           |
| IaC                   | Terraform                 | Herramienta para definir infraestructura como código de forma declarativa.       |
| Serverless            | Lambda                    | Permite ejecutar código sin necesidad de aprovisionar ni administrar servidores. |
| Deploy                | ECR & EKS - Kuberentes    | Servicio administrado de Kubernetes para desplegar, gestionar y escalar apps.    |
| Observabilidad        | CloudWatch                | Servicio de monitoreo de AWS para recolectar métricas, logs y trazas.            |
| Documentacion         | Notion, Markdown, Draw.io | Herramientas para crear documentación estructurada y diagramas visuales.         |

---

## 2. Organizacion del Proyecto

Para la gestión del código fuente y control de versiones se utilizó **GitHub** como plataforma principal. Esta elección facilitó la integración con pipelines de CI/CD, el control de cambios, y la trazabilidad del desarrollo.

Se optó por una arquitectura de múltiples repositorios, donde cada componente del sistema se encuentra desacoplado y contenido en su propio repositorio:

- `voting.result`: Contiene Codigo fuente de la app, manifiesto deploy k8, dockerfile, test unitarios y pipelines.
- `voting.vote`: Contiene Codigo fuente de la app, manifiesto deploy k8, dockerfile, test unitarios y pipelines.
- `voting.worker`: Contiene Codigo fuente de la app, manifiesto deploy k8, dockerfile, test unitarios y pipelines.
- `voting.infra`: Contiene la infraestructura como código (IaC), workflows que se pueden reutilizar entre los repositorios de aplicacion, asi como manifiestos genericos de k8.

![gh-org.png](/imgs/gh-org.png)

Estos repositorios van a estar todos unidos dentro de una organizacion de GitHub, lo cual esto va a permitir una correcta comunicacion entre repositorios, asi como una buena reutilizacion de secretos globales que van a compartir todos los repositorios.

La decisión de utilizar un repositorio por servicio se fundamenta en varias razones:

- **Modularidad y separación de responsabilidades**: Cada servicio puede evolucionar de forma independiente, permitiendo un mantenimiento más claro y ágil.
- **Especialización tecnológica**: Cada servicio fue desarrollado con tecnologías distintas, lo cual permite personalizar los pipelines de CI/CD según las necesidades particulares de cada stack.
- **Escalabilidad**: Facilita la ampliación o el reemplazo de componentes individuales sin afectar el resto del sistema.

![gh-diagram.png](/imgs/gh-diagram.png)

---

## 3. Deploy y configuracion

Para que los pipelines de cada servicio funcionen correctamente, va a ser necesario configurar el entorno en donde estos trabajan. en este caso en una organizacion de github junto con los repositorios.

A nivel de organizacion va a ser necesario dar un valor a los siguientes secretos:

- _AWS_SECRET_ACCESS_KEY → Llave de acceso de AWS._
- _AWS_SESSION_TOKEN → Token de sesion de AWS._
- _AWS_ACCESS_KEY_ID → Id de llave de acceso de AWS._
- _AWS_ACCOUNT_ID → Id de cuenta de AWS._
- _AWS_REGION → Region de AWS en la que se va a trabajar._
- _GMAIL_USERNAME → Username gmail to receive notify emails._
- _GMAIL_APP_PASSWORD → Smtp password._
- _SMTP_SERVER_ADDRESS → Smtp server._
- _SMTP_SERVER_PORT → Smtp server port._

\***\* Estos secretos de organizacion van a ser compartidos por cada repositorio de aplicacion individual.**

A nivel de repositorio individual, va a ser necesario dar un valor a los siguientes secretos:

- _ECR_REPOSITORY → ECR en donde se va a almacenar la imagen de la aplicacion construida._
- _SONAR_ORGANIZATION → Organizacion de SonarCloud para analsis de codigo._
- _SONAR_PROJECT_KEY → LLave de proyecto de SonarCloud para analisis de codigo._
- _SONAR_TOKEN → Token de SonarCloud para analisis de codigo._

Con esto configurado, el paso siguiente es desplegar los siguientes servicios:

![services.png](/imgs/services.png)

- **Vote**: Python que permite votar entre dos opciones
- **Worker**: .NET que consume los votos del cache y los guarda en la base de datos.
- **Result:** Node.js que muestra los resultados de la votación en tiempo real
- **Cache:** Redis que recoge los nuevos votos.
- **Db:** Postgres respaldada por un volumen Docker

---

**Deploy Local:**

Requisitos previos:

- **Docker Desktop** (Mac/Windows), que incluye Docker Compose.
- En **Linux**, tener instalados Docker y la última versión de Docker Compose.

Ejecutar containers:

1. Abre una terminal y sitúate en la carpeta raíz del proyecto (donde está el `docker-compose.yml`).
2. Ejecuta: `docker compose up`

Esto construirá las imágenes (si es la primera vez) y levantará todos los servicios.

1. Accede en tu navegador a:
   - **Aplicación de votación**: [http://localhost:8080](http://localhost:8080/)
   - **Resultados**: [http://localhost:8081](http://localhost:8081/)

---

**Deploy Cloud:**

Requisitos previos:

- Tener configurado todos los secretos de los repositorios y organizacion, los cuales se mostraron anteriormente en este punto.

Ejecutar containers:

1. Crear un bucket S3 llamado ‘voting.backend’ para guardar el estado de la infraestructura que deployaremos con terraform aplicando IaC.
2. Ejecutar Pipeline de Infraestructura, esto hara que se deployee la infraestructura en el provider de AWS. Junto con el apply inicial de manifiestos en cada cluster de EKS (dev,test,prod).
3. Por cada aplicacion, ejecutar el pipeline de ci-cd en el entorno requerido. Esto hara que se buildee la aplicacion junto con la imagen de docker y se despliegue a un ECR. Luego actualizara el manifiesto de deployment dentro del cluster.

Esto construirá toda la infraestructura necesaria para levantar la aplicacion en sus 3 ambientes, los cuales son dev, test y prod. Ambos entornos seran accesibles desde una url que les dara el NLB de AWS.

---

## 4. Estrategia de ramificacion para codigo de Aplicacion

A continuación se detalla paso a paso el flujo de trabajo basado en Git Flow, adaptado a nuestros tres entornos (Dev, Test y Prod) para los repositorios `voting.result`, `voting.vote` y `voting.worker`. Sigue cuidadosamente cada paso para mantener la coherencia y la calidad en todo el ciclo de vida del código.

- **`dev`**
  Es la rama de integración continua. Aquí convergen todas las _feature branches_ una vez finalizadas y revisadas. El pipeline de CI compila, ejecuta tests unitarios y de integración, y despliega automáticamente a un entorno de desarrollo.
- **`test`**
  Rama para validación en entorno de QA. Se alimenta únicamente desde _release branches_. Tras aprobarse, se prepara el paquete para producción.
- **`prod`**
  Representa el código que está en producción. Solo recibe merges desde las _hotfix branches_ o desde _release branches_ totalmente verificadas. Cada commit en `prod` debe ir acompañado de un tag semántico (p.ej. `v1.2.3`) y dispara el pipeline de despliegue a producción.

1. **Feature branches**
   - **Origen:** siempre desde `dev`.
   - **Naming:** `feature/<name>`
   - **Ciclo de vida:**
     1. Desarrollar la funcionalidad, commits atómicos y claros.
     2. Push y abrir Pull Request (PR) hacia `dev`.
     3. Código revisado (code review), aprobar y hacer merge _squash_ o _rebase_ según convención.
     4. Una vez mergeada, cerrar la rama remota y local:
2. **Release branches**
   - **Origen:** siempre desde `dev`, cuando se van a preparar versiones para `Testing`
   - **Naming:** `release/vX.Y.Z`
   - **Ciclo de vida:**
     1. Crear en el momento de “code freeze” para la siguiente versión.
     2. Abrir PR hacia `test`. Una vez aprobado y mergeado en `test`, se ejecutan pruebas de QA.
     3. Cuando `release/v1.2.0` pasa QA, hacer merge **doble**:
        - Merge a `prod` y etiquetar con `v1.2.0`:
        - Merge a `dev` para llevar hacia adelante cualquier corrección de última hora:
     4. Borrar la rama de release ya que ya cumplio su funcion.
3. **Hotfix branches**
   - **Origen:** siempre desde `prod`, para reaccionar ante incidencias críticas en producción.
   - **Naming:** `hotfix/vX.Y.Z+1` (p.ej., si estamos en v1.2.0, hotfix/v1.2.1)
   - **Ciclo de vida:**
     1. Corregir el fallo crítico y commitear.
     2. Abrir PR hacia `prod`. Tras aprobación:
     3. Fusionar también en `dev` y (si existe) en la rama de release activa:
     4. Eliminar rama.

![gitflow-diagram.png](/imgs/gitflow-diagram.png)

---

## 5. Estrategia de ramificacion para codigo de Infraestructura

Se utilizó la estrategia de **_feature branch_** para gestionar los cambios en el código de infraestructura.

Cada nuevo cambio (ya sea una funcionalidad, mejora o corrección) se desarrolla en una rama independiente creada a partir de `prod`. Una vez finalizado, se crea un Pull Request para revisión antes de integrar los cambios a la rama principal.

En base a esto, nos beneficiamos de:

- **Aislamiento de cambios**: Reduce el riesgo de afectar el entorno principal.
- **Mejor colaboración**: Permite que varios desarrolladores trabajen en paralelo.
- **Control y trazabilidad**: Los cambios se revisan y documentan antes de aplicarse.

![featurebranch-diagram.png](/imgs/featurebranch-diagram.png)

---

## 6. Planificación del Proyecto

Para la planificación, organización y seguimiento de tareas del proyecto, se utilizó **Trello**, implementando una metodología visual basada en **Kanban**. Esta herramienta permitió una gestión clara del estado de cada actividad, fomentando la colaboración y visibilidad del progreso en tiempo real.

`Backlog` → `To Do` → `In Progress` → `Blocked` → `Review` → `Done`

El flujo de trabajo se estructuró con los siguientes estados:

- **Backlog**: Contiene todas las ideas, tareas pendientes y funcionalidades a desarrollar en el futuro. Actúa como una lista priorizada desde donde se seleccionan las tareas para iniciar.
- **To Do**: Tareas que han sido priorizadas y están listas para ser trabajadas en el corto plazo. Indica el siguiente conjunto de acciones a tomar por el equipo.
- **In Progress**: Tareas en las que alguien ya está trabajando activamente. Aquí se concentra el trabajo en curso.
- **Blocked**: Tareas que no pueden avanzar por alguna razón externa o interna (dependencias, errores, falta de información, etc.). Este estado permite identificar rápidamente cuellos de botella.
- **Review**: Tareas finalizadas a nivel técnico, pero que requieren revisión por parte de otro miembro del equipo (por ejemplo, revisión de código, validación funcional o aprobación de cambios).
- **Done**: Tareas completamente terminadas, revisadas y validadas. No requieren más accione

Inicio del proyecto:

![trello 1.png](/imgs/trello_1.png)

Mitad del proyecto:

![trello 2.png](/imgs/trello_2.png)

Final del proyecto:

![trello 3.png](/imgs/trello_3.png)

---

## 7. Testing y Calidad

Se utilizó **SonarCloud** como herramienta de análisis de código estático en cada uno de los repositorios del proyecto para los 3 ambientes. Esta elección se basó en su capacidad para detectar de forma automática vulnerabilidades, malas prácticas, código duplicado, y otros indicadores de deuda técnica. El análisis se integró en los pipelines de CI, permitiendo recibir retroalimentación inmediata tras cada _push_ o _pull request_.

Ademas, en cada pipeline se agrego un Linter llamado Super-Linter el cual va a checkear codigo nuevo que se quiera agregar al repo.

![sonarcloud.jpg](/imgs/sonarcloud.jpg)

Ademas, en los repositorios `voting.result` y `voting.vote` se implementaron pruebas automatizadas de los endpoints usando **Postman**. Estas pruebas se ejecutan una vez que los servicios son desplegados en un entorno controlado.

Esto permitió verificar de forma automatizada la disponibilidad y el correcto funcionamiento de las rutas expuestas por cada API. Sin embargo, este enfoque **no garantiza** la ausencia total de errores, ya que:

- Las pruebas están limitadas a los casos definidos en los _collections_ de Postman.
- No se cubren casos extremos, condiciones inesperadas ni pruebas de carga.
- No reemplaza la necesidad de pruebas unitarias ni de integración más exhaustivas.

---

**Informe de calidad en voting.result:**

![result-analisis.png](/imgs/result-analisis.png)

- El análisis con **SonarCloud** reveló varios problemas críticos, siendo el más grave la exposición de una **contraseña de base de datos** en `server.js`, lo que representa un serio riesgo de seguridad. Es fundamental eliminar esta credencial del código y utilizar variables de entorno.
- A nivel de código, se detectó el uso repetido de `var` en lugar de `let` o `const` en múltiples archivos. Esta práctica obsoleta compromete la claridad y el comportamiento esperado del código. Aunque fácil de corregir, su impacto en la mantenibilidad es alto.

Se recomienda actuar con urgencia sobre el tema de seguridad, refactorizar el uso de `var`, Estos cambios mejorarán la seguridad, legibilidad y mantenimiento del proyecto sin requerir un esfuerzo significativo.

---

**Informe de calidad en voting.vote:**

![vote-analisis.png](/imgs/vote-analisis.png)

- El análisis con **SonarCloud** detectó la **falta de límites y solicitudes de recursos (CPU, memoria y almacenamiento)** para el contenedor. Esto impide que el clúster de Kubernetes pueda hacer un uso eficiente de los recursos y puede derivar en comportamientos impredecibles o problemas de estabilidad bajo carga.
- En cuanto al frontend, persisten problemas menores de accesibilidad y estilo. El archivo `index.html` no especifica el atributo `lang`, lo cual afecta a usuarios con tecnologías de asistencia. En `style.css`, falta una fuente genérica en las reglas de `font-family`, lo que puede causar inconsistencias visuales entre plataformas.

Aunque no se identificaron vulnerabilidades críticas, el repositorio `voting.vote` presenta varias **mejoras importantes en la configuración de Contenedores** que deben atenderse para reforzar la seguridad y confiabilidad del despliegue. Las correcciones en accesibilidad y estilo son simples, pero valiosas para ofrecer una experiencia más robusta y profesional.

---

**Informe de calidad en voting.worker:**

![worker-analisis.png](/imgs/worker-analisis.png)

- El análisis de **SonarCloud** en el repositorio `voting.worker` reveló varias oportunidades de mejora tanto en el `Dockerfile` como en la configuración de despliegue de Kubernetes.
- En el `Dockerfile`, se detectaron dos advertencias donde variables de entorno no están entrecomilladas correctamente en las líneas 19 y 22. Esta omisión puede provocar errores en tiempo de ejecución si los valores contienen espacios u otros caracteres especiales, afectando la portabilidad y confiabilidad del script.
- Respecto al archivo `worker-deployment.yaml`, se encontraron configuraciones incompletas en el contenedor. Faltan **límites y solicitudes de recursos (CPU, memoria y almacenamiento).**

El repositorio `voting.worker` no presenta fallas críticas, pero sí varios aspectos importantes que deben corregirse para garantizar un entorno más seguro, predecible y mantenible. Se recomienda actualizar el `Dockerfile` para asegurar buenas prácticas en el manejo de variables y completar la definición de recursos y permisos en Kubernetes, fortaleciendo así la confiabilidad y seguridad del despliegue.

---

## 8. Quality Gates

Dentro de los _pipelines_ definidos para cada aplicación, se establecieron distintos **quality gates** con el objetivo de determinar si la ejecución del pipeline es exitosa o no. Estos controles nos permiten asegurar la calidad del código y del servicio antes de proceder con una integración o despliegue.

**SonarCloud:**

Se configuró un **quality gate** en SonarCloud que realiza un análisis estático del código. En caso de que se detecten problemas que incumplen con las reglas definidas, el análisis fallará y se dejará un comentario automático en el _pull request_ correspondiente. Esto permite tomar decisiones informadas antes de realizar el _merge_.

**Testing Automatizado Postman:**

En los tests automatizados realizados con Postman, se estableció como **quality gate** que todas las respuestas del servicio deben retornar un **código HTTP 200**. Si alguna respuesta difiere de este valor, el pipeline fallará automáticamente, evitando la promoción de servicios con errores de ejecución.

![quality-gate-1.png](/imgs/quality-gate-1.png)

![quality-gate-2.png](/imgs/quality-gate-2.png)

---

## 9. Pipelines CI/CD

Para garantizar la entrega continua y automatizada de **VotingApp**, se crearon pipelines de **GitHub Actions** independientes para cada repositorio.

Para garantizar la entrega continua y automatizada de **VotingApp**, se crearon pipelines de **GitHub Actions** independientes para cada repositorio, alineados con la estrategia de ramas (`dev` → `test` → `prod`).

Cada pipeline está dividido en dos grandes etapas:

- **Integración Continua (CI):**
  - Checkout del código y configuración del entorno (runtime, credenciales).
  - Análisis estático con **Super-Linter** y **SonarCloud** (quality gates).
  - Ejecución de **tests unitarios.**
  - Compilación de la aplicación.
  - Construcción y etiquetado semántico de la **imagen Docker**, y push al repositorio **AWS ECR**.
- **Entrega Continua (CD):**
  - Actualización de la configuración de acceso a los clusters de **EKS** (dev, test, prod).
  - Despliegue automático de los manifiestos Kubernetes (`kubectl apply` o Helm).
  - Notificaciones de éxito/fallo (email SMTP o Slack) y, en el caso de la infraestructura, conteo de imágenes mediante Lambda y envío de un resumen al equipo.
  - Se prueba que el deploy haya sido correcto usando testing automatizado con Postman.
  -

A continuación se muestram, para cada repositorio, los disparadores y particularidades de su flujo

![gh-cicd-diagrams.png](/imgs/gh-cicd-diagrams.png)

**Pipeline Voting.Infra:**

![infra-gh.png](/imgs/infra-gh.png)

Este pipeline se dispara manualmente o cada vez que se abre un pull request o se hace push a la rama prod, asegurándose de que no haya ejecuciones simultáneas sobre la misma referencia. Primero extrae el código, configura las credenciales de AWS y ejecuta Terraform para inicializar el backend, comprobar el formato y la validez de la configuración, generar el plan de cambios y aplicar automáticamente las modificaciones en la infraestructura si procede.

A continuación, con la misma configuración de credenciales, actualiza el acceso a los tres clusters de EKS (dev, test y prod) y sincroniza todos los manifiestos Kubernetes en cada uno de ellos. Una vez completado el despliegue, invoca una función Lambda para contar cuántas imágenes hay en los repositorios ECR de los servicios principales, ensambla un correo resumen con esos datos y lo envía automáticamente vía SMTP/Gmail al equipo de infraestructura.

**Pipeline Voting.Result:**

![result-gh.png](/imgs/result-gh.png)

Este pipeline se dispara manualmente (`workflow_dispatch`) o en cada `push` o `pull_request` a las ramas **dev**, **test** y **prod**, utilizando una configuración de concurrencia que cancela ejecuciones previas sobre la misma referencia. En la fase de **CI**, tras hacer checkout del código, se valida el estilo con **Super-Linter**, se ejecutan los **tests unitarios** (`npm test`) y se somete todo el código a un análisis de calidad en **SonarCloud**.

Cuando esos checks finalizan con éxito en un push, se invoca un workflow externo que construye y etiqueta la **imagen Docker** en ECR. A continuación, en la fase de **CD**, se despliega la aplicación al cluster de **EKS** correspondiente (según la rama) aplicando los manifiestos parametrizados. Una vez activo el servicio, se ejecutan pruebas de integración con **Newman** contra el endpoint expuesto. Finalmente, el pipeline genera y envía por SMTP/Gmail un email de notificación al equipo, indicando la rama, el commit y la fecha del despliegue.

**Pipeline Voting.Vote:**

![vote-gh.png](/imgs/vote-gh.png)

Este pipeline se dispara manualmente (`workflow_dispatch`) o en cada `push` o `pull_request` a las ramas **dev**, **test** y **prod**, utilizando concurrencia para cancelar ejecuciones previas en la misma referencia. En la fase de **CI**, tras hacer checkout del código con historial completo, se valida el estilo con **Super-Linter** y se somete todo a un análisis de calidad en **SonarCloud**; Cuando esos checks finalizan con éxito en un push, se invoca un workflow externo que construye y etiqueta la **imagen Docker** en ECR. A continuación, en la fase de **CD**, se despliega la aplicación al cluster de **EKS** correspondiente (según la rama) aplicando los manifiestos parametrizados. Una vez activo el servicio, se ejecutan pruebas de integración con **Newman** contra el endpoint expuesto. Finalmente, el pipeline genera y envía por SMTP/Gmail un email de notificación al equipo, indicando la rama, el commit y la fecha del despliegue.

**Pipeline Voting.Worker:**

![vote-gh.png](/imgs/vote-gh.png)

Este pipeline se dispara manualmente (`workflow_dispatch`) o en cada `push` o `pull_request` a las ramas **dev**, **test** y **prod**, con concurrencia que cancela ejecuciones previas sobre la misma referencia. En la fase de **CI**, tras hacer checkout con historial completo, se valida el estilo y convenciones con **Super-Linter** (incluyendo C#/.NET), se restaura y compila la solución, se ejecutan los **tests unitarios** (`dotnet test`) y se realiza un análisis de calidad en **SonarCloud**; Cuando esos checks finalizan con éxito en un push, se invoca un workflow externo que construye y etiqueta la **imagen Docker** en ECR. A continuación, en la fase de **CD**, se despliega la aplicación al cluster de **EKS** correspondiente (según la rama) aplicando los manifiestos parametrizados. Una vez activo el servicio, se ejecutan pruebas de integración con **Newman** contra el endpoint expuesto. Finalmente, el pipeline genera y envía por SMTP/Gmail un email de notificación al equipo, indicando la rama, el commit y la fecha del despliegue.

## 10. IaC (Infraestructura como codigo)

Para mantener la coherencia, reutilización y trazabilidad de los recursos en AWS, toda la capa de infraestructura de **VotingApp** se define y gestiona con **Terraform**, utilizando un backend remoto en S3 para centralizar el estado y facilitar el trabajo colaborativo. A continuación se describen los principales componentes, así como las razones de diseño:

**Backend y proveedor**

Se configuró el backend S3 `voting.backend` con bloqueo de estado en `terraform.tfstate` (región `us-east-1`).

Codigo principal:

```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "voting.backend"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
}

# ECR

module "voting_vote_ecr" {
  source      = "./modules/ecr"
  application = "voting_vote"
}

module "voting_result_ecr" {
  source      = "./modules/ecr"
  application = "voting_result"
}

module "voting_worker_ecr" {
  source      = "./modules/ecr"
  application = "voting_worker"
}

# Networks

module "voting_prod_network" {
  source               = "./modules/network"
  vpc_cidr             = "10.1.0.0/16"
  environment          = "prod"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnets       = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets      = ["10.1.101.0/24", "10.1.102.0/24"]
  enable_dns_support   = true
  enable_dns_hostnames = true
}

module "voting_test_network" {
  source               = "./modules/network"
  vpc_cidr             = "10.2.0.0/16"
  environment          = "test"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnets       = ["10.2.1.0/24", "10.2.2.0/24"]
  private_subnets      = ["10.2.101.0/24", "10.2.102.0/24"]
  enable_dns_support   = true
  enable_dns_hostnames = true
}

module "voting_dev_network" {
  source               = "./modules/network"
  vpc_cidr             = "10.3.0.0/16"
  environment          = "dev"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnets       = ["10.3.1.0/24", "10.3.2.0/24"]
  private_subnets      = ["10.3.101.0/24", "10.3.102.0/24"]
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# EKS

module "voting_prod_cluster_eks" {
  source             = "./modules/eks"
  environment        = "prod"
  region             = var.region
  public_subnet_ids  = module.voting_prod_network.public_subnet_ids
  private_subnet_ids = module.voting_prod_network.private_subnet_ids
  desired_size       = 2
  max_size           = 3
  min_size           = 1
  instance_types     = ["t3.small"]
}

module "voting_test_cluster_eks" {
  source             = "./modules/eks"
  environment        = "test"
  region             = var.region
  public_subnet_ids  = module.voting_test_network.public_subnet_ids
  private_subnet_ids = module.voting_test_network.private_subnet_ids
  desired_size       = 2
  max_size           = 3
  min_size           = 1
  instance_types     = ["t3.small"]
}

module "voting_dev_cluster_eks" {
  source             = "./modules/eks"
  environment        = "dev"
  region             = var.region
  public_subnet_ids  = module.voting_dev_network.public_subnet_ids
  private_subnet_ids = module.voting_dev_network.private_subnet_ids
  desired_size       = 2
  max_size           = 3
  min_size           = 1
  instance_types     = ["t3.small"]
}

# Lambda Prod

module "lambda" {
  source     = "./modules/lambda"
  region     = var.region
  ecr_worker = module.voting_worker_ecr.repository_name
  ecr_vote   = module.voting_vote_ecr.repository_name
  ecr_result = module.voting_result_ecr.repository_name
}

# Cloudwatch

module "cloudwatch" {
  source          = "./modules/cloudwatch"
  region          = var.region
  cluster_name    = module.voting_prod_cluster_eks.cluster_name
  node_group_name = module.voting_prod_cluster_eks.ng_name
  depends_on      = [module.voting_prod_cluster_eks]
}

```

Este código Terraform orquesta toda la infraestructura de AWS para **VotingApp** de forma declarativa y modular, desplegando:

- **Backend S3** (`voting.backend`) para almacenar el estado compartido.
- **Provider AWS** parametrizado por `var.region` para reutilizar la misma configuración en todos los entornos;
- **Repositorios ECR** (`voting_vote`, `voting_result`, `voting_worker`) mediante un módulo genérico, asegurando políticas uniformes y naming consistente;
- **Redes aisladas** por entorno (**prod**, **test**, **dev**), cada una en dos AZs con VPC, subredes públicas/privadas, Internet Gateway, NAT Gateway, tablas de ruta y grupos de seguridad, garantizando separación, seguridad y alta disponibilidad;
- **Clusters EKS** independientes para cada entorno, con node-groups configurables (tamaño mínimo, deseado y máximo) y tipos de instancia `t3.small`, optimizando coste/rendimiento;
- **Función Lambda** que consume los repositorios ECR y cuenta las imágenes, usada para alimentar notificaciones tras el despliegue;
- **CloudWatch**: dashboards dinámicos que muestran métricas de CPU y estado de los nodos EKS, junto a alarmas de SNS (alta CPU y status check fallidos) para alertas proactivas.

Se ha optado por una arquitectura **modular** para fomentar la reutilización y coherencia (todos los entornos usan los mismos módulos parametrizados), garantizar la **separación de entornos**, facilitar la **escalabilidad** (gracias a variables de tamaño y subredes) y asegurar **observabilidad** y **resiliencia** mediante múltiples AZs, subredes privadas y un completo set de métricas y alarmas.

Todos los nodos del cluster EKS fueron desplegados en subredes privadas, esto para garantizar una seguridad correcta para entornos productivos. Solamente se va a poder acceder a la aplicacion a traves de Load Balancers que estan en redes publicas. donde estos NLB van a ser creados por manifiestos de K8.

Toda esta infraestructura como codigo, una vez que se desplegue en el provedor de AWS vamos a tener los siguientes recursos:

VPCS por entorno:

![aws-vpc.png](/imgs/aws-vpc.png)

Subredes publicas y privadas por entorno.

![aws-subnets.png](/imgs/aws-subnets.png)

Bucket S3 para guardar el estado de terraform.

![aws-s3.png](/imgs/aws-s3.png)

Mapeo de una VPC, en este caso PROD.

![aws-rs-map.png](/imgs/aws-rs-map.png)

ECR por aplicacion para guardar las imagenes dev/test/prod.

![aws-ecrs.png](/imgs/aws-ecrs.png)

Un cluster EKS por entorno. en donde cada cluster va a tener sus node groups asociados.

![aws-eks.png](/imgs/aws-eks.png)

Node groups asociados, en este caso hace referencia a un cluster EKS de PROD

![aws-node-groups.png](/imgs/aws-node-groups.png)

Load balancers como unicos puntos de acceso a la VPC desde internet. Ya que como comentamos antes, todos los nodos estan ubicados en subredes privadas por seguridad.

![aws-loadbalancers.png](/imgs/aws-loadbalancers.png)

Dashboard de CloudWatch, donde se puede ver CPU del node group, asi como instancias que fallaron.

![aws-dashboard-cloudwatch.png](/imgs/aws-dashboard-cloudwatch.png)

Alertas de CloudWatch, en donde si supera el 80% del CPU o si alguna fallo, enviara un EMAIL avisando.

![aws-cloudwatch-alarms.png](/imgs/aws-cloudwatch-alarms.png)

Funcion lambda.

![aws-lambda.png](/imgs/aws-lambda.png)

Asi como tambien Security Groups, Internet Gateway, asociaciones, route tables, nat gateways…

Toda esta infraestructura nos va a permitir tener la app deployada en cada entorno:

- Deploy en Prod:

  ![deploy-prod.png](/imgs/deploy-prod.png)

  ![deploy-prod-2.png](/imgs/deploy-prod-2.png)

- Deploy en Test:

  ![deploy-test-2.png](/imgs/deploy-test-2.png)

  ![deploy-test.png](/imgs/deploy-test.png)

- Deploy en Dev:
  ![deploy-dev-2.png](/imgs/deploy-dev-2.png)
  ![deploy-dev.png](/imgs/deploy-dev.png)

## 11. Arquitectura de Infraestructura desplegada

En esta sección se muestra la arquitectura de la capa de infraestructura desplegada en AWS para **VotingApp**, separada en tres entornos (**dev**, **test**, **prod**). Cada componente y conexión ha sido diseñado para maximizar la disponibilidad, seguridad y escalabilidad.

Infraestructura global desplegada:

![aws-infra.png](/imgs/aws-infra.png)

VPC-PROD:

![aws-vpc-diagram-prod.png](/imgs/aws-vpc-diagram-prod.png)

VPC-TEST:

![aws-vpc-diagram-test.png](/imgs/aws-vpc-diagram-test.png)

VPC-DEV:

![aws-vpc-diagram-dev.png](/imgs/aws-vpc-diagram-dev.png)

ECRS+ S3 + Lambda + Cloudwatch:

![aws-extras-diagram.png](/imgs/aws-extras-diagram.png)

## 12. Serverless Lambda

Para externalizar y centralizar la lógica de consulta de imágenes en ECR, creamos una función **AWS Lambda** provisionada vía Terraform. Esta función recibe como parámetros (mediante variables de entorno) los nombres de los tres repositorios ECR de VotingApp (`voting_vote`, `voting_result`, `voting_worker`), y al invocarse escanea cada repositorio para contar cuántas imágenes contiene. El resultado se formatea como un JSON con el conteo por aplicación.

En los pipelines de CI/CD del repo de Infra, esta Lambda se invoca al final del despliegue de infraestructura: el workflow ejecuta un comando `aws lambda invoke`, recoge el payload con los recuentos y utiliza esos valores para construir automáticamente el cuerpo del email de notificación. Así, el pipeline no necesita implementar en Bash o JavaScript la lógica de llamada a ECR, sino que delega en un componente reutilizable.

Aqui se invoco la lambda en el pipeline para obtener los datos. Luego se utilizaron los datos dentro del email de deploy satifactorio.

![lambda-usage.png](/imgs/lambda-usage.png)

## 13. Containerización y Despliegue

En este apartado se describen los **Dockerfiles** de cada servicio, el flujo de **build & push** a **AWS ECR**, y el despliegue en **Amazon EKS** mediante manifiestos Kubernetes.

Docker Composel:

```
# version is now using "compose spec"
# v2 and v3 are now combined!
# docker-compose v1.27+ required
# infra/docker-compose.yml

version: "3.9" # Compose spec v2+ (docker-compose v1.27+)
services:
  vote:
    build:
      context: ../voting.vote
      target: dev
    depends_on:
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 15s
      timeout: 5s
      retries: 3
      start_period: 10s
    volumes:
      - ../voting.vote:/usr/local/app
    ports:
      - "8080:80"
    networks:
      - front-tier
      - back-tier

  result:
    build:
      context: ../voting.result
    entrypoint: nodemon --inspect=0.0.0.0 server.js
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ../result:/usr/local/app
    ports:
      - "8081:80"
      - "127.0.0.1:9229:9229"
    networks:
      - front-tier
      - back-tier

  worker:
    build:
      context: ../voting.worker
    depends_on:
      redis:
        condition: service_healthy
      db:
        condition: service_healthy
    networks:
      - back-tier

  redis:
    image: redis:alpine
    volumes:
      - ./healthchecks:/healthchecks
    healthcheck:
      test: /healthchecks/redis.sh
      interval: "5s"
    networks:
      - back-tier

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: "postgres"
      POSTGRES_PASSWORD: "postgres"
    volumes:
      - db-data:/var/lib/postgresql/data
      - ./healthchecks:/healthchecks
    healthcheck:
      test: /healthchecks/postgres.sh
      interval: "5s"
    networks:
      - back-tier

  seed:
    build: ./seed-data
    profiles: ["seed"]
    depends_on:
      vote:
        condition: service_healthy
    networks:
      - front-tier
    restart: "no"

volumes:
  db-data:

networks:
  front-tier:
  back-tier:
```

Dockerfile para Vote App:

```docker
# base defines a base stage that uses the official python runtime base image
FROM python:3.11-slim AS base

# Add curl for healthcheck
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Set the application directory
WORKDIR /usr/local/app

# Install our requirements.txt
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# dev defines a stage for development, where it'll watch for filesystem changes
FROM base AS dev
RUN pip install watchdog
ENV FLASK_ENV=development
CMD ["python", "app.py"]

# final defines the stage that will bundle the application for production
FROM base AS final

# Copy our code from the current folder to the working directory inside the container
COPY . .

# Make port 80 available for links and/or publish
EXPOSE 80

# Define our command to be run when launching the container
CMD ["gunicorn", "app:app", "-b", "0.0.0.0:80", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--keep-alive", "0"]

```

Dockerfile para Result App:

```docker
FROM node:18-slim

# add curl for healthcheck
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl tini && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/app

# have nodemon available for local dev use (file watching)
RUN npm install -g nodemon

COPY package*.json ./

RUN npm ci && \
 npm cache clean --force && \
 mv /usr/local/app/node_modules /node_modules

COPY . .

ENV PORT=80
EXPOSE 80

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "server.js"]

```

Dockerfile para Worker:

```docker
FROM --platform=${BUILDPLATFORM} mcr.microsoft.com/dotnet/sdk:7.0 AS build
ARG TARGETPLATFORM
ARG TARGETARCH
ARG BUILDPLATFORM
RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM"

WORKDIR /source
COPY *.csproj .
RUN dotnet restore -a $TARGETARCH

COPY . .
RUN dotnet publish -c release -o /app -a $TARGETARCH --self-contained false --no-restore

# app image
FROM mcr.microsoft.com/dotnet/runtime:7.0
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "Worker.dll"]
```

Estas imagenes una vez que se buildeen, se van a almacenar en el ECR correspondiente. Teniendo como precondicion que pase todo el flujo de CI.

Manifiestos de Kubernetes:

Dentro del repositorio de infra, se encontrara una carpeta llamda “./k8-specifications” que contendra los manifiestos “genericos” que se deployaran en el cluster correspondiente.

k8s-specifications/
├── db-deployment.yaml
├── db-service.yaml
├── redis-deployment.yaml
├── redis-service.yaml
├── result-service.yaml
├── vote-service.yaml
└── seed-data/

Asi mismo, cada repo tendra un archivo deployment que se utilizara para el deploy.

k8s-specifications/
├── deployment.yaml

El mismo contara con una estructura simlar a este, en donde se van a setear el AWS account id y Image tag dinamicamente.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: result
  name: result
spec:
  replicas: 1
  selector:
    matchLabels:
      app: result
  template:
    metadata:
      labels:
        app: result
    spec:
      containers:
        - image: __AWS_ACCOUNT_ID__.dkr.ecr.us-east-1.amazonaws.com/voting_result:__IMAGE_TAG__
          name: result
          ports:
            - containerPort: 80
              name: result
```

Estos manifiestos van a ser aplicados automaticamente en el cluster de EKS. gracias a los pipelines automaticos que tendremos en nuestro repositorio

## 14. Observabilidad + Notificaciones SMTP

Para garantizar visibilidad sobre el estado de los clusters y recibir avisos inmediatos tanto de alerta de infraestructura como de despliegues, combinamos **Amazon CloudWatch + SNS** para métricas y alarmas, con **notificaciones SMTP/Gmail** desde los pipelines de CI/CD.

Se crea un panel central en CloudWatch que agrupa las métricas clave de los nodos del cluster **de Produccion**(uso de CPU y fallos de estado).

**Alarmas basadas en umbrales**

- Definimos reglas críticas, como un **uso medio de CPU superior al 80 %** o **fallos de status check** en los nodos.
- Estas alarmas se agrupan a nivel de autoscaling group para minimizar el ruido y entender la salud global del cluster.

**Distribución de alertas con SNS**

- Cuando se incumple un umbral, la alarma dispara un mensaje a un **SNS Topic** específico de producción.
- El SNS, a su vez, notifica inmediatamente por correo electrónico al equipo de operaciones, cerrando el ciclo de detección y alerta.

![aws-cloudwatch-alarms.png](/imgs/aws-cloudwatch-alarms.png)

![aws-dashboard-cloudwatch.png](/imgs/aws-dashboard-cloudwatch.png)

Ademas, luego de cada deploy, tanto en los repositorios de Infraestructura como en los de aplicacion, se va a enviar un email indicando que el deploy fue satisfactorio, como un medio mas de observabilidad.

![emails.png](/imgs/emails.png)

Con esta combinación de **monitorización activa** (CloudWatch + SNS) y **notificaciones de despliegue** (SMTP/Gmail), el equipo de infraestructura y desarrollo recibe información proactiva y detallada sobre la salud del entorno y el estado de cada despliegue, permitiendo una respuesta ágil ante incidentes y una trazabilidad completa del ciclo de vida de **VotingApp**.

## 15. Decisiones de diseño importantes y lecciones aprendidas.

Decisiones de diseño:

- Se optio por organizar el codigo de la solucion implementada en 4 repositorios. Esto para llevar una solucion final mas modular y escalable, donde cada repositorio cumpla con su propia responsabilidad. Ademas de que cada aplicacion esta hecho en tecnologias diferentes (Python, C#, Node.js). por ende cada pipeline puede ser mas enfocado a esas tecnologias.
- Se opto por agregar ciertos secretos a nivel de organizacion y que estos sean usados en los repositorios. esto para no duplicar los secretos en cada repositorio de aplicacion y poder reutilizarlos.
- Se optio por un esquema de GIT FLOW debido a que al separar claramente desarrollo, QA y producción, minimizas la posibilidad de que código inestable llegue a entornos críticos. Si bien estaba yo solo en el equipo. este enfoque me permitio definir roles claros para cada rama: dev para integración de features, test para validación y prod para producción.
- Se optio por un esquema de Feature branch en el repo de Infra dado que los cambios en IaC suelen ser puntuales y críticos (añadir un nuevo módulo, modificar redes o políticas)/
- El repo de infraestructura implementa workflows reutilizables para que no se duplique el codigo en los repos de aplicaciones.
- El repositorio de infraestructura es responsable de guardar ciertos manifiestos de k8 genericos. mientras que los reposotiros de apps va a guardar el manifiesto de deployment de esa app especifica, para poder aplicarla al momento de ejecutar el pipeline de CI/CD.
- Se implemento Terraform de forma modular para poder ser mas extensible ante nuevos requerimientos.
- Se creo un ECR por aplicacion, esto para no mezclar aplicaciones. en cada ECR se van a guardar las imagenes buildeadas de cada entorno (dev,test,prod).
- Se creo VPC dedicadas por ambiente, esto para ser mas escalable y permitir politicas de acceso diferenciadas, asi como subir o bajar recursos segun entorno y no mezclar problemas entre ambientes.
- Cada VPC tiene subredes publicas y privadas, en donde todos los nodos que se encuentran las apps corren en subredes privadas, eso para garantizar seguridad y exposicion nula. Mientras que en las subredes publicas se van a exponer los balanceadores de carga como unico punto de acceso a los sistemas. Con esta separación y doble AZ, se logra alta disponibilidad y redundancia, mientras que la capa privada protege recursos críticos y facilita cumplir requisitos de seguridad y compliance.
- **Internet Gateway** + **NAT Gateway** en cada VPC: Los pods en subredes privadas pueden acceder a Internet para actualizaciones y llamadas salientes, sin exponerlos directamente.
- Se implemento tres clusters EKS (dev/test/prod) aislados para evitar interferencias y permitir escalado independiente. donde cada cluster va a tener un node group configurado con un Auto Scaling (min=1, desired=2, max=3) garantiza capacidad bajo demanda.
- La elección de **EKS** sobre **ECS** vino de la necesidad de **reutilizar** los manifiestos de Kubernetes que ya existían (Deployments, Services, ConfigMaps, etc.) y encajaban perfectamente en nuestros pipelines de **GitHub Actions** y módulos de Terraform.

Lecciones aprendidas:

- Las aplicaciones estaban diseñadas para atender únicamente la ruta raíz (`/`), lo que chocó con nuestro primer enfoque de usar un único Ingress NGINX (un mismo Load Balancer) mapeando `/vote` y `/result` a cada servicio. Al no admitir subpaths, las peticiones no alcanzaban el handler correcto y la aplicación fallaba. En lugar de forzar cambios en el código, invertimos el enfoque: adaptamos la infraestructura a la configuración existente. este modo pudimos desplegar sin tocar el código, simplificando el enrutamiento y evitando problemas adicionales.
- Para aplicaciones pequeñas, donde la carga es baja, puede resultar más económico y práctico desplegar on-premises en lugar de asumir las tarifas de servicios gestionados en la nube. ya que me parecio que hubo mucho gasto para el casi nulo trafico que tuvo la aplicacion.
- Kuberentes tuvo una mayor curva de aprendizaje con respecto a docker. pero termine entendidendo la cantidad de beneficios que este trae. en especial con aplicaciones grandes.
- Tuve varios problemas con recursos que quise utilizar en terraform debido a falta total de conocimiento de ciertas propiedades que se debian de configurar. Pero gracias a la documentacion y IA generativa en modo de aprendizaje, se pudo evacuar esos problemas.
