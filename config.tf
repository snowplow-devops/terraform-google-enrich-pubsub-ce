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

  iglu_resolver = templatefile("${path.module}/templates/iglu_resolver.json.tmpl", { resolvers = jsonencode(local.resolvers) })

  campaign_attribution     = var.enrichment_campaign_attribution == "" ? file("${path.module}/templates/enrichments/campaign_attribution.json") : var.enrichment_campaign_attribution
  event_fingerprint_config = var.enrichment_event_fingerprint_config == "" ? file("${path.module}/templates/enrichments/event_fingerprint_config.json") : var.enrichment_event_fingerprint_config
  referer_parser           = var.enrichment_referer_parser == "" ? file("${path.module}/templates/enrichments/referer_parser.json") : var.enrichment_referer_parser
  ua_parser_config         = var.enrichment_ua_parser_config == "" ? file("${path.module}/templates/enrichments/ua_parser_config.json") : var.enrichment_ua_parser_config
  yauaa_enrichment_config  = var.enrichment_yauaa_enrichment_config == "" ? file("${path.module}/templates/enrichments/yauaa_enrichment_config.json") : var.enrichment_yauaa_enrichment_config
}
