import http from 'k6/http';
import { check } from 'k6';

// One scenario per process, selected by SCENARIO. VUs and duration come from
// the environment so warmup and measure runs share this file.
const scenario = __ENV.SCENARIO || 'list';
const vus = Number(__ENV.VUS || 1);
const duration = __ENV.DURATION || '30s';

export const options = {
  // One TCP connection per request. This keeps client error counts aligned
  // across the five servers.
  noConnectionReuse: true,
  scenarios: {
    bench: {
      executor: 'constant-vus',
      vus: vus,
      duration: duration,
      gracefulStop: '5s',
    },
  },
  summaryTrendStats: ['avg', 'p(50)', 'p(90)', 'p(99)'],
};

const base = __ENV.BASE;
const token = __ENV.TOKEN || '';
const auth = {
  headers: {
    Authorization: `Token ${token}`,
    'Content-Type': 'application/json',
  },
};

function bookmarkId() {
  return ((__VU * 17 + __ITER) % 100000) + 1;
}

function list() {
  const offset = ((__ITER + __VU) % 50) * 20;
  const res = http.get(`${base}/api/bookmarks/?limit=20&offset=${offset}`, auth);
  check(res, { 'list 200': (r) => r.status === 200 });
}

function search() {
  const res = http.get(`${base}/api/bookmarks/?q=alpha&limit=20`, auth);
  check(res, { 'search 200': (r) => r.status === 200 });
}

function searchTag() {
  const tag = (__ITER + __VU) % 2000;
  const res = http.get(`${base}/api/bookmarks/?q=${encodeURIComponent('#' + 'tag' + tag)}&limit=20`, auth);
  check(res, { 'search_tag 200': (r) => r.status === 200 });
}

function getOne() {
  const res = http.get(`${base}/api/bookmarks/${bookmarkId()}/`, auth);
  check(res, { 'get 200': (r) => r.status === 200 });
}

function create() {
  const url = `https://example.com/new/${__VU}/${__ITER}/${Date.now()}`;
  const body = JSON.stringify({
    url: url,
    title: 'bench',
    tag_names: ['tag0', 'tag1'],
  });
  const res = http.post(`${base}/api/bookmarks/?disable_scraping`, body, auth);
  check(res, { 'create 201': (r) => r.status === 201 });
}

function update() {
  const body = JSON.stringify({ title: `updated ${__VU}` });
  const res = http.patch(`${base}/api/bookmarks/${bookmarkId()}/`, body, auth);
  check(res, { 'update 200': (r) => r.status === 200 });
}

function archive() {
  const res = http.post(`${base}/api/bookmarks/${bookmarkId()}/archive/`, '{}', auth);
  check(res, { 'archive 204': (r) => r.status === 204 });
}

function tags() {
  const offset = ((__ITER + __VU) % 20) * 20;
  const res = http.get(`${base}/api/tags/?limit=20&offset=${offset}`, auth);
  check(res, { 'tags 200': (r) => r.status === 200 });
}

function mixed() {
  // 40% list, 20% text search, 15% get, 10% tag list, 8% update, 5% archive, 2% create.
  const roll = (__ITER * 17 + __VU) % 100;
  if (roll < 40) {
    list();
  } else if (roll < 60) {
    search();
  } else if (roll < 75) {
    getOne();
  } else if (roll < 85) {
    tags();
  } else if (roll < 93) {
    update();
  } else if (roll < 98) {
    archive();
  } else {
    create();
  }
}

export default function () {
  if (scenario === 'list') {
    list();
  } else if (scenario === 'search') {
    search();
  } else if (scenario === 'search_tag') {
    searchTag();
  } else if (scenario === 'get') {
    getOne();
  } else if (scenario === 'create') {
    create();
  } else if (scenario === 'update') {
    update();
  } else if (scenario === 'archive') {
    archive();
  } else if (scenario === 'tags') {
    tags();
  } else if (scenario === 'mixed') {
    mixed();
  }
}
