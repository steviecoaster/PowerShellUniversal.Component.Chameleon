import React, { useEffect, useMemo, useRef, useState } from 'react';
import { withComponentFeatures } from 'universal-dashboard';
import {
  MODES,
  MUI_DEFAULTS,
  STARTER_THEME,
  alpha,
  copyText,
  getPath,
  normalizeTheme,
  prune,
  resolveColors,
  setPath,
  surfaceStyle,
  toHex6,
  toPowerShell,
  writeSelected
} from './themeUtils';

const PALETTE_GROUPS = [
  {
    title: 'Primary',
    fields: [
      { path: ['primary', 'main'], label: 'Main', fallback: 'primary' },
      { path: ['primary', 'light'], label: 'Light' },
      { path: ['primary', 'dark'], label: 'Dark' },
      { path: ['primary', 'contrastText'], label: 'Contrast text' }
    ]
  },
  {
    title: 'Secondary',
    fields: [
      { path: ['secondary', 'main'], label: 'Main', fallback: 'secondary' },
      { path: ['secondary', 'light'], label: 'Light' },
      { path: ['secondary', 'dark'], label: 'Dark' },
      { path: ['secondary', 'contrastText'], label: 'Contrast text' }
    ]
  },
  {
    title: 'Status',
    fields: [
      { path: ['error', 'main'], label: 'Error', fallback: 'error' },
      { path: ['warning', 'main'], label: 'Warning', fallback: 'warning' },
      { path: ['info', 'main'], label: 'Info', fallback: 'info' },
      { path: ['success', 'main'], label: 'Success', fallback: 'success' }
    ]
  },
  {
    title: 'Surfaces & text',
    fields: [
      { path: ['background', 'default'], label: 'Background', fallback: 'background' },
      { path: ['background', 'paper'], label: 'Paper', fallback: 'paper' },
      { path: ['text', 'primary'], label: 'Text', fallback: 'text' },
      { path: ['text', 'secondary'], label: 'Text secondary', fallback: 'textSecondary' },
      { path: ['divider'], label: 'Divider' }
    ]
  }
];

const FONT_SUGGESTIONS = [
  "'Roboto', 'Helvetica', 'Arial', sans-serif",
  "'Inter', sans-serif",
  "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif",
  "'Open Sans', sans-serif",
  "'Work Sans', sans-serif",
  "'Source Sans Pro', sans-serif",
  "Georgia, 'Times New Roman', serif",
  "'Cascadia Code', Consolas, monospace"
];

// The load endpoint pushes a JSON string (or, defensively, an array/object) via Set-UDElement.
const unwrapResult = (result) => {
  let value = Array.isArray(result) ? result[0] : result;
  if (typeof value === 'string') {
    try {
      value = JSON.parse(value);
    } catch {
      return null;
    }
  }
  return value;
};

const ColorField = ({ label, value, placeholder, onChange }) => {
  const shown = value || placeholder;
  return (
    <label className="chameleon-field">
      <span className="chameleon-label">{label}</span>
      <span className="chameleon-color-input">
        <span className={`chameleon-color-swatch ${shown ? '' : 'is-empty'}`} style={shown ? { background: shown } : undefined}>
          <input
            type="color"
            value={toHex6(shown, '#000000')}
            onChange={(e) => onChange(e.target.value)}
            aria-label={`${label} color picker`}
          />
        </span>
        <input
          type="text"
          value={value || ''}
          placeholder={placeholder || 'auto'}
          onChange={(e) => onChange(e.target.value)}
          spellCheck={false}
        />
        {value ? (
          <button type="button" className="chameleon-clear" title="Reset to default" onClick={() => onChange('')}>
            ×
          </button>
        ) : null}
      </span>
    </label>
  );
};

const Preview = ({ theme, mode }) => {
  const c = resolveColors(theme, mode);
  const section = theme[mode] || {};
  const typography = section.typography || {};
  const radius = getPath(section, ['shape', 'borderRadius']);
  const r = radius === undefined || radius === '' ? 4 : radius;
  const radiusCss = typeof r === 'number' ? `${r}px` : r;
  const fontSize = Number(typography.fontSize) || 14;
  const textTransform = getPath(typography, ['button', 'textTransform']) || 'uppercase';
  const btn = (bg, fg, outlined) => ({
    background: outlined ? 'transparent' : bg,
    color: outlined ? bg : fg,
    border: `1px solid ${outlined ? alpha(bg, 0.5) : bg}`,
    borderRadius: radiusCss,
    textTransform
  });
  const alertStyle = (color) => ({
    background: alpha(color, mode === 'dark' ? 0.18 : 0.12),
    borderLeft: `4px solid ${color}`,
    borderRadius: radiusCss
  });

  return (
    <div
      className="chameleon-preview"
      style={{
        background: c.background,
        color: c.text,
        fontFamily: typography.fontFamily || "'Roboto', 'Helvetica', 'Arial', sans-serif",
        fontSize: `${fontSize}px`,
        borderColor: c.divider
      }}
    >
      <div className="chameleon-preview-appbar" style={{ background: c.primary, color: c.primaryContrast }}>
        <span>☰</span>
        <strong>My App</strong>
        <span className="chameleon-spacer" />
        <span className="chameleon-preview-avatar" style={{ background: c.secondary, color: c.secondaryContrast }}>
          A
        </span>
      </div>
      <div className="chameleon-preview-body">
        <div className="chameleon-preview-card" style={{ background: c.paper, borderRadius: radiusCss, borderColor: c.divider }}>
          <div style={{ fontSize: `${fontSize * 1.45}px`, fontWeight: 500 }}>Card title</div>
          <div style={{ color: c.textSecondary }}>Secondary text sits under the heading.</div>
          <div className="chameleon-preview-row">
            <span className="chameleon-preview-btn" style={btn(c.primary, c.primaryContrast)}>Primary</span>
            <span className="chameleon-preview-btn" style={btn(c.secondary, c.secondaryContrast)}>Secondary</span>
            <span className="chameleon-preview-btn" style={btn(c.primary, c.primaryContrast, true)}>Outlined</span>
          </div>
          <div className="chameleon-preview-input" style={{ borderColor: c.divider, borderRadius: radiusCss }}>
            <span style={{ color: c.textSecondary }}>Text field</span>
            <span style={{ borderBottom: `2px solid ${c.primary}` }} />
          </div>
        </div>
        <div className="chameleon-preview-alerts">
          {['success', 'info', 'warning', 'error'].map((s) => (
            <div key={s} className="chameleon-preview-alert" style={alertStyle(c[s])}>
              <span style={{ color: c[s], fontWeight: 600 }}>●</span> {s.charAt(0).toUpperCase() + s.slice(1)} message
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

const ThemeBuilder = (props) => {
  const { id, name: initialName = '', theme: initialTheme, sources = [], loadResult, onSave, onApply, onReset, onLoad, height } = props || {};

  const [work, setWork] = useState(() => normalizeTheme(initialTheme));
  const [name, setName] = useState(initialName);
  const [source, setSource] = useState('');
  const [savedNames, setSavedNames] = useState([]);
  const [loading, setLoading] = useState(false);
  const [mode, setMode] = useState('light');
  const [tab, setTab] = useState('palette');
  const [live, setLive] = useState(false);
  const [jsonText, setJsonText] = useState('');
  const [jsonError, setJsonError] = useState('');
  const [status, setStatus] = useState(null);
  const [exportOpen, setExportOpen] = useState(false);
  const statusTimer = useRef(null);
  const liveTimer = useRef(null);
  const exportRef = useRef(null);
  const pendingLoad = useRef(null);

  useEffect(() => {
    if (!exportOpen) return undefined;
    const close = (e) => {
      if (exportRef.current && !exportRef.current.contains(e.target)) setExportOpen(false);
    };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, [exportOpen]);

  const initialKey = typeof initialTheme === 'string' ? initialTheme : JSON.stringify(initialTheme || null);
  useEffect(() => {
    setWork(normalizeTheme(initialTheme));
  }, [initialKey]);

  useEffect(() => {
    setName(initialName);
  }, [initialName]);

  const output = useMemo(() => prune(work), [work]);
  const psCode = useMemo(() => toPowerShell(output), [output]);
  const jsonOut = useMemo(() => JSON.stringify(output, null, 2), [output]);

  useEffect(() => {
    if (tab === 'json') {
      setJsonText(jsonOut);
      setJsonError('');
    }
  }, [tab]);

  const flash = (text, kind = 'ok') => {
    setStatus({ text, kind });
    clearTimeout(statusTimer.current);
    statusTimer.current = setTimeout(() => setStatus(null), 3500);
  };

  const apply = async (silent) => {
    if (!onApply) return;
    try {
      await onApply({ theme: JSON.stringify(output), variant: mode });
      // The app now shows the builder's theme, not any picker theme.
      writeSelected(undefined, '');
      if (!silent) flash(`Applied to this app in ${mode} mode (only your browser sees it)`);
    } catch (e) {
      flash(`Apply failed: ${e && e.message ? e.message : e}`, 'error');
    }
  };

  useEffect(() => {
    if (!live) return undefined;
    clearTimeout(liveTimer.current);
    liveTimer.current = setTimeout(() => apply(true), 600);
    return () => clearTimeout(liveTimer.current);
  }, [live, output, mode]);

  const setPalette = (path, value) => setWork((w) => setPath(w, [mode, 'palette', ...path], value));

  // Typography and shape are shared so both modes stay consistent.
  const setShared = (path, value) =>
    setWork((w) => MODES.reduce((acc, m) => setPath(acc, [m, ...path], value), w));

  const copyMode = (from, to) =>
    setWork((w) => setPath(w, [to, 'palette'], { ...(getPath(w, [from, 'palette']) || {}), mode: to }));

  const save = async () => {
    const trimmed = name.trim();
    if (!trimmed) {
      flash('Enter a theme name before saving', 'error');
      return;
    }
    if (!onSave) return;
    try {
      await onSave({ name: trimmed, theme: JSON.stringify(output) });
      setSavedNames((n) => (n.includes(trimmed) ? n : [...n, trimmed]));
      flash(`Saved "${trimmed}"`);
    } catch (e) {
      flash(`Save failed: ${e && e.message ? e.message : e}`, 'error');
    }
  };

  const reset = async () => {
    if (!onReset) return;
    setLive(false);
    try {
      await onReset();
      writeSelected(undefined, '');
      flash('App theme reset to default');
    } catch (e) {
      flash(`Reset failed: ${e && e.message ? e.message : e}`, 'error');
    }
  };

  const loadSource = async (value) => {
    setSource(value);
    if (!value) return;
    if (value === 'starter') {
      setWork(normalizeTheme(STARTER_THEME));
      setName('');
      flash('Loaded the starter theme');
      return;
    }
    if (!onLoad) return;
    setLoading(true);
    pendingLoad.current = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
    try {
      await onLoad({ id, source: value, nonce: pendingLoad.current });
    } catch (e) {
      pendingLoad.current = null;
      setLoading(false);
      flash(`Load failed: ${e && e.message ? e.message : e}`, 'error');
    }
  };

  useEffect(() => {
    if (!loadResult || !loadResult.nonce || loadResult.nonce !== pendingLoad.current) return;
    pendingLoad.current = null;
    setLoading(false);
    const data = unwrapResult(loadResult.payload);
    if (!data || !data.theme) {
      flash('Load failed: theme not found', 'error');
      return;
    }
    setWork(normalizeTheme(data.theme));
    setName(data.name || '');
    flash(`Loaded "${data.label || data.name}". Edit it, then Apply or Save.`);
  }, [loadResult && loadResult.nonce]);

  // Deep link from the Saved Themes page: ?theme=<name>
  useEffect(() => {
    const requested = new URLSearchParams(window.location.search).get('theme');
    if (requested) loadSource(`saved:${requested}`);
  }, []);

  const savedOptions = useMemo(() => {
    const fromServer = sources.filter((s) => s.group === 'Saved');
    const known = fromServer.map((s) => s.value);
    const added = savedNames
      .filter((n) => !known.includes(`saved:${n}`))
      .map((n) => ({ value: `saved:${n}`, label: n, group: 'Saved' }));
    return [...fromServer, ...added];
  }, [sources, savedNames]);
  const builtInOptions = useMemo(() => sources.filter((s) => s.group !== 'Saved'), [sources]);

  const loadJson = () => {
    try {
      setWork(normalizeTheme(JSON.parse(jsonText)));
      setJsonError('');
      flash('JSON loaded');
    } catch (e) {
      setJsonError(e.message);
    }
  };

  const copy = async (text, label) => {
    setExportOpen(false);
    const ok = await copyText(text);
    flash(ok ? `${label} copied to clipboard` : 'Copy failed', ok ? 'ok' : 'error');
  };

  const palette = getPath(work, [mode, 'palette']) || {};
  const shared = work.light || {};
  const defaults = MUI_DEFAULTS[mode];
  const other = mode === 'light' ? 'dark' : 'light';

  return (
    <div id={id} className="chameleon-builder" style={height ? { height } : undefined}>
      <div className="chameleon-toolbar">
        <div className="chameleon-toolbar-group">
          {onLoad ? (
            <select
              className="chameleon-textfield"
              aria-label="Start from"
              value={source}
              disabled={loading}
              onChange={(e) => loadSource(e.target.value)}
            >
              <option value="" disabled>
                {loading ? 'Loading...' : 'Start from...'}
              </option>
              <option value="starter">Starter theme</option>
              {savedOptions.length ? (
                <optgroup label="Saved themes">
                  {savedOptions.map((s) => (
                    <option key={s.value} value={s.value}>
                      {s.label}
                    </option>
                  ))}
                </optgroup>
              ) : null}
              {builtInOptions.length ? (
                <optgroup label="Built-in themes">
                  {builtInOptions.map((s) => (
                    <option key={s.value} value={s.value}>
                      {s.label}
                    </option>
                  ))}
                </optgroup>
              ) : null}
            </select>
          ) : null}
          <input
            className="chameleon-textfield"
            type="text"
            placeholder="Theme name"
            aria-label="Theme name"
            value={name}
            maxLength={64}
            onChange={(e) => setName(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && onSave && save()}
          />
          {onSave ? (
            <button type="button" className="chameleon-btn chameleon-btn-contained" onClick={save}>
              Save
            </button>
          ) : null}
        </div>

        <div className="chameleon-toolbar-group">
          {onApply ? (
            <>
              <span className="chameleon-toolbar-caption">Preview in app</span>
              <button
                type="button"
                className="chameleon-btn chameleon-btn-outlined"
                title={`Apply this theme to the app you are using now, in ${mode} mode. Only your browser is affected.`}
                onClick={() => apply(false)}
              >
                Apply
              </button>
              <label className="chameleon-switch" title="Keep the app in sync with every edit">
                <input type="checkbox" checked={live} onChange={(e) => setLive(e.target.checked)} />
                <span className="chameleon-switch-track" aria-hidden="true" />
                Live
              </label>
              {onReset ? (
                <button
                  type="button"
                  className="chameleon-btn chameleon-btn-text"
                  title="Go back to the app's own theme"
                  onClick={reset}
                >
                  Reset
                </button>
              ) : null}
              <span className="chameleon-divider" aria-hidden="true" />
            </>
          ) : null}
          <div className="chameleon-menu-anchor" ref={exportRef}>
            <button
              type="button"
              className="chameleon-btn chameleon-btn-outlined"
              aria-haspopup="menu"
              aria-expanded={exportOpen}
              onClick={() => setExportOpen((o) => !o)}
            >
              Export <span className="chameleon-caret">▾</span>
            </button>
            {exportOpen ? (
              <ul className="chameleon-menu" role="menu" style={surfaceStyle()}>
                <li role="menuitem" onClick={() => copy(psCode, 'PowerShell')}>
                  Copy as PowerShell
                </li>
                <li role="menuitem" onClick={() => copy(jsonOut, 'JSON')}>
                  Copy as JSON
                </li>
              </ul>
            ) : null}
          </div>
        </div>
      </div>

      {status ? (
        <div className={`chameleon-snackbar chameleon-snackbar-${status.kind}`} role="status">
          {status.text}
        </div>
      ) : null}

      <div className="chameleon-layout">
        <div className="chameleon-editor">
          <div className="chameleon-tabs" role="tablist">
            {[
              ['palette', 'Palette'],
              ['typography', 'Typography & shape'],
              ['code', 'PowerShell'],
              ['json', 'JSON']
            ].map(([key, label]) => (
              <button
                key={key}
                type="button"
                role="tab"
                aria-selected={tab === key}
                className={`chameleon-tab ${tab === key ? 'is-active' : ''}`}
                onClick={() => setTab(key)}
              >
                {label}
              </button>
            ))}
          </div>

          <div className="chameleon-modes">
            {MODES.map((m) => (
              <button
                key={m}
                type="button"
                className={`chameleon-chip ${mode === m ? 'is-active' : ''}`}
                onClick={() => setMode(m)}
              >
                {m === 'light' ? '☀ Light' : '☾ Dark'}
              </button>
            ))}
            {tab === 'palette' ? (
              <button type="button" className="chameleon-link" onClick={() => copyMode(mode, other)}>
                Copy {mode} palette to {other}
              </button>
            ) : null}
          </div>

          {tab === 'palette' ? (
            <div className="chameleon-groups">
              {PALETTE_GROUPS.map((group) => (
                <fieldset key={group.title} className="chameleon-group">
                  <legend>{group.title}</legend>
                  {group.fields.map((f) => (
                    <ColorField
                      key={f.path.join('.')}
                      label={f.label}
                      value={getPath(palette, f.path)}
                      placeholder={f.fallback ? defaults[f.fallback] : ''}
                      onChange={(v) => setPalette(f.path, v)}
                    />
                  ))}
                </fieldset>
              ))}
            </div>
          ) : null}

          {tab === 'typography' ? (
            <div className="chameleon-groups">
              <fieldset className="chameleon-group">
                <legend>Typography</legend>
                <label className="chameleon-field">
                  <span className="chameleon-label">Font family</span>
                  <input
                    type="text"
                    list={`${id}-fonts`}
                    value={getPath(shared, ['typography', 'fontFamily']) || ''}
                    placeholder="'Roboto', 'Helvetica', 'Arial', sans-serif"
                    onChange={(e) => setShared(['typography', 'fontFamily'], e.target.value)}
                  />
                  <datalist id={`${id}-fonts`}>
                    {FONT_SUGGESTIONS.map((f) => (
                      <option key={f} value={f} />
                    ))}
                  </datalist>
                </label>
                <label className="chameleon-field">
                  <span className="chameleon-label">Base font size (px)</span>
                  <input
                    type="number"
                    min="8"
                    max="32"
                    value={getPath(shared, ['typography', 'fontSize']) ?? ''}
                    placeholder="14"
                    onChange={(e) => setShared(['typography', 'fontSize'], e.target.value === '' ? '' : Number(e.target.value))}
                  />
                </label>
                <label className="chameleon-field">
                  <span className="chameleon-label">Button text</span>
                  <select
                    value={getPath(shared, ['typography', 'button', 'textTransform']) || ''}
                    onChange={(e) => setShared(['typography', 'button', 'textTransform'], e.target.value)}
                  >
                    <option value="">Default (UPPERCASE)</option>
                    <option value="none">As typed</option>
                    <option value="capitalize">Capitalize</option>
                    <option value="lowercase">lowercase</option>
                  </select>
                </label>
              </fieldset>
              <fieldset className="chameleon-group">
                <legend>Shape</legend>
                <label className="chameleon-field">
                  <span className="chameleon-label">Border radius ({getPath(shared, ['shape', 'borderRadius']) ?? 4})</span>
                  <input
                    type="range"
                    min="0"
                    max="24"
                    value={Number(getPath(shared, ['shape', 'borderRadius']) ?? 4)}
                    onChange={(e) => setShared(['shape', 'borderRadius'], Number(e.target.value))}
                  />
                </label>
              </fieldset>
            </div>
          ) : null}

          {tab === 'code' ? <pre className="chameleon-code">{psCode}</pre> : null}

          {tab === 'json' ? (
            <div className="chameleon-json">
              <textarea
                value={jsonText}
                spellCheck={false}
                onChange={(e) => {
                  setJsonText(e.target.value);
                  setJsonError('');
                }}
              />
              {jsonError ? <div className="chameleon-status chameleon-status-error">{jsonError}</div> : null}
              <div className="chameleon-row">
                <button type="button" className="chameleon-btn chameleon-btn-contained" onClick={loadJson}>
                  Load JSON
                </button>
                <button type="button" className="chameleon-btn chameleon-btn-outlined" onClick={() => setJsonText(jsonOut)}>
                  Revert
                </button>
              </div>
            </div>
          ) : null}
        </div>

        <Preview theme={work} mode={mode} />
      </div>
    </div>
  );
};

export default withComponentFeatures(ThemeBuilder);
