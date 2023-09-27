import * as E from "fp-ts/Eq";
import * as N from "fp-ts/number";
import { Monoid, struct } from "fp-ts/Monoid";

export interface Vector {
  x: number;
  y: number;
}

export const Semigroup: Monoid<Vector> = struct<Vector>({
  x: N.MonoidSum,
  y: N.MonoidSum,
});

export const Eq: E.Eq<Vector> = {
  equals: (a, b) => a.x === b.x && a.y === b.y,
};

export const Abs = (point: Vector) => Math.abs(point.x) + Math.abs(point.y);
export const MaxLeg = (point: Vector) =>
  Math.max(Math.abs(point.x), Math.abs(point.y));

export const NormalizedStep = (point: Vector) => ({
  x: point.x === 0 ? 0 : point.x / Math.abs(point.x),
  y: point.y === 0 ? 0 : point.y / Math.abs(point.y),
});
export const Negative = (point: Vector) => ({ x: -point.x, y: -point.y });
