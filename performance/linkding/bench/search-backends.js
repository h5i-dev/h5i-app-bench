import http from 'k6/http';
import { check } from 'k6';

export const options = {
  noConnectionReuse: true,
  vus: Number(__ENV.VUS),
  duration: __ENV.DURATION,
  summaryTrendStats: ['avg', 'p(50)', 'p(95)', 'p(99)'],
  thresholds: { http_req_failed: ['rate==0'], checks: ['rate==1'] },
};

export default function () {
  const res = http.get(__ENV.URL, {
    headers: { Authorization: `Token ${__ENV.TOKEN}` },
  });
  check(res, {
    'status and count match SQL': (r) =>
      r.status === 200 && r.json('count') === Number(__ENV.EXPECTED_COUNT),
  });
}
