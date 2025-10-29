locals {
  module_name    = "enrich-pubsub-ce"
  module_version = "0.5.0"

  app_name    = "enrich-pubsub"
  app_version = var.app_version

  local_labels = {
    name           = var.name
    app_name       = local.app_name
    app_version    = replace(local.app_version, ".", "-")
    module_name    = local.module_name
    module_version = replace(local.module_version, ".", "-")
  }

  labels = merge(
    var.labels,
    local.local_labels
  )
}

module "telemetry" {
  source  = "snowplow-devops/telemetry/snowplow"
  version = "0.6.1"

  count = var.telemetry_enabled ? 1 : 0

  user_provided_id = var.user_provided_id
  cloud            = "GCP"
  region           = var.region
  app_name         = local.app_name
  app_version      = local.app_version
  module_name      = local.module_name
  module_version   = local.module_version
}

# --- IAM: Service Account setup

resource "google_service_account" "sa" {
  account_id   = var.name
  display_name = "Snowplow Enrich PubSub service account - ${var.name}"
}

resource "google_project_iam_member" "sa_pubsub_viewer" {
  project = var.project_id
  role    = "roles/pubsub.viewer"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "sa_pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "sa_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "sa_logging_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "sa_storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

# --- CE: Firewall rules

resource "google_compute_firewall" "ingress_ssh" {
  project = (var.network_project_id != "") ? var.network_project_id : var.project_id
  name    = "${var.name}-ssh-in"

  network     = var.network
  target_tags = [var.name]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_ip_allowlist
}

resource "google_compute_firewall" "egress" {
  project = (var.network_project_id != "") ? var.network_project_id : var.project_id
  name    = "${var.name}-traffic-out"

  network     = var.network
  target_tags = [var.name]

  allow {
    protocol = "tcp"
    ports    = distinct(compact(concat(["80", "443"], var.custom_tcp_egress_port_list)))
  }

  allow {
    protocol = "udp"
    ports    = ["123"]
  }

  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
}

# --- CE: Instance group setup

resource "google_pubsub_subscription" "in" {
  name  = var.name
  topic = var.raw_topic_name

  expiration_policy {
    ttl = ""
  }

  labels = local.labels
}

locals {
  hocon = templatefile("${path.module}/templates/config.hocon.tmpl", {
    raw_subscription_id = google_pubsub_subscription.in.id
    good_topic_id       = var.good_topic_id
    bad_topic_id        = var.bad_topic_id

    assets_update_period = var.assets_update_period

    telemetry_disable          = !var.telemetry_enabled
    telemetry_collector_uri    = join("", module.telemetry.*.collector_uri)
    telemetry_collector_port   = 443
    telemetry_secure           = true
    telemetry_user_provided_id = var.user_provided_id
    telemetry_auto_gen_id      = join("", module.telemetry.*.auto_generated_id)
    telemetry_module_name      = local.module_name
    telemetry_module_version   = local.module_version
  })

  startup_script = templatefile("${path.module}/templates/startup-script.sh.tmpl", {
    accept_limited_use_license = var.accept_limited_use_license

    config_b64        = base64encode(local.hocon)
    version           = local.app_version
    iglu_resolver_b64 = base64encode(local.iglu_resolver)

    telemetry_script = join("", module.telemetry.*.gcp_ubuntu_24_04_user_data)

    gcp_logs_enabled = var.gcp_logs_enabled

    java_opts = var.java_opts

    enrichment_campaign_attribution_b64            = base64encode(local.campaign_attribution)
    enrichment_event_fingerprint_config_b64        = base64encode(local.event_fingerprint_config)
    enrichment_referer_parser_b64                  = base64encode(local.referer_parser)
    enrichment_ua_parser_config_b64                = base64encode(local.ua_parser_config)
    enrichment_yauaa_enrichment_config_b64         = base64encode(local.yauaa_enrichment_config)
    enrichment_anon_ip_b64                         = base64encode(var.enrichment_anon_ip)
    enrichment_api_request_enrichment_config_b64   = base64encode(var.enrichment_api_request_enrichment_config)
    enrichment_cookie_extractor_config_b64         = base64encode(var.enrichment_cookie_extractor_config)
    enrichment_currency_conversion_config_b64      = base64encode(var.enrichment_currency_conversion_config)
    enrichment_http_header_extractor_config_b64    = base64encode(var.enrichment_http_header_extractor_config)
    enrichment_iab_spiders_and_bots_enrichment_b64 = base64encode(var.enrichment_iab_spiders_and_bots_enrichment)
    enrichment_ip_lookups_b64                      = base64encode(var.enrichment_ip_lookups)
    enrichment_javascript_script_config_b64        = base64encode(var.enrichment_javascript_script_config)
    enrichment_pii_enrichment_config_b64           = base64encode(var.enrichment_pii_enrichment_config)
    enrichment_sql_query_enrichment_config_b64     = base64encode(var.enrichment_sql_query_enrichment_config)
    enrichment_weather_enrichment_config_b64       = base64encode(var.enrichment_weather_enrichment_config)
  })
}

module "service" {
  source  = "snowplow-devops/service-ce/google"
  version = "0.2.0"

  user_supplied_script        = local.startup_script
  name                        = var.name
  instance_group_version_name = "${local.app_name}-${local.app_version}"
  labels                      = local.labels

  region     = var.region
  network    = var.network
  subnetwork = var.subnetwork

  ubuntu_24_04_source_image   = var.ubuntu_24_04_source_image
  machine_type                = var.machine_type
  target_size                 = var.target_size
  ssh_block_project_keys      = var.ssh_block_project_keys
  ssh_key_pairs               = var.ssh_key_pairs
  service_account_email       = google_service_account.sa.email
  associate_public_ip_address = var.associate_public_ip_address
}
