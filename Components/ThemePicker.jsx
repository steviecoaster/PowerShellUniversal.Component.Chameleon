import React, { useEffect, useRef, useState } from 'react';
import { withComponentFeatures } from 'universal-dashboard';
import { SELECTION_EVENT, currentVariant, readSelected, storageKeyFor, surfaceStyle, swatchesFor, writeSelected } from './themeUtils';

const Swatches = ({ item, mode }) => {
  const colors = item.colors && item.colors.length ? item.colors : swatchesFor(item.theme, mode);
  return (
    <span className="chameleon-swatches" aria-hidden="true">
      {colors.slice(0, 4).map((c, i) => (
        <span key={i} style={{ background: c }} />
      ))}
    </span>
  );
};

const ThemePicker = (props) => {
  const {
    id,
    themes = [],
    label = 'Theme',
    variant = 'menu',
    showReset = true,
    storageKey,
    onApply,
    onReset,
    onChange
  } = props || {};

  const [selected, setSelected] = useState(() => readSelected(storageKey));
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const rootRef = useRef(null);
  const mode = currentVariant() || 'light';

  useEffect(() => {
    const fullKey = storageKeyFor(storageKey);
    const onLocal = (e) => e.detail && e.detail.key === fullKey && setSelected(e.detail.value);
    const onOtherTab = (e) => e.key === fullKey && setSelected(e.newValue || '');
    window.addEventListener(SELECTION_EVENT, onLocal);
    window.addEventListener('storage', onOtherTab);
    return () => {
      window.removeEventListener(SELECTION_EVENT, onLocal);
      window.removeEventListener('storage', onOtherTab);
    };
  }, [storageKey]);

  useEffect(() => {
    if (!open) return undefined;
    const close = (e) => {
      if (rootRef.current && !rootRef.current.contains(e.target)) setOpen(false);
    };
    const esc = (e) => e.key === 'Escape' && setOpen(false);
    document.addEventListener('mousedown', close);
    document.addEventListener('keydown', esc);
    return () => {
      document.removeEventListener('mousedown', close);
      document.removeEventListener('keydown', esc);
    };
  }, [open]);

  const choose = async (item) => {
    setOpen(false);
    if (!item || busy) return;
    setBusy(true);
    try {
      if (onApply) {
        const theme = item.builtin ? '' : typeof item.theme === 'string' ? item.theme : JSON.stringify(item.theme || {});
        await onApply({ name: item.name, builtin: !!item.builtin, theme, variant: currentVariant() });
      }
      setSelected(item.name);
      writeSelected(storageKey, item.name);
      if (onChange) await onChange(item.name);
    } finally {
      setBusy(false);
    }
  };

  const reset = async () => {
    setOpen(false);
    setBusy(true);
    try {
      if (onReset) await onReset();
      setSelected('');
      writeSelected(storageKey, '');
      if (onChange) await onChange('');
    } finally {
      setBusy(false);
    }
  };

  const current = themes.find((t) => t.name === selected);
  const groups = [
    { label: 'Saved', items: themes.filter((t) => !t.builtin) },
    { label: 'Built-in', items: themes.filter((t) => t.builtin) }
  ].filter((group) => group.items.length);

  if (variant === 'select') {
    return (
      <label id={id} className="chameleon-picker chameleon-picker-select">
        {label ? <span className="chameleon-label">{label}</span> : null}
        <select
          value={current ? current.name : ''}
          disabled={busy}
          onChange={(e) => (e.target.value ? choose(themes.find((t) => t.name === e.target.value)) : reset())}
        >
          <option value="">{showReset ? 'Default' : 'Choose a theme…'}</option>
          {groups.map((group) => (
            <optgroup key={group.label} label={group.label}>
              {group.items.map((t) => (
                <option key={t.name} value={t.name}>
                  {t.name}
                </option>
              ))}
            </optgroup>
          ))}
        </select>
      </label>
    );
  }

  if (variant === 'grid') {
    return (
      <div id={id} className="chameleon-picker chameleon-picker-grid" role="listbox" aria-label={label}>
        {showReset ? (
          <button
            type="button"
            role="option"
            aria-selected={!current}
            className={`chameleon-card ${!current ? 'is-selected' : ''}`}
            disabled={busy}
            onClick={reset}
          >
            <span className="chameleon-swatches chameleon-swatches-empty" aria-hidden="true">
              <span />
            </span>
            <span className="chameleon-card-name">Default</span>
          </button>
        ) : null}
        {themes.map((t) => (
          <button
            key={t.name}
            type="button"
            role="option"
            aria-selected={selected === t.name}
            title={t.description || t.name}
            className={`chameleon-card ${selected === t.name ? 'is-selected' : ''}`}
            disabled={busy}
            onClick={() => choose(t)}
          >
            <Swatches item={t} mode={mode} />
            <span className="chameleon-card-name">{t.name}</span>
          </button>
        ))}
      </div>
    );
  }

  return (
    <div id={id} ref={rootRef} className="chameleon-picker chameleon-picker-menu">
      <button
        type="button"
        className="chameleon-picker-button"
        aria-haspopup="listbox"
        aria-expanded={open}
        disabled={busy}
        onClick={() => setOpen((o) => !o)}
      >
        {current ? <Swatches item={current} mode={mode} /> : <span className="chameleon-picker-icon">🎨</span>}
        <span>{current ? current.name : label}</span>
        <span className="chameleon-caret">▾</span>
      </button>
      {open ? (
        <ul className="chameleon-menu" role="listbox" aria-label={label} style={surfaceStyle()}>
          {showReset ? (
            <li role="option" aria-selected={!current} className={!current ? 'is-selected' : ''} onClick={reset}>
              <span className="chameleon-swatches chameleon-swatches-empty" aria-hidden="true">
                <span />
              </span>
              Default
            </li>
          ) : null}
          {groups.map((group) => (
            <li key={group.label} className="chameleon-menu-group" role="presentation">
              <ul role="group" aria-label={group.label}>
                <li className="chameleon-menu-heading" role="presentation">{group.label}</li>
                {group.items.map((t) => (
                  <li
                    key={t.name}
                    role="option"
                    aria-selected={selected === t.name}
                    title={t.description || t.name}
                    className={selected === t.name ? 'is-selected' : ''}
                    onClick={() => choose(t)}
                  >
                    <Swatches item={t} mode={mode} />
                    {t.name}
                  </li>
                ))}
              </ul>
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  );
};

export default withComponentFeatures(ThemePicker);
