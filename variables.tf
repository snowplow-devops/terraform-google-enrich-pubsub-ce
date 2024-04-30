variable "accept_limited_use_license" {
  description = "Acceptance of the SLULA terms (https://docs.snowplow.io/limited-use-license-1.0/)"
  type        = bool
  default     = false

  validation {
    condition     = var.accept_limited_use_license
    error_message = "Please accept the terms of the Snowplow Limited Use License Agreement to proceed."
  }
}

variable "name" {
  description = "A name which will be pre-pended to the resources created"
  type        = string
}

variable "app_version" {
  description = "App version to use. This variable facilitates dev flow, the modules may not work with anything other than the default value."
  type        = string
  default     = "3.9.0"
}

variable "project_id" {
  description = "The project ID in which the stack is being deployed"
  type        = string
}

variable "network_project_id" {
  description = "The project ID of the shared VPC in which the stack is being deployed"
  type        = string
  default     = ""
}

variable "region" {
  description = "The name of the region to deploy within"
  type        = string
}

variable "network" {
  description = "The name of the network to deploy within"
  type        = string
}

variable "subnetwork" {
  description = "The name of the sub-network to deploy within; if populated will override the 'network' setting"
  type        = string
  default     = ""
}

variable "machine_type" {
  description = "The machine type to use"
  type        = string
  default     = "e2-small"
}

variable "target_size" {
  description = "The number of servers to deploy"
  default     = 1
  type        = number
}

variable "associate_public_ip_address" {
  description = "Whether to assign a public ip address to this instance; if false this instance must be behind a Cloud NAT to connect to the internet"
  type        = bool
  default     = true
}

variable "ssh_ip_allowlist" {
  description = "The list of CIDR ranges to allow SSH traffic from"
  type        = list(any)
  default     = ["0.0.0.0/0"]
}

variable "ssh_block_project_keys" {
  description = "Whether to block project wide SSH keys"
  type        = bool
  default     = true
}

variable "ssh_key_pairs" {
  description = "The list of SSH key-pairs to add to the servers"
  default     = []
  type = list(object({
    user_name  = string
    public_key = string
  }))
}

variable "ubuntu_20_04_source_image" {
  description = "The source image to use which must be based of of Ubuntu 20.04; by default the latest community version is used"
  default     = ""
  type        = string
}

variable "labels" {
  description = "The labels to append to this resource"
  default     = {}
  type        = map(string)
}

variable "gcp_logs_enabled" {
  description = "Whether application logs should be reported to GCP Logging"
  default     = true
  type        = bool
}

variable "java_opts" {
  description = "Custom JAVA Options"
  default     = "-XX:InitialRAMPercentage=75 -XX:MaxRAMPercentage=75"
  type        = string
}

# --- Configuration options

variable "raw_topic_name" {
  description = "The name of the raw pubsub topic that enrichment will pull data from"
  type        = string
}

variable "good_topic_id" {
  description = "The id of the good pubsub topic that enrichment will insert data into"
  type        = string
}

variable "bad_topic_id" {
  description = "The id of the bad pubsub topic that enrichment will insert data into"
  type        = string
}

variable "assets_update_period" {
  description = "Period after which enrich assets should be checked for updates (e.g. MaxMind DB)"
  default     = "7 days"
  type        = string

  validation {
    condition     = can(regex("\\d+ (ns|nano|nanos|nanosecond|nanoseconds|us|micro|micros|microsecond|microseconds|ms|milli|millis|millisecond|milliseconds|s|second|seconds|m|minute|minutes|h|hour|hours|d|day|days)", var.assets_update_period))
    error_message = "Invalid period formant."
  }
}

# --- Enrichment options
#
# To take full advantage of Snowplows enrichments should be activated to enhance and extend the data included
# with each event passing through the pipeline.  By default this module deploys the following:
#
# - campaign_attribution
# - event_fingerprint_config
# - referer_parser
# - ua_parser_config
# - yauaa_enrichment_config
#
# You can override the configuration JSON for any of these auto-enabled enrichments to turn them off or change the parameters
# along with activating any of available enrichments in our estate by passing in the appropriate configuration JSON.
#
# enrichment_yauaa_enrichment_config = <<EOF
# {
#   "schema": "iglu:com.snowplowanalytics.snowplow.enrichments/yauaa_enrichment_config/jsonschema/1-0-0",
#   "data": {
#     "enabled": false,
#     "vendor": "com.snowplowanalytics.snowplow.enrichments",
#     "name": "yauaa_enrichment_config"
#   }
# }
# EOF

variable "custom_tcp_egress_port_list" {
  description = "For opening up TCP ports to access other destinations not served over HTTP(s) (e.g. for SQL / API enrichments)"
  default     = []
  type        = list(string)
}

# --- Iglu Resolver

variable "default_iglu_resolvers" {
  description = "The default Iglu Resolvers that will be used by Enrichment to resolve and validate events"
  default = [
    {
      name            = "Iglu Central"
      priority        = 10
      uri             = "http://iglucentral.com"
      api_key         = ""
      vendor_prefixes = []
    },
    {
      name            = "Iglu Central - Mirror 01"
      priority        = 20
      uri             = "http://mirror01.iglucentral.com"
      api_key         = ""
      vendor_prefixes = []
    }
  ]
  type = list(object({
    name            = string
    priority        = number
    uri             = string
    api_key         = string
    vendor_prefixes = list(string)
  }))
}

variable "custom_iglu_resolvers" {
  description = "The custom Iglu Resolvers that will be used by Enrichment to resolve and validate events"
  default     = []
  type = list(object({
    name            = string
    priority        = number
    uri             = string
    api_key         = string
    vendor_prefixes = list(string)
  }))
}

# --- Enrichments which are enabled by default

variable "enrichment_campaign_attribution" {
  default = ""
  type    = string
}

variable "enrichment_event_fingerprint_config" {
  default = ""
  type    = string
}

variable "enrichment_referer_parser" {
  default = ""
  type    = string
}

variable "enrichment_ua_parser_config" {
  default = ""
  type    = string
}

variable "enrichment_yauaa_enrichment_config" {
  default = ""
  type    = string
}

# --- Enrichments which are disabled by default

variable "enrichment_anon_ip" {
  default = ""
  type    = string
}

variable "enrichment_api_request_enrichment_config" {
  default = ""
  type    = string
}

variable "enrichment_cookie_extractor_config" {
  default = ""
  type    = string
}

variable "enrichment_currency_conversion_config" {
  default = ""
  type    = string
}

variable "enrichment_http_header_extractor_config" {
  default = ""
  type    = string
}

# Note: Requires paid database to function
variable "enrichment_iab_spiders_and_bots_enrichment" {
  default = ""
  type    = string
}

# Note: Requires free or paid subscription to database to function
variable "enrichment_ip_lookups" {
  default = ""
  type    = string
}

variable "enrichment_javascript_script_config" {
  default = ""
  type    = string
}

variable "enrichment_pii_enrichment_config" {
  default = ""
  type    = string
}

variable "enrichment_sql_query_enrichment_config" {
  default = ""
  type    = string
}

variable "enrichment_weather_enrichment_config" {
  default = ""
  type    = string
}

# --- Telemetry

variable "telemetry_enabled" {
  description = "Whether or not to send telemetry information back to Snowplow Analytics Ltd"
  type        = bool
  default     = true
}

variable "user_provided_id" {
  description = "An optional unique identifier to identify the telemetry events emitted by this stack"
  type        = string
  default     = ""
}
