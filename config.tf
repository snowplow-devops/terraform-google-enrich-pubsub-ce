locals {
  resolvers_raw = concat(var.default_iglu_resolvers, var.custom_iglu_resolvers)

  resolvers_open = [
    for resolver in local.resolvers_raw : merge(
      {
        name           = resolver["name"],
        priority       = resolver["priority"],
        vendorPrefixes = resolver["vendor_prefixes"],
        connection = {
          http = {
            uri = resolver["uri"]
          }
        }
      }
    ) if resolver["api_key"] == ""
  ]

  resolvers_closed = [
    for resolver in local.resolvers_raw : merge(
      {
        name           = resolver["name"],
        priority       = resolver["priority"],
        vendorPrefixes = resolver["vendor_prefixes"],
        connection = {
          http = {
            uri    = resolver["uri"]
            apikey = resolver["api_key"]
          }
        }
      }
    ) if resolver["api_key"] != ""
  ]

  resolvers = flatten([
    local.resolvers_open,
    local.resolvers_closed
  ])

  iglu_config = templatefile("${path.module}/templates/iglu_config.json.tmpl", { resolvers = jsonencode(local.resolvers) })

  campaign_attribution     = var.enrichment_campaign_attribution == "" ? file("${path.module}/templates/enrichments/campaign_attribution.json") : var.enrichment_campaign_attribution
  event_fingerprint_config = var.enrichment_event_fingerprint_config == "" ? file("${path.module}/templates/enrichments/event_fingerprint_config.json") : var.enrichment_event_fingerprint_config
  referer_parser           = var.enrichment_referer_parser == "" ? file("${path.module}/templates/enrichments/referer_parser.json") : var.enrichment_referer_parser
  ua_parser_config         = var.enrichment_ua_parser_config == "" ? file("${path.module}/templates/enrichments/ua_parser_config.json") : var.enrichment_ua_parser_config
  yauaa_enrichment_config  = var.enrichment_yauaa_enrichment_config == "" ? file("${path.module}/templates/enrichments/yauaa_enrichment_config.json") : var.enrichment_yauaa_enrichment_config

  enrichments_list = compact([
    local.campaign_attribution,
    local.event_fingerprint_config,
    local.referer_parser,
    local.ua_parser_config,
    local.yauaa_enrichment_config,
    var.enrichment_anon_ip,
    var.enrichment_api_request_enrichment_config,
    var.enrichment_cookie_extractor_config,
    var.enrichment_currency_conversion_config,
    var.enrichment_http_header_extractor_config,
    var.enrichment_iab_spiders_and_bots_enrichment,
    var.enrichment_ip_lookups,
    var.enrichment_javascript_script_config,
    var.enrichment_pii_enrichment_config,
    var.enrichment_sql_query_enrichment_config,
    var.enrichment_weather_enrichment_config,
  ])

  enrichments = templatefile("${path.module}/templates/enrichments.json.tmpl", { enrichments = join(",", local.enrichments_list) })
}
