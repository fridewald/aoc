import * as Console from "fp-ts/Console";
import * as E from "fp-ts/Either";
import { flow, pipe } from "fp-ts/function";
import * as IO from "fp-ts/IO";
import * as IOE from "fp-ts/IOEither";
import * as S from "fp-ts/string";
import * as t from "io-ts";
import { PathReporter } from "io-ts/PathReporter";
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
}

const parseInput = (fileBuffer: Buffer): t.Validation<Instruction> => {
  return pipe(
    fileBuffer.toString(),
    S.trim,
    S.split("\n"),
    RA.map(S.split(" ")),
    InstructionCodec.decode,
    (e) => {
      console.log(PathReporter.report(e));
      return e;
    }
  );
};

const zeroVector = { x: 0, y: 0 };

type Acc = { tailToHeadVec: V.Vector; tailPosition: V.Vector };

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

const move =
  (direction: Direction) =>
  ({
    tailToHeadVec,
    tailPosition,
  }: Acc): E.Either<Errors.WrongDirection, Acc> => {
    return pipe(
      E.Do,
      E.bind("step", () => E.of(step(direction))),
      E.bind("tmpTailToHeadVec", ({ step }) =>
        E.of(V.Semigroup.concat(tailToHeadVec, step))
      ),
      E.bind("moveTail", ({ tmpTailToHeadVec }) =>
        calcNextMove(tmpTailToHeadVec)
      ),
      E.map(({ moveTail, tmpTailToHeadVec }) => ({
        tailPosition: V.Semigroup.concat(tailPosition, moveTail),
        tailToHeadVec: V.Semigroup.concat(
          tmpTailToHeadVec,
          V.Negative(moveTail)
        ),
      }))
    );
  };

function numberOfVisibleTrees(inputPath: string, prefix: string) {
  return pipe(
    readInput(inputPath),
    IO.map(E.flatMap(parseInput)),
    IOE.tap((data) => IOE.fromIO(Console.log(data))),
    IOE.map(RA.flatMap(([direction, step]) => RA.replicate(step, direction))),
    IOE.flatMap(
      flow(
        RA.scanLeft(
          E.of({
            tailToHeadVec: { x: 0, y: 0 },
            tailPosition: { x: 0, y: 0 },
          } satisfies Acc),
          (acc: E.Either<Errors.WrongDirection, Acc>, curr) =>
            E.flatMap(move(curr))(acc)
        ),
        RA.sequence(E.Applicative),
        E.map(
          flow(
            RA.map(({ tailPosition }) => tailPosition),
            RA.uniq(V.Eq),
            RA.size
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

function highestVisibleScore(inputPath: string, prefix: string) {
  return pipe(
    readInput(inputPath),
    IOE.map(parseInput)
    // IOE.map(prepareMatrices),
    // IOE.map(R.map(findDist)),
    // IOE.map(combineMatrices(combineTwoDistMatrices)),
    // IOE.map(flow(RA.map(RA.maximum(N.Ord)), RA.maximum(N.Ord))),
    // IOE.fold(
    //   (err) => Console.error(err.message),
    //   (result) =>
    //     pipe(
    //       Console.log(`${prefix}: `),
    //       IO.flatMap(() => Console.log(result))
    //     )
    // )
  );
}

function main() {
  numberOfVisibleTrees("./input.txt", "Result exercise 9 part 1")();

  // highestVisibleScore("./input.txt", "Result exercise 9 part 2")();
}

main();
