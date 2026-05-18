import React, { useMemo, useReducer } from 'react';

import './tilawa_app_prototype.css';

const navItems = [
  { label: 'Quran', icon: 'book', active: true },
  { label: 'Prayer', icon: 'sun' },
  { label: 'Reciters', icon: 'audio' },
  { label: 'Athkar', icon: 'spark' },
  { label: 'Qibla', icon: 'compass' },
];

const quickActions = [
  { label: 'Continue Al-Kahf', meta: 'Ayah 18', icon: 'book' },
  { label: 'Fajr Reminder', meta: '04:23', icon: 'sun' },
  { label: 'Evening Athkar', meta: '31 left', icon: 'spark' },
];

const reciters = [
  {
    name: 'Mishary Rashid Alafasy',
    meta: 'Hafs • 114 surahs',
    progress: '82%',
  },
  {
    name: 'Abdul Basit',
    meta: 'Murattal • offline ready',
    progress: '47%',
  },
];

const verses = [
  {
    marker: '1',
    arabic: 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ',
    translation: 'In the name of Allah, the Most Compassionate, Most Merciful.',
  },
  {
    marker: '2',
    arabic: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    translation: 'All praise is for Allah, Lord of all worlds.',
  },
];

const prayerTimes = [
  { label: 'Fajr', value: '04:23' },
  { label: 'Dhuhr', value: '12:08' },
  { label: 'Asr', value: '15:31' },
];

const playerDurations = ['18:24', '20:11', '24:08', '32:10'];

function clampPercent(value) {
  const numeric = Number(value);
  if (Number.isNaN(numeric)) {
    return 0;
  }
  return Math.min(100, Math.max(0, Math.round(numeric)));
}

function prototypeReducer(state, action) {
  switch (action.type) {
    case 'setActiveNav':
      return { ...state, activePage: action.label };
    case 'setFocusedAction':
      return { ...state, focusedAction: action.label };
    case 'setActiveVerse':
      return { ...state, activeVerse: action.marker };
    case 'setActivePrayer':
      return { ...state, activePrayer: action.label };
    case 'setActiveReciter':
      return { ...state, activeReciter: action.name };
    case 'togglePlayer':
      return { ...state, isPlaying: !state.isPlaying };
    case 'seekTo':
      return { ...state, seekPercent: clampPercent(action.value) };
    case 'playerNext': {
      const nextIndex = (state.trackIndex + 1) % playerDurations.length;
      return {
        ...state,
        trackIndex: nextIndex,
        seekPercent: clampPercent(((nextIndex + 1) / playerDurations.length) * 100),
      };
    }
    case 'playerPrevious': {
      const previousIndex =
        (state.trackIndex - 1 + playerDurations.length) %
        playerDurations.length;
      return {
        ...state,
        trackIndex: previousIndex,
        seekPercent: clampPercent(
          ((previousIndex + 1) / playerDurations.length) * 100,
        ),
      };
    }
    default:
      return state;
  }
}

export default function TilawaAppPrototype() {
  const [state, dispatch] = useReducer(prototypeReducer, {
    activePage: 'Quran',
    focusedAction: quickActions[0].label,
    activeVerse: verses[0].marker,
    activePrayer: 'Dhuhr',
    activeReciter: reciters[0].name,
    isPlaying: true,
    seekPercent: 57,
    trackIndex: 0,
  });

  const activeTrackDuration = useMemo(
    () => playerDurations[state.trackIndex],
    [state.trackIndex],
  );

  return (
    <main className="tilawa-prototype" aria-label="Tilawa premium prototype">
      <section className="prototype-shell">
        <section className="app-surface">
          <header className="top-bar">
            <div>
              <p className="eyebrow">Assalamu alaikum</p>
              <h1>{pageTitleFor(state.activePage)}</h1>
            </div>
            <div className="top-actions">
              <button className="icon-button" type="button" aria-label="Search">
                <Icon name="search" />
              </button>
              <button
                className="avatar-button"
                type="button"
                aria-label="Open profile"
              >
                MK
              </button>
            </div>
          </header>

          <PageViewport
            activePage={state.activePage}
            activeVerse={state.activeVerse}
            activePrayer={state.activePrayer}
            activeReciter={state.activeReciter}
            focusedAction={state.focusedAction}
            onSelectAction={(label) => {
              dispatch({ type: 'setFocusedAction', label });
            }}
            onSelectVerse={(marker) => {
              dispatch({ type: 'setActiveVerse', marker });
            }}
            onSelectPrayer={(label) => {
              dispatch({ type: 'setActivePrayer', label });
            }}
            onSelectReciter={(name) => {
              dispatch({ type: 'setActiveReciter', name });
            }}
          />

          <BottomNav
            activePage={state.activePage}
            onSelectPage={(label) => {
              dispatch({ type: 'setActiveNav', label });
            }}
          />
        </section>

        {state.activePage === 'Quran' ? (
          <ExpandedPlayer
            isPlaying={state.isPlaying}
            seekPercent={state.seekPercent}
            totalDuration={activeTrackDuration}
            onTogglePlay={() => {
              dispatch({ type: 'togglePlayer' });
            }}
            onSeek={(value) => {
              dispatch({ type: 'seekTo', value });
            }}
            onNext={() => {
              dispatch({ type: 'playerNext' });
            }}
            onPrevious={() => {
              dispatch({ type: 'playerPrevious' });
            }}
          />
        ) : null}
      </section>
    </main>
  );
}

function pageTitleFor(page) {
  switch (page) {
    case 'Prayer':
      return 'Prayer';
    case 'Reciters':
      return 'Reciters';
    case 'Athkar':
      return 'Athkar';
    case 'Qibla':
      return 'Qibla';
    default:
      return 'Tilawa';
  }
}

function PageViewport({
  activePage,
  activeVerse,
  activePrayer,
  activeReciter,
  focusedAction,
  onSelectAction,
  onSelectVerse,
  onSelectPrayer,
  onSelectReciter,
}) {
  switch (activePage) {
    case 'Prayer':
      return (
        <div className="page-stage page-prayer">
          <PrayerPage activePrayer={activePrayer} onSelectPrayer={onSelectPrayer} />
        </div>
      );
    case 'Reciters':
      return (
        <div className="page-stage page-reciters">
          <RecitersPage
            activeReciter={activeReciter}
            onSelectReciter={onSelectReciter}
          />
        </div>
      );
    case 'Athkar':
      return (
        <div className="page-stage page-athkar">
          <AthkarPage
            focusedAction={focusedAction}
            onSelectAction={onSelectAction}
          />
        </div>
      );
    case 'Qibla':
      return (
        <div className="page-stage page-qibla">
          <QiblaPage />
        </div>
      );
    default:
      return (
        <div className="page-stage page-quran">
          <QuranPage
            activeVerse={activeVerse}
            focusedAction={focusedAction}
            onSelectAction={onSelectAction}
            onSelectVerse={onSelectVerse}
          />
        </div>
      );
  }
}

function BottomNav({ activePage, onSelectPage }) {
  return (
    <nav className="bottom-nav" aria-label="Bottom navigation">
      {navItems.map((item) => (
        <button
          key={item.label}
          className={`bottom-nav-item${
            item.label === activePage ? ' is-active' : ''
          }`}
          type="button"
          aria-current={item.label === activePage ? 'page' : undefined}
          onClick={() => {
            onSelectPage(item.label);
          }}
        >
          <Icon name={item.icon} />
          <span>{item.label}</span>
        </button>
      ))}
    </nav>
  );
}

function QuranPage({ activeVerse, focusedAction, onSelectAction, onSelectVerse }) {
  return (
    <div className="page-layout page-layout-quran">
      <HeroPanel />
      <QuickActionRail
        focusedAction={focusedAction}
        onSelectAction={onSelectAction}
      />
      <QuranReaderCard activeVerse={activeVerse} onSelectVerse={onSelectVerse} />
    </div>
  );
}

function PrayerPage({ activePrayer, onSelectPrayer }) {
  return (
    <div className="page-layout page-layout-single">
      <section className="page-header-card">
        <p className="eyebrow">Prayer page</p>
        <h2>Track the next prayer and the day&apos;s rhythm.</h2>
        <p>
          Keep the current prayer highlighted, with a quick glance at the
          surrounding times.
        </p>
      </section>
      <PrayerCard activePrayer={activePrayer} onSelectPrayer={onSelectPrayer} />
      <section className="page-info-card">
        <h3>Prayer notes</h3>
        <p>
          The active prayer changes the header and chips immediately, so the
          page always reflects your current focus.
        </p>
      </section>
    </div>
  );
}

function RecitersPage({ activeReciter, onSelectReciter }) {
  return (
    <div className="page-layout page-layout-single">
      <section className="page-header-card">
        <p className="eyebrow">Reciters page</p>
        <h2>Choose a reciter and keep the selection visible.</h2>
        <p>
          Tap any row to set the active reciter and mirror that choice across
          the page.
        </p>
      </section>
      <ReciterPanel
        activeReciter={activeReciter}
        onSelectReciter={onSelectReciter}
      />
      <section className="page-info-card">
        <h3>Reciter focus</h3>
        <p>
          The active row stays highlighted so the selection is easy to verify.
        </p>
      </section>
    </div>
  );
}

function AthkarPage({ focusedAction, onSelectAction }) {
  return (
    <div className="page-layout page-layout-single">
      <section className="page-header-card">
        <p className="eyebrow">Athkar page</p>
        <h2>Keep a small set of remembrances within reach.</h2>
        <p>
          The quick-action rail behaves like a compact dhikr deck and keeps the
          selected item obvious.
        </p>
      </section>
      <section className="athkar-panel">
        <div className="athkar-counter">
          <strong>31</strong>
          <span>phrases remaining</span>
        </div>
        <QuickActionRail
          focusedAction={focusedAction}
          onSelectAction={onSelectAction}
        />
      </section>
    </div>
  );
}

function QiblaPage() {
  return (
    <div className="page-layout page-layout-single">
      <section className="page-header-card">
        <p className="eyebrow">Qibla page</p>
        <h2>Orientation stays calm and easy to read.</h2>
        <p>
          The compass state is isolated here so the page feels distinct from the
          reading and prayer views.
        </p>
      </section>
      <FocusPanel />
      <section className="page-info-card">
        <h3>Orientation</h3>
        <p>
          Keep the phone level and wait for the compass to settle before
          starting prayer.
        </p>
      </section>
    </div>
  );
}

function HeroPanel() {
  return (
    <section className="hero-panel" aria-labelledby="daily-intention-title">
      <div className="geometry-field" aria-hidden="true">
        <span className="arch arch-one" />
        <span className="arch arch-two" />
        <span className="compass-line line-one" />
        <span className="compass-line line-two" />
      </div>
      <div className="hero-copy">
        <p className="eyebrow">Today&apos;s calm path</p>
        <h2 id="daily-intention-title">Read, listen, remember.</h2>
        <p>
          A quiet daily flow for Quran reading, prayer awareness, and dhikr
          without visual noise.
        </p>
      </div>
      <div className="hero-stats" aria-label="Daily progress">
        <Metric label="Quran" value="18 min" />
        <Metric label="Athkar" value="31" />
        <Metric label="Next" value="Dhuhr" />
      </div>
    </section>
  );
}

function QuickActionRail({ focusedAction, onSelectAction }) {
  return (
    <section className="quick-rail" aria-label="Quick actions">
      {quickActions.map((action) => (
        <button
          className={`quick-card${
            action.label === focusedAction ? ' is-active' : ''
          }`}
          key={action.label}
          type="button"
          aria-pressed={action.label === focusedAction}
          onClick={() => {
            onSelectAction(action.label);
          }}
        >
          <span className="icon-box">
            <Icon name={action.icon} />
          </span>
          <span>
            <strong>{action.label}</strong>
            <small>{action.meta}</small>
          </span>
        </button>
      ))}
    </section>
  );
}

function QuranReaderCard({ activeVerse, onSelectVerse }) {
  return (
    <section className="reader-card" aria-labelledby="reader-title">
      <div className="section-header">
        <div>
          <p className="eyebrow">Continue reading</p>
          <h2 id="reader-title">Surah Al-Fatihah</h2>
        </div>
        <button className="quiet-button" type="button">
          Mushaf
        </button>
      </div>

      <div className="verse-stack" dir="rtl" lang="ar">
        {verses.map((verse) => (
          <article
            className={`verse-row${
              verse.marker === activeVerse ? ' is-active' : ''
            }`}
            key={verse.marker}
            onClick={() => {
              onSelectVerse(verse.marker);
            }}
            onKeyDown={(event) => {
              if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                onSelectVerse(verse.marker);
              }
            }}
            role="button"
            tabIndex={0}
            aria-current={verse.marker === activeVerse ? 'true' : undefined}
          >
            <span className="ayah-marker">{verse.marker}</span>
            <p>{verse.arabic}</p>
          </article>
        ))}
      </div>

      <div className="translation-stack">
        {verses.map((verse) => (
          <p key={verse.marker}>
            <span>{verse.marker}</span>
            {verse.translation}
          </p>
        ))}
      </div>
    </section>
  );
}

function PrayerCard({ activePrayer, onSelectPrayer }) {
  const selectedPrayer =
    prayerTimes.find((item) => item.label === activePrayer) ?? prayerTimes[0];

  return (
    <section className="prayer-card" aria-labelledby="prayer-title">
      <div className="section-header compact">
        <div>
          <p className="eyebrow">Next prayer</p>
          <h2 id="prayer-title">{selectedPrayer.label}</h2>
        </div>
        <span className="status-chip">{selectedPrayer.value}</span>
      </div>
      <div className="horizon" aria-hidden="true">
        <span />
      </div>
      <div className="prayer-times">
        {prayerTimes.map((item) => (
          <TimePill
            key={item.label}
            label={item.label}
            value={item.value}
            active={item.label === activePrayer}
            onSelect={() => {
              onSelectPrayer(item.label);
            }}
          />
        ))}
      </div>
    </section>
  );
}

function ReciterPanel({ activeReciter, onSelectReciter }) {
  return (
    <section className="reciter-panel" aria-labelledby="reciters-title">
      <div className="section-header compact">
        <div>
          <p className="eyebrow">Listening</p>
          <h2 id="reciters-title">Reciters</h2>
        </div>
        <button className="icon-button small" type="button" aria-label="Filter">
          <Icon name="sliders" />
        </button>
      </div>
      <div className="reciter-list">
        {reciters.map((reciter) => (
          <article
            className={`reciter-row${
              reciter.name === activeReciter ? ' is-active' : ''
            }`}
            key={reciter.name}
            onClick={() => {
              onSelectReciter(reciter.name);
            }}
            onKeyDown={(event) => {
              if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault();
                onSelectReciter(reciter.name);
              }
            }}
            role="button"
            tabIndex={0}
            aria-current={reciter.name === activeReciter ? 'true' : undefined}
          >
            <span className="reciter-art" aria-hidden="true">
              <Icon name="audio" />
            </span>
            <div>
              <strong>{reciter.name}</strong>
              <small>{reciter.meta}</small>
            </div>
            <span className="progress-pill">{reciter.progress}</span>
          </article>
        ))}
      </div>
    </section>
  );
}

function FocusPanel() {
  return (
    <section className="focus-panel" aria-labelledby="focus-title">
      <div className="state-visual" aria-hidden="true">
        <Icon name="compass" />
      </div>
      <h2 id="focus-title">Qibla ready</h2>
      <p>Compass calibrated. Keep the phone level for a quieter reading.</p>
      <button className="tonal-button" type="button">
        Open Qibla
      </button>
    </section>
  );
}

function ExpandedPlayer({
  isPlaying,
  seekPercent,
  totalDuration,
  onTogglePlay,
  onSeek,
  onNext,
  onPrevious,
}) {
  return (
    <section className="player-sheet" aria-label="Expanded audio player">
      <div className="player-background" aria-hidden="true" />
      <div className="sheet-handle" aria-hidden="true" />
      <div className="player-content">
        <div className="player-artwork" aria-hidden="true">
          <Icon name="book" />
        </div>
        <div className="player-meta">
          <p className="eyebrow">Now playing</p>
          <h2>Surah Al-Kahf</h2>
          <p>Mishary Rashid Alafasy</p>
        </div>
        <div className="seek-area" aria-label="Playback progress">
          <span>18:24</span>
          <div className="seek-track">
            <span style={{ width: `${seekPercent}%` }} />
          </div>
          <span>{totalDuration}</span>
        </div>
        <input
          aria-label="Seek position"
          className="seek-input"
          max="100"
          min="0"
          onChange={(event) => {
            onSeek(event.target.value);
          }}
          type="range"
          value={seekPercent}
        />
        <div className="player-controls">
          <button
            className="icon-button"
            type="button"
            aria-label="Previous"
            onClick={onPrevious}
          >
            <Icon name="previous" />
          </button>
          <button
            className="play-button"
            type="button"
            aria-label={isPlaying ? 'Pause' : 'Play'}
            onClick={onTogglePlay}
          >
            <Icon name={isPlaying ? 'pause' : 'play'} />
          </button>
          <button
            className="icon-button"
            type="button"
            aria-label="Next"
            onClick={onNext}
          >
            <Icon name="next" />
          </button>
          <button className="icon-button" type="button" aria-label="Sleep timer">
            <Icon name="timer" />
          </button>
        </div>
      </div>
    </section>
  );
}

function Metric({ label, value }) {
  return (
    <div className="metric">
      <strong>{value}</strong>
      <span>{label}</span>
    </div>
  );
}

function TimePill({ label, value, active = false, onSelect }) {
  return (
    <button
      className={`time-pill${active ? ' is-active' : ''}`}
      type="button"
      aria-pressed={active}
      onClick={onSelect}
    >
      <span>{label}</span>
      <strong>{value}</strong>
    </button>
  );
}

function Icon({ name }) {
  const paths = {
    audio: 'M9 18V5l12-2v13M9 18a3 3 0 1 1-6 0 3 3 0 0 1 6 0Zm12-2a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z',
    book: 'M4 5.5A2.5 2.5 0 0 1 6.5 3H20v16H7a3 3 0 0 0-3 3V5.5Zm0 0V22m4-15h8m-8 4h8',
    compass: 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20Zm4-14-2.2 5.8L8 16l2.2-5.8L16 8Z',
    next: 'm5 5 8 7-8 7V5Zm10 0h3v14h-3V5Z',
    pause: 'M7 5h4v14H7V5Zm6 0h4v14h-4V5Z',
    play: 'm8 5 11 7-11 7V5Z',
    previous: 'M19 5v14l-8-7 8-7ZM6 5h3v14H6V5Z',
    search: 'm21 21-4.3-4.3M10.8 18a7.2 7.2 0 1 1 0-14.4 7.2 7.2 0 0 1 0 14.4Z',
    sliders: 'M4 7h10m4 0h2M4 17h2m4 0h10M8 5v4m8 6v4',
    spark: 'm12 2 1.8 6.2L20 10l-6.2 1.8L12 18l-1.8-6.2L4 10l6.2-1.8L12 2Zm7 13 1 3 3 1-3 1-1 3-1-3-3-1 3-1 1-3Z',
    sun: 'M12 18a6 6 0 1 0 0-12 6 6 0 0 0 0 12Zm0-16v2m0 16v2M4.9 4.9l1.4 1.4m11.4 11.4 1.4 1.4M2 12h2m16 0h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4',
    timer: 'M10 2h4m-2 8v5l3 2m5-4a8 8 0 1 1-16 0 8 8 0 0 1 16 0Z',
  };

  return (
    <svg
      aria-hidden="true"
      className="icon"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="1.8"
    >
      <path d={paths[name]} />
    </svg>
  );
}
