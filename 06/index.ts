import * as RA from "fp-ts/ReadonlyArray";

import * as Console from "fp-ts/Console";
import * as IOE from "fp-ts/IOEither";
import { flow, pipe } from "fp-ts/lib/function";
import * as O from "fp-ts/Option";
import * as S from "fp-ts/string";
import { readInput } from "../utils/readInput";

type Line = string;

const parseInput = (fileBuffer: Buffer): Line => {
  return pipe(fileBuffer.toString(), S.trim, S.split("\n"))[0];
};

type Windows = ReadonlyArray<ReadonlyArray<string>>;

const createWindows: (markerSize: number) => (line: string) => Windows = (
  markerSize
) =>
  flow(
    S.split(""),
    RA.chop((as) => {
      return [as.slice(0, markerSize), as.slice(1)];
    })
  );

const checkUnique: (
  markerSize: number
) => (arr: ReadonlyArray<string>) => boolean = (markerSize) =>
  flow(RA.uniq(S.Eq), RA.size, (size) => size === markerSize);

function findMarker(markerSize2: number, prefix: string) {
  return pipe(
    readInput("./input.txt"),
    IOE.map(parseInput),
    IOE.map(createWindows(markerSize2)),
    IOE.flatMap(
      flow(
        RA.map(checkUnique(markerSize2)),
        RA.findIndex((x) => x),
        O.map((x) => x + markerSize2),
        IOE.fromOption(() => new Error("No solution found"))
      )
    ),
    IOE.tap((item) => IOE.fromIO(Console.log(item))),
    IOE.fold(
      (err) => Console.error(err.message),
      (result) => Console.log(`${prefix}: ${result}`)
    )
  );
}

function main() {
  const markerSize = 4;
  findMarker(markerSize, "Result exercise 6 part 1")();

  const markerSize2 = 14;
  findMarker(markerSize2, "Result exercise 6 part 2")();
}

main();
