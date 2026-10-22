export const MODES = ['light', 'dark'];

export const MUI_DEFAULTS = {
  light: {
    primary: '#1976d2',
    secondary: '#9c27b0',
    error: '#d32f2f',
    warning: '#ed6c02',
    info: '#0288d1',
    success: '#2e7d32',
    background: '#ffffff',
    paper: '#ffffff',
    text: 'rgba(0, 0, 0, 0.87)',
    textSecondary: 'rgba(0, 0, 0, 0.6)'
  },
  dark: {
    primary: '#90caf9',
    secondary: '#ce93d8',
    error: '#f44336',
    warning: '#ffa726',
    info: '#29b6f6',
    success: '#66bb6a',
    background: '#121212',
    paper: '#121212',
    text: '#ffffff',
    textSecondary: 'rgba(255, 255, 255, 0.7)'
  }
};

export const STARTER_THEME = {
  light: {
    palette: {
      mode: 'light',
      primary: { main: '#3f51b5' },
      secondary: { main: '#f50057' },
      background: { default: '#f5f5f7', paper: '#ffffff' }
    },
    typography: { fontFamily: "'Inter', 'Roboto', 'Helvetica', 'Arial', sans-serif", fontSize: 14 },
    shape: { borderRadius: 8 }
  },
  dark: {
    palette: {
      mode: 'dark',
      primary: { main: '#8c9eff' },
      secondary: { main: '#ff4081' },
      background: { default: '#121212', paper: '#1e1e1e' }
    },
    typography: { fontFamily: "'Inter', 'Roboto', 'Helvetica', 'Arial', sans-serif", fontSize: 14 },
    shape: { borderRadius: 8 }
  }
};

const isPlainObject = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);

export const clone = (obj) => (obj == null ? obj : JSON.parse(JSON.stringify(obj)));

export const parseTheme = (value) => {
  if (!value) return null;
  if (typeof value === 'string') {
    try {
      return JSON.parse(value);
    } catch {
      return null;
    }
  }
  return isPlainObject(value) ? value : null;
};

export const getPath = (obj, path) =>
  path.reduce((acc, key) => (acc != null ? acc[key] : undefined), obj);

const isEmpty = (v) => v === undefined || v === null || v === '' || (isPlainObject(v) && Object.keys(v).length === 0);

// Immutable set; empty values delete the key and prune now-empty parents.
export const setPath = (obj, path, value) => {
  const [head, ...rest] = path;
  const current = isPlainObject(obj) ? obj : {};
  const next = rest.length === 0 ? value : setPath(current[head], rest, value);
  const copy = { ...current };
  if (isEmpty(next)) {
    delete copy[head];
  } else {
    copy[head] = next;
  }
  return copy;
};

export const prune = (value) => {
  if (Array.isArray(value)) return value.map(prune);
  if (!isPlainObject(value)) return value;
  const out = {};
  Object.keys(value).forEach((key) => {
    const v = prune(value[key]);
    if (!isEmpty(v)) out[key] = v;
  });
  return out;
};

// Always work with explicit light/dark sections so each mode can be edited independently.
export const normalizeTheme = (input) => {
  const theme = clone(parseTheme(input)) || clone(STARTER_THEME);
  let result;
  if (isPlainObject(theme.light) || isPlainObject(theme.dark)) {
    const { light, dark, ...rest } = theme;
    result = {
      ...rest,
      light: clone(light || dark || {}),
      dark: clone(dark || light || {})
    };
  } else {
    result = { light: clone(theme), dark: clone(theme) };
  }
  MODES.forEach((mode) => {
    result[mode] = setPath(result[mode], ['palette', 'mode'], mode);
  });
  return prune(result);
};

export const paletteOf = (theme, mode = 'light') => {
  const t = parseTheme(theme) || {};
  return (t[mode] && t[mode].palette) || t.palette || (t.light && t.light.palette) || (t.dark && t.dark.palette) || {};
};

export const resolveColors = (theme, mode) => {
  const p = paletteOf(theme, mode);
  const d = MUI_DEFAULTS[mode] || MUI_DEFAULTS.light;
  const main = (key) => (p[key] && p[key].main) || d[key];
  return {
    primary: main('primary'),
    primaryContrast: (p.primary && p.primary.contrastText) || contrastText(main('primary')),
    secondary: main('secondary'),
    secondaryContrast: (p.secondary && p.secondary.contrastText) || contrastText(main('secondary')),
    error: main('error'),
    warning: main('warning'),
    info: main('info'),
    success: main('success'),
    background: (p.background && p.background.default) || d.background,
    paper: (p.background && p.background.paper) || (p.background && p.background.default) || d.paper,
    text: (p.text && p.text.primary) || d.text,
    textSecondary: (p.text && p.text.secondary) || d.textSecondary,
    divider: p.divider || (mode === 'dark' ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.12)')
  };
};

export const swatchesFor = (theme, mode = 'light') => {
  const c = resolveColors(theme, mode);
  return [c.primary, c.secondary, c.background, c.paper];
};

const parseHex = (value) => {
  if (typeof value !== 'string') return null;
  let hex = value.trim().replace(/^#/, '');
  if (!/^([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(hex)) return null;
  if (hex.length === 3) hex = hex.split('').map((c) => c + c).join('');
  return {
    r: parseInt(hex.slice(0, 2), 16),
    g: parseInt(hex.slice(2, 4), 16),
    b: parseInt(hex.slice(4, 6), 16)
  };
};

export const toHex6 = (value, fallback = '#000000') => {
  const rgb = parseHex(value);
  if (!rgb) return fallback;
  return '#' + [rgb.r, rgb.g, rgb.b].map((n) => n.toString(16).padStart(2, '0')).join('');
};

export const alpha = (value, amount) => {
  const rgb = parseHex(value);
  return rgb ? `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${amount})` : value;
};

export function contrastText(value) {
  const rgb = parseHex(value);
  if (!rgb) return '#ffffff';
  const lum = [rgb.r, rgb.g, rgb.b]
    .map((c) => c / 255)
    .map((c) => (c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)));
  const l = 0.2126 * lum[0] + 0.7152 * lum[1] + 0.0722 * lum[2];
  return l > 0.4 ? 'rgba(0, 0, 0, 0.87)' : '#ffffff';
}

const psKey = (key) => (/^[A-Za-z_][A-Za-z0-9_]*$/.test(key) ? key : `'${String(key).replace(/'/g, "''")}'`);

const psValue = (value, depth) => {
  const pad = '    '.repeat(depth + 1);
  const end = '    '.repeat(depth);
  if (value === null || value === undefined) return '$null';
  if (typeof value === 'boolean') return value ? '$true' : '$false';
  if (typeof value === 'number') return String(value);
  if (typeof value === 'string') return `'${value.replace(/'/g, "''")}'`;
  if (Array.isArray(value)) {
    if (value.length === 0) return '@()';
    return `@(\n${value.map((v) => pad + psValue(v, depth + 1)).join('\n')}\n${end})`;
  }
  const keys = Object.keys(value);
  if (keys.length === 0) return '@{}';
  return `@{\n${keys.map((k) => `${pad}${psKey(k)} = ${psValue(value[k], depth + 1)}`).join('\n')}\n${end}}`;
};

export const toPowerShell = (theme, variableName = 'Theme') => `$${variableName} = ${psValue(prune(theme), 0)}`;

export const copyText = async (text) => {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    const area = document.createElement('textarea');
    area.value = text;
    area.style.position = 'fixed';
    area.style.opacity = '0';
    document.body.appendChild(area);
    area.select();
    const ok = document.execCommand('copy');
    document.body.removeChild(area);
    return ok;
  }
};

// Match popup surfaces to whatever the app body currently renders.
export const surfaceStyle = () => {
  const s = window.getComputedStyle(document.body);
  return { background: s.backgroundColor || '#fff', color: s.color || 'inherit' };
};

export const SELECTION_EVENT = 'chameleon:selection';

export const storageKeyFor = (key) => {
  const scope = key || window.location.pathname.split('/').filter(Boolean)[0] || 'root';
  return `chameleon:selected:${scope}`;
};

export const readSelected = (key) => {
  try {
    return window.localStorage.getItem(storageKeyFor(key)) || '';
  } catch {
    return '';
  }
};

// Persists the choice and tells every picker on this page; other tabs get the native 'storage' event.
export const writeSelected = (key, value) => {
  const fullKey = storageKeyFor(key);
  try {
    if (value) window.localStorage.setItem(fullKey, value);
    else window.localStorage.removeItem(fullKey);
  } catch {
    // Storage may be unavailable (private mode); selection just won't persist.
  }
  window.dispatchEvent(new CustomEvent(SELECTION_EVENT, { detail: { key: fullKey, value: value || '' } }));
};

export const currentVariant = () => {
  try {
    const v = window.localStorage.getItem('theme');
    return v === 'dark' || v === 'light' ? v : '';
  } catch {
    return '';
  }
};
