import type { ComputedIslamicDay, Location } from '@islamic-day-dial/core';

type Props = {
  snapshot: ComputedIslamicDay;
  location: Location;
  timezone: string;
  now: Date;
};

function fmtTime(d: Date): string {
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false });
}

function fmtAngle(deg: number): string {
  return `${deg.toFixed(1)}°`;
}

export function DebugPanel({ snapshot, location, timezone, now }: Props) {
  const { timeline, ring } = snapshot;

  return (
    <div className="debug-panel">
      <h3>Debug</h3>

      <section>
        <h4>Context</h4>
        <dl>
          <dt>Latitude</dt><dd>{location.latitude.toFixed(4)}</dd>
          <dt>Longitude</dt><dd>{location.longitude.toFixed(4)}</dd>
          <dt>Timezone</dt><dd>{timezone}</dd>
          <dt>Local time</dt><dd>{fmtTime(now)}</dd>
        </dl>
      </section>

      <section>
        <h4>Timeline</h4>
        <dl>
          <dt>Maghrib (start)</dt><dd>{fmtTime(timeline.lastMaghrib)}</dd>
          <dt>Isha</dt><dd>{fmtTime(timeline.isha)}</dd>
          <dt>Islamic Midnight</dt><dd>{fmtTime(timeline.islamicMidnight)}</dd>
          <dt>Last Third</dt><dd>{fmtTime(timeline.lastThirdStart)}</dd>
          <dt>Fajr</dt><dd>{fmtTime(timeline.fajr)}</dd>
          <dt>Sunrise</dt><dd>{fmtTime(timeline.sunrise)}</dd>
          <dt>Dhuhr</dt><dd>{fmtTime(timeline.dhuhr)}</dd>
          <dt>Asr</dt><dd>{fmtTime(timeline.asr)}</dd>
          <dt>Maghrib (end)</dt><dd>{fmtTime(timeline.nextMaghrib)}</dd>
        </dl>
      </section>

      <section>
        <h4>State</h4>
        <dl>
          <dt>Current phase</dt><dd>{snapshot.currentPhase}</dd>
          <dt>Next transition</dt><dd>{snapshot.nextTransition.id}</dd>
          <dt>Countdown</dt><dd>{snapshot.countdownMs.toLocaleString()} ms</dd>
          <dt>Progress</dt><dd>{(ring.progress * 100).toFixed(2)}%</dd>
        </dl>
      </section>

      <section>
        <h4>Marker Angles</h4>
        <dl>
          {ring.markers.map(m => (
            <span key={m.id}>
              <dt>{m.id}</dt><dd>{fmtAngle(m.angleDeg)} ({m.kind})</dd>
            </span>
          ))}
        </dl>
      </section>

      <section>
        <h4>Segment Angles</h4>
        <dl>
          {ring.segments.map(s => (
            <span key={s.id}>
              <dt>{s.id}</dt>
              <dd>{fmtAngle(s.startAngleDeg)} → {fmtAngle(s.endAngleDeg)}</dd>
            </span>
          ))}
        </dl>
      </section>
    </div>
  );
}
