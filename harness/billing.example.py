"""Run costs for run.py. Copy to harness/billing.py and fill in PRICES.

Meter(model, usage_log) is created before a run; its cost() is the run's cost
in USD from the token counts proxy.py logged, or None for a model without a
price. gateway_id() maps the model names run.py takes (`gpt-5.5`,
`claude-sonnet-5-5`) to the names your upstream expects.
"""
import json

# Prompts longer than this many tokens use the second price tuple, if any.
LONG = 200_000
# model: ((input, cached input, output), long-prompt tuple or None), USD per
# 1M tokens. Thinking tokens bill as output; cache writes at 1.25x input.
PRICES = {
    # "gpt-5.5": ((5.00, 0.50, 30.00), None),
}


def gateway_id(model):
    return model


class Meter:
    def __init__(self, model, usage_log):
        self.model, self.log = model, usage_log

    def cost(self):
        return cost(self.model, self.log)


def cost(model, usage_log):
    """Cost of the requests in a proxy usage log (one JSON object per line)."""
    if model not in PRICES:
        return None
    base, long = PRICES[model]
    total = 0.0
    for line in usage_log.read_text().splitlines():
        u = json.loads(line).get("usage")
        if not u:
            continue
        out = u.get("output_tokens") or 0
        if "cache_read_input_tokens" in u or "cache_creation_input_tokens" in u:
            # Messages API: input_tokens excludes the cached parts.
            fresh = u.get("input_tokens") or 0
            cached = u.get("cache_read_input_tokens") or 0
            written = u.get("cache_creation_input_tokens") or 0
            inp = fresh + cached + written
        else:
            inp = u.get("input_tokens") or 0
            cached = (u.get("input_tokens_details") or {}).get("cached_tokens") or 0
            fresh, written = inp - cached, 0
        p_in, p_cached, p_out = long if long and inp > LONG else base
        total += (fresh * p_in + cached * p_cached + written * 1.25 * p_in + out * p_out) / 1e6
    return round(total, 4)
