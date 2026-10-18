import http from 'k6/http';
import { check } from 'k6';

// One scenario per process, selected by SCENARIO. VUs and duration come from
// the environment so warmup and measure runs share this file.
const scenario = __ENV.SCENARIO || 'list';
const vus = Number(__ENV.VUS || 1);
const duration = __ENV.DURATION || '30s';

export const options = {
  scenarios: {
    bench: {
      executor: 'constant-vus',
      vus: vus,
      duration: duration,
      gracefulStop: scenario === 'login' ? '60s' : '15s',
    },
  },
  thresholds: { http_req_failed: ['rate==0'], checks: ['rate==1'] },
  summaryTrendStats: ['avg', 'p(50)', 'p(90)', 'p(99)'],
};

const base = __ENV.BASE;
const token = __ENV.TOKEN || '';
const authHeaders = {
  Authorization: `Token ${token}`,
  'Content-Type': 'application/json',
};
const jsonHeaders = { 'Content-Type': 'application/json' };

function articleNumber() {
  return ((__VU * 997 + __ITER) % 10000) + 1;
}

function list() {
  const kind = (__ITER + __VU) % 3;
  let url;
  if (kind === 0) {
    url = `${base}/api/articles?limit=20&offset=0`;
  } else if (kind === 1) {
    const offset = ((__ITER + __VU) % 50) * 20;
    url = `${base}/api/articles?limit=20&offset=${offset}`;
  } else {
    const tag = (__ITER + __VU) % 20;
    url = `${base}/api/articles?tag=tag${tag}&limit=20&offset=0`;
  }
  const res = http.get(url);
  check(res, { 'list 200': (r) => r.status === 200 });
}

function slug() {
  const res = http.get(`${base}/api/articles/article-${articleNumber()}`);
  check(res, { 'slug 200': (r) => r.status === 200 });
}

function feed() {
  const res = http.get(`${base}/api/articles/feed?limit=20&offset=0`, {
    headers: authHeaders,
  });
  check(res, { 'feed 200': (r) => r.status === 200 });
}

function login() {
  const i = ((__VU + __ITER) % 100) + 1;
  const body = JSON.stringify({
    user: { email: `user${i}@bench.test`, password: 'password123' },
  });
  const res = http.post(`${base}/api/users/login`, body, { headers: jsonHeaders });
  check(res, { 'login 200': (r) => r.status === 200 });
}

function createArticle() {
  const title = `Bench ${__VU}-${__ITER}-${Date.now()}`;
  const body = JSON.stringify({
    article: {
      title: title,
      description: 'Benchmark article',
      body: 'Benchmark body',
      tagList: ['tag0', 'tag1'],
    },
  });
  const res = http.post(`${base}/api/articles`, body, { headers: authHeaders });
  check(res, { 'create 201': (r) => r.status === 201 });
}

function favorite() {
  const n = 5000 + ((__VU * 13 + __ITER) % 5000) + 1;
  const res = http.post(`${base}/api/articles/article-${n}/favorite`, '{}', {
    headers: authHeaders,
  });
  check(res, { 'favorite 200': (r) => r.status === 200 });
}

function mixed() {
  // 50% list, 20% slug, 15% feed, 10% favorite, 5% create.
  const roll = (__ITER * 17 + __VU) % 100;
  if (roll < 50) {
    list();
  } else if (roll < 70) {
    slug();
  } else if (roll < 85) {
    feed();
  } else if (roll < 95) {
    favorite();
  } else {
    createArticle();
  }
}

export default function () {
  if (scenario === 'list') {
    list();
  } else if (scenario === 'slug') {
    slug();
  } else if (scenario === 'feed') {
    feed();
  } else if (scenario === 'login') {
    login();
  } else if (scenario === 'create') {
    createArticle();
  } else if (scenario === 'favorite') {
    favorite();
  } else if (scenario === 'mixed') {
    mixed();
  } else {
    throw new Error(`unknown scenario ${scenario}`);
  }
}
