import * as RA from "fp-ts/ReadonlyArray";

import * as Console from "fp-ts/Console";
import * as IO from "fp-ts/IO";
import * as IOE from "fp-ts/IOEither";
import { flow, pipe } from "fp-ts/lib/function";
import * as O from "fp-ts/Option";
import * as R from "fp-ts/Reader";
import * as S from "fp-ts/string";
import { readInput } from "../utils/readInput";

type Lines = ReadonlyArray<string>;

const parseInput = (fileBuffer: Buffer): Lines => {
  return pipe(fileBuffer.toString(), S.trim, S.split("\n"));
};

type Stacks = ReadonlyArray<string>;
type Procedure = [number, number, number];

type Procedures = ReadonlyArray<Procedure>;

const processData: R.Reader<
  ReadonlyArray<string>,
  {
    stacks: Stacks;
    procedures: Procedures;
  }
> = pipe(
  R.Do,
  R.bind("stacks", () => R.asks(extractStacksAndProcess)),
  R.bind("procedures", () => R.asks(extractProcedures))
);

const extractProcedures: (x: Lines) => Procedures = flow(
  RA.dropLeft(10),
  RA.map(
    flow(
      S.split(" "),
      RA.map((str) => parseInt(str, 10))
    )
  ),
  RA.map((instr) => [instr[1], instr[3], instr[5]])
);

type ReadonlyMatrix<T> = ReadonlyArray<ReadonlyArray<T>>;

const transpose = (matrix: ReadonlyMatrix<string>): ReadonlyMatrix<string> => {
  return pipe(
    matrix[0],
    RA.mapWithIndex((i, _) => matrix.map((arr) => arr[i]))
  );
};

const getStackLetters = flow(
  S.split(""),
  RA.chunksOf(4),
  RA.map((arr) => arr[1])
);
const extractStacksAndProcess: (ar: Lines) => Stacks = flow(
  RA.takeLeft(8),
  RA.map(getStackLetters),
  transpose,
  RA.map(
    flow(
      RA.filter((str) => str !== " "),
      RA.reduce("", S.Monoid.concat)
    )
  )
);

const performProcedure =
  (moveModifier: (x: string) => string) =>
  (stacks: Stacks, procedure: Procedure): Stacks => {
    return pipe(
      O.Do,
      O.bind("stacks", () => O.some(stacks)),
      O.bind("move", ({ stacks }) =>
        pipe(
          stacks,
          RA.lookup(procedure[1] - 1),
          O.map(S.slice(0, procedure[0])),
          O.map(moveModifier)
        )
      ),
      O.bind("from", ({ stacks }) =>
        pipe(
          stacks,
          RA.lookup(procedure[1] - 1),
          O.map((from) => from.slice(procedure[0]))
        )
      ),
      O.bind("to", ({ stacks, move }) =>
        pipe(
          stacks,
          RA.lookup(procedure[2] - 1),
          O.map((to) => S.Monoid.concat(move, to))
        )
      ),
      O.flatMap(({ stacks, from, to }) =>
        pipe(
          stacks,
          RA.updateAt(procedure[1] - 1, from),
          O.flatMap(RA.updateAt(procedure[2] - 1, to))
        )
      ),
      O.getOrElse(() => stacks)
    );
  };

const reverse = (str: string): string => {
  return str.split("").reverse().join("");
};

const craneTask = (
  moveModifier: (string) => string,
  prefix: string
): IO.IO<void> =>
  pipe(
    readInput("./input.txt"),
    IOE.map(parseInput),
    IOE.map(processData),
    IOE.map(({ stacks, procedures }) =>
      pipe(procedures, RA.reduce(stacks, performProcedure(moveModifier)))
    ),
    IOE.map(
      flow(
        RA.map((stack) => stack[0]),
        RA.reduce("", S.Monoid.concat)
      )
    ),
    IOE.fold(
      (err) => Console.error(err.message),
      (result) => Console.log(`${prefix}: ${result}`)
    )
  );
function main() {
  craneTask(reverse, "Result exercise 4 part 1")();

  craneTask((x) => x, "Result exercise 4 part 2")();
}

main();
