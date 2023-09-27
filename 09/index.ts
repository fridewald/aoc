import * as Console from "fp-ts/Console";
import * as E from "fp-ts/Either";
import { flow, pipe } from "fp-ts/function";
import * as IO from "fp-ts/IO";
import * as IOE from "fp-ts/IOEither";
import * as O from "fp-ts/Option";
import * as S from "fp-ts/string";
import * as t from "io-ts";
import * as RA from "../types/ReadonlyArray";
import * as V from "../types/Vector";
import { readInput } from "../utils/readInput";

const NumberCodec = new t.Type<number, string, string>(
  "NumberCodec",
  t.number.is,
  (s, c) => {
    const n = parseInt(s);
    return isNaN(n) ? t.failure(s, c) : t.success(n);
  },
  String
);
const DirectionCodec = t.keyof({ R: null, L: null, U: null, D: null });
type Direction = t.TypeOf<typeof DirectionCodec>;

const InstructionCodec = t.array(
  t.tuple([DirectionCodec, t.string.pipe(NumberCodec, "NumberFromString")])
);

type Instruction = t.TypeOf<typeof InstructionCodec>;

enum Errors {
  InvalidInput = "Invalid input",
  WrongDirection = "Step is too long",
  EmptyArray = "Empty array",
}

const parseInput = (fileBuffer: Buffer): t.Validation<Instruction> => {
  return pipe(
    fileBuffer.toString(),
    S.trim,
    S.split("\n"),
    RA.map(S.split(" ")),
    InstructionCodec.decode
  );
};

const zeroVector = { x: 0, y: 0 };

type TailState = { tailToHeadVec: V.Vector; tailPosition: V.Vector };

const step = (direction: Direction) => {
  switch (direction) {
    case "R":
      return { x: 1, y: 0 };
    case "L":
      return { x: -1, y: 0 };
    case "U":
      return { x: 0, y: 1 };
    case "D":
      return { x: 0, y: -1 };
  }
};
const calcNextMove = (
  nextHead: V.Vector
): E.Either<Errors.WrongDirection, V.Vector> => {
  switch (V.MaxLeg(nextHead)) {
    case 0:
    case 1:
      return E.right(zeroVector);
    case 2:
      return E.right(V.NormalizedStep(nextHead));
    default:
      return E.left(Errors.WrongDirection);
  }
};

const updateTailWithDirection =
  (direction: Direction) =>
  ({
    tailToHeadVec,
    tailPosition,
  }: TailState): E.Either<Errors.WrongDirection, TailState> => {
    return updateTailPosition({
      tailToHeadVec: V.Semigroup.concat(tailToHeadVec, step(direction)),
      tailPosition,
    });
  };

const moveLongTail =
  (direction: Direction) =>
  (
    arrTailState: ReadonlyArray<TailState>
  ): E.Either<Errors.WrongDirection, ReadonlyArray<TailState>> => {
    const [[start], end] = RA.splitAt(1)(arrTailState);
    return pipe(
      end,
      RA.scanLeft(
        updateTailWithDirection(direction)(start),
        (ELastKnot, currKnot) =>
          pipe(
            ELastKnot,
            E.flatMap((lastKnot) =>
              updateTailPosition({
                tailPosition: currKnot.tailPosition,
                tailToHeadVec: V.Semigroup.concat(
                  lastKnot.tailPosition,
                  V.Negative(currKnot.tailPosition)
                ),
              })
            )
          )
      ),
      RA.sequence(E.Applicative)
    );
  };

function updateTailPosition({
  tailToHeadVec,
  tailPosition,
}: TailState): E.Either<Errors.WrongDirection, TailState> {
  return pipe(
    calcNextMove(tailToHeadVec),
    E.map((moveTail) => ({
      tailPosition: V.Semigroup.concat(tailPosition, moveTail),
      tailToHeadVec: V.Semigroup.concat(tailToHeadVec, V.Negative(moveTail)),
    }))
  );
}

const getUniqTailPositions = flow(
  RA.map(({ tailPosition }) => tailPosition),
  RA.uniq(V.Eq),
  RA.size
);
const unfoldDirections = RA.flatMap(([direction, step]) =>
  RA.replicate(step, direction)
);

function tailPosition(inputPath: string, prefix: string) {
  return pipe(
    readInput(inputPath),
    IO.map(E.flatMap(parseInput)),
    IOE.map(unfoldDirections),
    IOE.flatMap(
      flow(
        RA.scanLeft(
          E.of({
            tailToHeadVec: { x: 0, y: 0 },
            tailPosition: { x: 0, y: 0 },
          }),
          (
            lastState: E.Either<Errors.WrongDirection, TailState>,
            currDirection
          ) =>
            pipe(lastState, E.flatMap(updateTailWithDirection(currDirection)))
        ),
        RA.sequence(E.Applicative),
        E.map(getUniqTailPositions),
        IOE.fromEither
      )
    ),
    IOE.fold(
      (err) => Console.error(err),
      (result) =>
        pipe(
          Console.log(`${prefix}: `),
          IO.flatMap(() => Console.log(result))
        )
    )
  );
}

function nineTailPosition(inputPath: string, prefix: string) {
  return pipe(
    readInput(inputPath),
    IO.map(E.flatMap(parseInput)),
    IOE.map(unfoldDirections),
    IOE.flatMap(
      flow(
        RA.scanLeft(
          E.of(
            RA.replicate(9, {
              tailToHeadVec: { x: 0, y: 0 },
              tailPosition: { x: 0, y: 0 },
            })
          ),
          (
            acc: E.Either<Errors.WrongDirection, ReadonlyArray<TailState>>,
            curr
          ) => pipe(acc, E.flatMap(moveLongTail(curr)))
        ),
        RA.sequence(E.Applicative),
        E.flatMap(
          flow(
            RA.map(RA.last),
            RA.sequence(O.Applicative),
            O.map(getUniqTailPositions),
            E.fromOption(() => Errors.EmptyArray)
          )
        ),
        IOE.fromEither
      )
    ),
    IOE.fold(
      (err) => Console.error(err),
      (result) =>
        pipe(
          Console.log(`${prefix}: `),
          IO.flatMap(() => Console.log(result))
        )
    )
  );
}

function main() {
  tailPosition("./input.txt", "Result exercise 9 part 1")();

  nineTailPosition("./input.txt", "Result exercise 9 part 2")();
}

main();
