import pkg from '../package.json' with { type: 'json' };

const API_URL = 'https://ifconfig.me/all.json';

// 版本号唯一来源：package.json 的 version；
// 打包时 Makefile 通过 --define 注入最终值，因此 make VERSION=x.y.z 也能同步到界面
const APP_VERSION =
    typeof INJECTED_VERSION !== 'undefined' ? INJECTED_VERSION : pkg.version;

const fetchBtn = document.getElementById('fetch-btn');
const statusOutput = document.getElementById('status-output');
const resultList = document.getElementById('result-list');

document.getElementById('app-version').textContent = `v${APP_VERSION}`;

// 字段中文名与展示顺序
const FIELD_LABELS = {
    ip_addr: 'IP 地址',
    forwarded: '转发链路',
    via: '代理',
    port: '端口',
    method: '请求方法',
    mime: 'MIME 类型',
    user_agent: 'User Agent'
};

function renderData(data) {
    const known = Object.keys(FIELD_LABELS).filter((key) => key in data);
    const extra = Object.keys(data).filter((key) => !(key in FIELD_LABELS));

    resultList.replaceChildren();
    [...known, ...extra].forEach((key) => {
        const item = document.createElement('li');
        item.className = 'result-item';

        const label = document.createElement('span');
        label.className = 'result-label';
        label.textContent = FIELD_LABELS[key] || key;

        const value = document.createElement('span');
        value.className = 'result-value';
        if (key === 'ip_addr') value.classList.add('highlight');
        value.textContent = String(data[key] ?? '-');

        item.append(label, value);
        resultList.appendChild(item);
    });
}

async function loadInfo() {
    fetchBtn.disabled = true;
    statusOutput.textContent = '正在查询...';
    statusOutput.className = 'status';

    try {
        const response = await fetch(API_URL, { headers: { Accept: 'application/json' } });
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        renderData(await response.json());
        statusOutput.textContent = '查询成功';
        statusOutput.className = 'status ok';
    } catch (err) {
        statusOutput.textContent = `请求失败：${err.message}`;
        statusOutput.className = 'status error';
    } finally {
        fetchBtn.disabled = false;
    }
}

fetchBtn.addEventListener('click', loadInfo);
loadInfo();
