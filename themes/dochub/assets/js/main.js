// Search powered by Hugo JSON output
let searchIndex = [];

async function loadIndex() {
  try {
    const res = await fetch('/index.json');
    searchIndex = await res.json();
  } catch (e) {
    console.warn('Search index not available');
  }
}

function search(query) {
  if (!query || query.length < 2) return [];
  const q = query.toLowerCase();
  return searchIndex
    .filter(item =>
      item.title?.toLowerCase().includes(q) ||
      item.content?.toLowerCase().includes(q) ||
      item.tags?.some(t => t.toLowerCase().includes(q))
    )
    .slice(0, 8);
}

function renderResults(results, query) {
  const el = document.getElementById('search-results');
  if (!results.length) {
    el.innerHTML = `<div class="search-result-item"><span class="search-result-meta">Nenhum resultado para "${query}"</span></div>`;
    el.classList.remove('hidden');
    return;
  }
  el.innerHTML = results.map(r => `
    <a class="search-result-item" href="${r.permalink}">
      <div class="search-result-meta">${r.params?.team || ''} · ${r.params?.doc_type || ''}</div>
      <div>${r.title}</div>
    </a>
  `).join('');
  el.classList.remove('hidden');
}

document.addEventListener('DOMContentLoaded', () => {
  loadIndex();

  const input = document.getElementById('search-input');
  const results = document.getElementById('search-results');
  if (!input) return;

  let debounce;
  input.addEventListener('input', e => {
    clearTimeout(debounce);
    debounce = setTimeout(() => {
      const q = e.target.value.trim();
      if (!q) { results.classList.add('hidden'); return; }
      renderResults(search(q), q);
    }, 200);
  });

  document.addEventListener('click', e => {
    if (!input.contains(e.target) && !results.contains(e.target)) {
      results.classList.add('hidden');
    }
  });

  // Atalho de teclado: / para focar na busca
  document.addEventListener('keydown', e => {
    if (e.key === '/' && document.activeElement !== input) {
      e.preventDefault();
      input.focus();
    }
    if (e.key === 'Escape') {
      input.blur();
      results.classList.add('hidden');
    }
  });
});
