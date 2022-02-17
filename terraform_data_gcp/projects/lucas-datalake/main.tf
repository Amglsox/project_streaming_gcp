module "gcs-bucket-logs" {
  source                      = "../../modules/gcs"
  name                        = format("%s-logs", var.project)
  project_id                  = var.project
  location                    = "US-CENTRAL1"
  storage_class               = "STANDARD"
  bucket_policy_only          = true
  labels        = {
    zone = "logs"
  }
}
module "pubsub-topic-person-events" {
  source = "../../modules/pubsub"
  project_id = var.project
  topic      = "lucas-person-events"
  topic_labels = {
    source  = "api"
    event   = "fake_person"
    env     = var.env
  }
  create_topic = true
}
module "bigquery-dataset-1" {
  source  = "../../modules/bigquery"
  dataset_id                  = "loja_lucas"
  dataset_name                = "loja_lucas"
  description                 = "Dataset a respeito das vendas das lojas"
  project_id                  = var.project
  location                    = var.region
  delete_contents_on_destroy  = true
  dataset_labels = {
    env      = var.env
    billable = "true"
  }
  access = [
    {
      role = "OWNER"
      special_group = "projectOwners"
    },
    {
      role = "READER"
      special_group = "projectReaders"
    },
    {
      role = "WRITER"
      special_group = "projectWriters"
    }
  ]
  tables=[
    {
      table_id           = "vendas",
      description        = "Tabela de vendas de produtos"
      time_partitioning  = {
        type                     = "DAY",
        field                    = "dtCompra",
        require_partition_filter = false,
        expiration_ms            = null
      },
      range_partitioning = null,
      expiration_time = null,
      clustering      = ["pais", "estado", "cidade"]
      labels          = {
        env      = var.env
        carga    = "streaming"
        project  = "lojas"
      },
      deletion_protection = true
      schema = file("./bigquery/LOJA_LUCAS/vendas.json")
  }
  ]
}

module "dataflow-job-person-events"{
    source                = "../../modules/dataflow"
    project_id            = var.project
    region                = "us-central1"
    zone                  = "us-central1-a"
    name                  = "lucas-dataflow-job-person-events"
    max_workers           = 3
    template_gcs_path     = "gs://dataflow-templates-us-central1/latest/PubSub_to_BigQuery"
    temp_gcs_location     = "${var.project}-logs/dataflow"
    parameters            = {
      "outputTableSpec"   = "${var.project}:loja_lucas.vendas"
      "inputTopic"        = "projects/${var.project}/topics/${module.pubsub-topic-person-events.topic}" 
    }
}
module "function-person-events"{
    source = "../../modules/cloud_function"
    name   = "function-person-events"
    description = "Cloud function resposnável por receber os eventos de pessoas fake"
    available_memory_mb = 1024
    timeout_s = "200"
    entry_point = "execute"
    ingress_settings = "ALLOW_ALL"
    trigger_http = true
    project_id = var.project
    region = "us-central1"
    labels = {
      env     = var.env
    }
    environment_variables = {
      PROJECT_ID = var.project
      TOPIC = "lucas-person-events"
    }
    runtime = "python38"
    create_bucket = true
    bucket_name = "${var.project}-artifacts-function"
    source_directory = "./cloud-function/function-person-events"
}

module "scheduler-person-events"{
   source         = "../../modules/cloud_scheduler"
   job_name       = "scheduler"
   region         = "us-central1"
   job_description    = ""
   cron   = "*/1 * * * *"
   url = "${module.function-person-events.https_trigger_url}"
   body="Hello"
   audience = "${module.function-person-events.https_trigger_url}"
   service_account = "lucas-datalake-dev@appspot.gserviceaccount.com"
} 
