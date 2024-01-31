[![Release][release-image]][release] [![CI][ci-image]][ci] [![License][license-image]][license] [![Registry][registry-image]][registry] [![Source][source-image]][source]

# terraform-google-enrich-pubsub-ce

A Terraform module which deploys the Snowplow Enrich PubSub service on Compute Engine.  If you want to use a custom image for this deployment you will need to ensure it is based on top of Ubuntu 20.04.

## Telemetry

This module by default collects and forwards telemetry information to Snowplow to understand how our applications are being used.  No identifying information about your sub-account or account fingerprints are ever forwarded to us - it is very simple information about what modules and applications are deployed and active.

If you wish to subscribe to our mailing list for updates to these modules or security advisories please set the `user_provided_id` variable to include a valid email address which we can reach you at.

### How do I disable it?

To disable telemetry simply set variable `telemetry_enabled = false`.

### What are you collecting?

For details on what information is collected please see this module: https://github.com/snowplow-devops/terraform-snowplow-telemetry

## Usage

### Standard usage

Enrich PubSub takes data from a raw input topic and pushes validated data to the enriched topic and failed data to the bad topic.  As part of this validation process we leverage Iglu which is Snowplow's schema repository - the home for event and entity definitions.  If you are using custom events that you have defined yourself you will need to ensure that you link in your own Iglu Registries to this module so that they can be discovered correctly.

By default this module enables 5 enrichments which you can find in the `templates/enrichments` directory of this module.

```hcl
module "raw_topic" {
  source  = "snowplow-devops/pubsub-topic/google"
  version = "0.3.0"

  name = "raw-topic"
}

module "bad_1_topic" {
  source  = "snowplow-devops/pubsub-topic/google"
  version = "0.3.0"

  name = "bad-1-topic"
}

module "enriched_topic" {
  source  = "snowplow-devops/pubsub-topic/google"
  version = "0.3.0"

  name = "enriched-topic"
}

module "enrich_pubsub" {
  source = "snowplow-devops/enrich-pubsub-ce/google"

  accept_limited_use_license = true

  name = "enrich-server"

  network    = var.network
  subnetwork = var.subnetwork
  region     = var.region

  raw_topic_name = module.raw_topic.name
  good_topic_id  = module.enriched_topic.id
  bad_topic_id   = module.bad_1_topic.id

  ssh_key_pairs    = []
  ssh_ip_allowlist = ["0.0.0.0/0"]

  # Linking in the custom Iglu Server here
  custom_iglu_resolvers = [
    {
      name            = "Iglu Server"
      priority        = 0
      uri             = "http://your-iglu-server-endpoint/api"
      api_key         = var.iglu_super_api_key
      vendor_prefixes = []
    }
  ]
}
```

### Inserting custom enrichments

To define your own enrichment configurations you will need to provide the enrichment in the appropriate placeholder.

```hcl
locals {
  enrichment_anon_ip = <<EOF
{
  "schema": "iglu:com.snowplowanalytics.snowplow/anon_ip/jsonschema/1-0-1",
  "data": {
    "name": "anon_ip",
    "vendor": "com.snowplowanalytics.snowplow",
    "enabled": true,
    "parameters": {
      "anonOctets": 1,
      "anonSegments": 1
    }
  }
}
EOF
}

module "enrich_pubsub" {
  source = "snowplow-devops/enrich-pubsub-ce/google"

  accept_limited_use_license = true

  name = "enrich-server"

  network    = var.network
  subnetwork = var.subnetwork
  region     = var.region

  raw_topic_name = module.raw_topic.name
  good_topic_id  = module.enriched_topic.id
  bad_topic_id   = module.bad_1_topic.id

  ssh_key_pairs    = []
  ssh_ip_allowlist = ["0.0.0.0/0"]

  # Linking in the custom Iglu Server here
  custom_iglu_resolvers = [
    {
      name            = "Iglu Server"
      priority        = 0
      uri             = "http://your-iglu-server-endpoint/api"
      api_key         = var.iglu_super_api_key
      vendor_prefixes = []
    }
  ]

  # Enable this enrichment
  enrichment_anon_ip = local.enrichment_anon_ip
}
```

### Disabling default enrichments

As with inserting custom enrichments to disable the default enrichments a similar strategy must be employed.  For example to disable YAUAA you would do the following.

```hcl
locals {
  enrichment_yauaa = <<EOF
{
  "schema": "iglu:com.snowplowanalytics.snowplow.enrichments/yauaa_enrichment_config/jsonschema/1-0-0",
  "data": {
    "enabled": false,
    "vendor": "com.snowplowanalytics.snowplow.enrichments",
    "name": "yauaa_enrichment_config"
  }
}
EOF
}

module "enrich_pubsub" {
  source = "snowplow-devops/enrich-pubsub-ce/google"

  accept_limited_use_license = true

  name = "enrich-server"

  network    = var.network
  subnetwork = var.subnetwork
  region     = var.region

  raw_topic_name = module.raw_topic.name
  good_topic_id  = module.enriched_topic.id
  bad_topic_id   = module.bad_1_topic.id

  ssh_key_pairs    = []
  ssh_ip_allowlist = ["0.0.0.0/0"]

  # Linking in the custom Iglu Server here
  custom_iglu_resolvers = [
    {
      name            = "Iglu Server"
      priority        = 0
      uri             = "http://your-iglu-server-endpoint/api"
      api_key         = var.iglu_super_api_key
      vendor_prefixes = []
    }
  ]

  # Disable this enrichment
  enrichment_yauaa_enrichment_config = local.enrichment_yauaa
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 3.44.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 3.44.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_service"></a> [service](#module\_service) | snowplow-devops/service-ce/google | 0.1.0 |
| <a name="module_telemetry"></a> [telemetry](#module\_telemetry) | snowplow-devops/telemetry/snowplow | 0.5.0 |

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.egress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.ingress_ssh](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_project_iam_member.sa_logging_log_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.sa_pubsub_publisher](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.sa_pubsub_subscriber](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.sa_pubsub_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.sa_storage_object_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_pubsub_subscription.in](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) | resource |
| [google_service_account.sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bad_topic_id"></a> [bad\_topic\_id](#input\_bad\_topic\_id) | The id of the bad pubsub topic that enrichment will insert data into | `string` | n/a | yes |
| <a name="input_good_topic_id"></a> [good\_topic\_id](#input\_good\_topic\_id) | The id of the good pubsub topic that enrichment will insert data into | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | A name which will be pre-pended to the resources created | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | The name of the network to deploy within | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project ID in which the stack is being deployed | `string` | n/a | yes |
| <a name="input_raw_topic_name"></a> [raw\_topic\_name](#input\_raw\_topic\_name) | The name of the raw pubsub topic that enrichment will pull data from | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The name of the region to deploy within | `string` | n/a | yes |
| <a name="input_accept_limited_use_license"></a> [accept\_limited\_use\_license](#input\_accept\_limited\_use\_license) | Acceptance of the SLULA terms (https://docs.snowplow.io/limited-use-license-1.0/) | `bool` | `false` | no |
| <a name="input_app_version"></a> [app\_version](#input\_app\_version) | App version to use. This variable facilitates dev flow, the modules may not work with anything other than the default value. | `string` | `"3.9.0"` | no |
| <a name="input_assets_update_period"></a> [assets\_update\_period](#input\_assets\_update\_period) | Period after which enrich assets should be checked for updates (e.g. MaxMind DB) | `string` | `"7 days"` | no |
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | Whether to assign a public ip address to this instance; if false this instance must be behind a Cloud NAT to connect to the internet | `bool` | `true` | no |
| <a name="input_custom_iglu_resolvers"></a> [custom\_iglu\_resolvers](#input\_custom\_iglu\_resolvers) | The custom Iglu Resolvers that will be used by Enrichment to resolve and validate events | <pre>list(object({<br>    name            = string<br>    priority        = number<br>    uri             = string<br>    api_key         = string<br>    vendor_prefixes = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_custom_tcp_egress_port_list"></a> [custom\_tcp\_egress\_port\_list](#input\_custom\_tcp\_egress\_port\_list) | For opening up TCP ports to access other destinations not served over HTTP(s) (e.g. for SQL / API enrichments) | `list(string)` | `[]` | no |
| <a name="input_default_iglu_resolvers"></a> [default\_iglu\_resolvers](#input\_default\_iglu\_resolvers) | The default Iglu Resolvers that will be used by Enrichment to resolve and validate events | <pre>list(object({<br>    name            = string<br>    priority        = number<br>    uri             = string<br>    api_key         = string<br>    vendor_prefixes = list(string)<br>  }))</pre> | <pre>[<br>  {<br>    "api_key": "",<br>    "name": "Iglu Central",<br>    "priority": 10,<br>    "uri": "http://iglucentral.com",<br>    "vendor_prefixes": []<br>  },<br>  {<br>    "api_key": "",<br>    "name": "Iglu Central - Mirror 01",<br>    "priority": 20,<br>    "uri": "http://mirror01.iglucentral.com",<br>    "vendor_prefixes": []<br>  }<br>]</pre> | no |
| <a name="input_enrichment_anon_ip"></a> [enrichment\_anon\_ip](#input\_enrichment\_anon\_ip) | n/a | `string` | `""` | no |
| <a name="input_enrichment_api_request_enrichment_config"></a> [enrichment\_api\_request\_enrichment\_config](#input\_enrichment\_api\_request\_enrichment\_config) | n/a | `string` | `""` | no |
| <a name="input_enrichment_campaign_attribution"></a> [enrichment\_campaign\_attribution](#input\_enrichment\_campaign\_attribution) | n/a | `string` | `""` | no |
| <a name="input_enrichment_cookie_extractor_config"></a> [enrichment\_cookie\_extractor\_config](#input\_enrichment\_cookie\_extractor\_config) | n/a | `string` | `""` | no |
| <a name="input_enrichment_currency_conversion_config"></a> [enrichment\_currency\_conversion\_config](#input\_enrichment\_currency\_conversion\_config) | n/a | `string` | `""` | no |
| <a name="input_enrichment_event_fingerprint_config"></a> [enrichment\_event\_fingerprint\_config](#input\_enrichment\_event\_fingerprint\_config) | n/a | `string` | `""` | no |
| <a name="input_enrichment_http_header_extractor_config"></a> [enrichment\_http\_header\_extractor\_config](#input\_enrichment\_http\_header\_extractor\_config) | n/a | `string` | `""` | no |
| <a name="input_enrichment_iab_spiders_and_bots_enrichment"></a> [enrichment\_iab\_spiders\_and\_bots\_enrichment](#input\_enrichment\_iab\_spiders\_and\_bots\_enrichment) | Note: Requires paid database to function | `string` | `""` | no |
| <a name="input_enrichment_ip_lookups"></a> [enrichment\_ip\_lookups](#input\_enrichment\_ip\_lookups) | Note: Requires free or paid subscription to database to function | `string` | `""` | no |
| <a name="input_enrichment_javascript_script_config"></a> [enrichment\_javascript\_script\_config](#input\_enrichment\_javascript\_script\_config) | n/a | `string` | `""` | no |
| <a name="input_enrichment_pii_enrichment_config"></a> [enrichment\_pii\_enrichment\_config](#input\_enrichment\_pii\_enrichment\_config) | n/a | `string` | `""` | no |
| <a name="input_enrichment_referer_parser"></a> [enrichment\_referer\_parser](#input\_enrichment\_referer\_parser) | n/a | `string` | `""` | no |
| <a name="input_enrichment_sql_query_enrichment_config"></a> [enrichment\_sql\_query\_enrichment\_config](#input\_enrichment\_sql\_query\_enrichment\_config) | n/a | `string` | `""` | no |
| <a name="input_enrichment_ua_parser_config"></a> [enrichment\_ua\_parser\_config](#input\_enrichment\_ua\_parser\_config) | n/a | `string` | `""` | no |
| <a name="input_enrichment_weather_enrichment_config"></a> [enrichment\_weather\_enrichment\_config](#input\_enrichment\_weather\_enrichment\_config) | n/a | `string` | `""` | no |
| <a name="input_enrichment_yauaa_enrichment_config"></a> [enrichment\_yauaa\_enrichment\_config](#input\_enrichment\_yauaa\_enrichment\_config) | n/a | `string` | `""` | no |
| <a name="input_gcp_logs_enabled"></a> [gcp\_logs\_enabled](#input\_gcp\_logs\_enabled) | Whether application logs should be reported to GCP Logging | `bool` | `true` | no |
| <a name="input_java_opts"></a> [java\_opts](#input\_java\_opts) | Custom JAVA Options | `string` | `"-XX:InitialRAMPercentage=75 -XX:MaxRAMPercentage=75"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | The labels to append to this resource | `map(string)` | `{}` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | The machine type to use | `string` | `"e2-small"` | no |
| <a name="input_ssh_block_project_keys"></a> [ssh\_block\_project\_keys](#input\_ssh\_block\_project\_keys) | Whether to block project wide SSH keys | `bool` | `true` | no |
| <a name="input_ssh_ip_allowlist"></a> [ssh\_ip\_allowlist](#input\_ssh\_ip\_allowlist) | The list of CIDR ranges to allow SSH traffic from | `list(any)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_ssh_key_pairs"></a> [ssh\_key\_pairs](#input\_ssh\_key\_pairs) | The list of SSH key-pairs to add to the servers | <pre>list(object({<br>    user_name  = string<br>    public_key = string<br>  }))</pre> | `[]` | no |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | The name of the sub-network to deploy within; if populated will override the 'network' setting | `string` | `""` | no |
| <a name="input_target_size"></a> [target\_size](#input\_target\_size) | The number of servers to deploy | `number` | `1` | no |
| <a name="input_telemetry_enabled"></a> [telemetry\_enabled](#input\_telemetry\_enabled) | Whether or not to send telemetry information back to Snowplow Analytics Ltd | `bool` | `true` | no |
| <a name="input_ubuntu_20_04_source_image"></a> [ubuntu\_20\_04\_source\_image](#input\_ubuntu\_20\_04\_source\_image) | The source image to use which must be based of of Ubuntu 20.04; by default the latest community version is used | `string` | `""` | no |
| <a name="input_user_provided_id"></a> [user\_provided\_id](#input\_user\_provided\_id) | An optional unique identifier to identify the telemetry events emitted by this stack | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_group_url"></a> [instance\_group\_url](#output\_instance\_group\_url) | The full URL of the instance group created by the manager |
| <a name="output_manager_id"></a> [manager\_id](#output\_manager\_id) | Identifier for the instance group manager |
| <a name="output_manager_self_link"></a> [manager\_self\_link](#output\_manager\_self\_link) | The URL for the instance group manager |

# Copyright and license

Copyright 2021-present Snowplow Analytics Ltd.

Licensed under the [Snowplow Limited Use License Agreement][license]. _(If you are uncertain how it applies to your use case, check our answers to [frequently asked questions][license-faq].)_

[release]: https://github.com/snowplow-devops/terraform-google-enrich-pubsub-ce/releases/latest
[release-image]: https://img.shields.io/github/v/release/snowplow-devops/terraform-google-enrich-pubsub-ce

[ci]: https://github.com/snowplow-devops/terraform-google-enrich-pubsub-ce/actions?query=workflow%3Aci
[ci-image]: https://github.com/snowplow-devops/terraform-google-enrich-pubsub-ce/workflows/ci/badge.svg

[license]: https://docs.snowplow.io/limited-use-license-1.0/
[license-image]: https://img.shields.io/badge/license-Snowplow--Limited--Use-blue.svg?style=flat
[license-faq]: https://docs.snowplow.io/docs/contributing/limited-use-license-faq/

[registry]: https://registry.terraform.io/modules/snowplow-devops/enrich-pubsub-ce/google/latest
[registry-image]: https://img.shields.io/static/v1?label=Terraform&message=Registry&color=7B42BC&logo=terraform

[source]: https://github.com/snowplow/enrich
[source-image]: https://img.shields.io/static/v1?label=Snowplow&message=Enrich&color=0E9BA4&logo=GitHub
