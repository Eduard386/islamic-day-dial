import { describe, it, expect } from 'vitest';
import { polarToXY, describeArc } from '../geometry.js';

describe('polarToXY', () => {
  const cx = 100;
  const cy = 100;
  const r = 50;

  it('0° is at top (12 o\'clock)', () => {
    const { x, y } = polarToXY(cx, cy, r, 0);
    expect(x).toBeCloseTo(100);
    expect(y).toBeCloseTo(50);
  });

  it('90° is at right (3 o\'clock)', () => {
    const { x, y } = polarToXY(cx, cy, r, 90);
    expect(x).toBeCloseTo(150);
    expect(y).toBeCloseTo(100);
  });

  it('180° is at bottom (6 o\'clock)', () => {
    const { x, y } = polarToXY(cx, cy, r, 180);
    expect(x).toBeCloseTo(100);
    expect(y).toBeCloseTo(150);
  });

  it('270° is at left (9 o\'clock)', () => {
    const { x, y } = polarToXY(cx, cy, r, 270);
    expect(x).toBeCloseTo(50);
    expect(y).toBeCloseTo(100);
  });

  it('360° wraps back to top', () => {
    const { x, y } = polarToXY(cx, cy, r, 360);
    expect(x).toBeCloseTo(100);
    expect(y).toBeCloseTo(50);
  });
});

describe('describeArc', () => {
  const cx = 100;
  const cy = 100;
  const r = 50;

  it('returns empty string for zero span', () => {
    expect(describeArc(cx, cy, r, 45, 45)).toBe('');
  });

  it('returns empty string for negative span', () => {
    expect(describeArc(cx, cy, r, 90, 45)).toBe('');
  });

  it('returns arc path for small span (<180°)', () => {
    const path = describeArc(cx, cy, r, 0, 90);
    expect(path).toMatch(/^M .+ A .+ 0 0 1 .+$/);
  });

  it('returns arc path with large-arc flag for span >180°', () => {
    const path = describeArc(cx, cy, r, 0, 270);
    expect(path).toMatch(/A .+ 0 1 1/);
  });

  it('returns full circle path for 360° span', () => {
    const path = describeArc(cx, cy, r, 0, 360);
    expect(path).toContain('A 50 50 0 1 1');
    expect(path.match(/A/g)?.length).toBe(2);
  });
});
