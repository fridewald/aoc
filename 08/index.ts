import * as Console from "fp-ts/Console";
import * as IO from "fp-ts/IO";
import * as IOE from "fp-ts/IOEither";
import { flow, pipe } from "fp-ts/lib/function";
import * as N from "fp-ts/lib/number";
import * as O from "fp-ts/lib/Option";
import * as R from "fp-ts/lib/Record";
import * as S from "fp-ts/lib/string";
import * as RA from "../types/ReadonlyArray";
import { readInput } from "../utils/readInput";

type GenericForestMatrix<T> = ReadonlyArray<ReadonlyArray<T>>;
type ForestMatrix = GenericForestMatrix<number>;
type VisibleMatrix = GenericForestMatrix<boolean>;

const parseInput = (fileBuffer: Buffer): ForestMatrix => {
  return pipe(
    fileBuffer.toString(),
    S.trim,
    S.split("\n"),
    RA.map(flow(S.split(""), RA.map(parseInt)))
  );
};

const prepareMatrices = (
  forest: ForestMatrix
): Record<"input" | "rInput" | "inputT" | "rInputT", ForestMatrix> => {
  return {
    input: forest,
    rInput: RA.map(RA.reverse)(forest),
    inputT: RA.transpose(forest),
    rInputT: RA.map(RA.reverse)(RA.transpose(forest)),
  };
};

const findVisibleTrees = (forest: ForestMatrix): VisibleMatrix => {
  return pipe(
    forest,
    RA.map(
      flow(
        RA.scanLeft({ highestTree: -1, visible: true }, (b, a: number) => ({
          highestTree: Math.max(a, b.highestTree),
          visible: b.highestTree < a,
        })),
        RA.map((x) => x.visible),
        RA.dropLeft(1)
      )
    )
  );
};

type DistToHighTrees = { dist: number; edge: number } & {
  [key: string]: number;
};

const findDist = (forest: ForestMatrix) => {
  return pipe(
    forest,
    RA.map(
      flow(
        RA.scanLeft(
          { edge: 0, dist: 0 } satisfies DistToHighTrees,
          (distToHighTrees: DistToHighTrees, currentHeight: number) => {
            const dist = pipe(
              distToHighTrees,
              R.keys,
              RA.filter((key) => key !== "dist" && key !== "edge"),
              RA.sort(S.Ord),
              RA.findFirst((key) => parseInt(key) >= currentHeight),
              O.flatMap((key) => R.lookup(key)(distToHighTrees)),
              O.getOrElse(() => distToHighTrees.edge)
            );

            return {
              ...updateDistToHighTrees(currentHeight, distToHighTrees),
              [currentHeight]: 1,
              dist,
            };
          }
        ),
        RA.map((x) => x.dist),
        RA.dropLeft(1)
      )
    )
  );
};

const combineMatrices =
  <T>(
    combine: (
      forest: GenericForestMatrix<T>
    ) => (other: GenericForestMatrix<T>) => GenericForestMatrix<T>
  ) =>
  (
    visibleMatrix: Record<
      "input" | "rInput" | "inputT" | "rInputT",
      GenericForestMatrix<T>
    >
  ): GenericForestMatrix<T> => {
    return pipe(
      combine(visibleMatrix["input"])(
        RA.map(RA.reverse)(visibleMatrix["rInput"])
      ),
      combine(RA.transpose(visibleMatrix["inputT"])),
      combine(RA.transpose(RA.map(RA.reverse)(visibleMatrix["rInputT"])))
    );
  };

const combineTwoVisibleMatrices =
  (forest: VisibleMatrix) =>
  (other: VisibleMatrix): VisibleMatrix => {
    return RA.zipWith(forest, other, (a, b) =>
      RA.zipWith(a, b, (x, y) => x || y)
    );
  };

const combineTwoDistMatrices =
  (forest: ForestMatrix) => (other: ForestMatrix) => {
    return RA.zipWith(forest, other, (a, b) =>
      RA.zipWith(a, b, N.MonoidProduct.concat)
    );
  };

function updateDistToHighTrees(
  currentHeight: number,
  distToHighTrees: DistToHighTrees
): { edge: number } & Record<string, number> {
  return pipe(
    distToHighTrees,
    R.filterMapWithIndex((key: "edge" | "dist" | string, value: number) =>
      key !== "dist" && (key === "edge" || parseInt(key) > currentHeight)
        ? O.some(value + 1)
        : O.none
    )
    // Sorry, too lazy for type safety here
  ) as { edge: number } & Record<string, number>;
}

function numberOfVisibleTrees(inputPath: string, prefix: string) {
  return pipe(
    readInput(inputPath),
    IOE.map(parseInput),
    IOE.map(prepareMatrices),
    // IOE.tap((matrices) => IOE.fromIO(Console.log(matrices))),
    IOE.map(R.map(findVisibleTrees)),
    // IOE.tap((matrices) => IOE.fromIO(Console.log(matrices))),
    IOE.map(combineMatrices(combineTwoVisibleMatrices)),
    // IOE.tap((matrices) => IOE.fromIO(Console.log(matrices))),
    IOE.map(
      RA.reduce(
        0,
        (acc, curr) =>
          acc +
          pipe(
            curr,
            RA.filter((x) => x),
            RA.size
          )
      )
    ),
    IOE.fold(
      (err) => Console.error(err.message),
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
    IOE.map(parseInput),
    IOE.map(prepareMatrices),
    IOE.map(R.map(findDist)),
    IOE.map(combineMatrices(combineTwoDistMatrices)),
    IOE.map(flow(RA.map(RA.maximum(N.Ord)), RA.maximum(N.Ord))),
    IOE.fold(
      (err) => Console.error(err.message),
      (result) =>
        pipe(
          Console.log(`${prefix}: `),
          IO.flatMap(() => Console.log(result))
        )
    )
  );
}

function main() {
  numberOfVisibleTrees("./input.txt", "Result exercise 8 part 1")();

  highestVisibleScore("./input.txt", "Result exercise 8 part 2")();
}

main();
