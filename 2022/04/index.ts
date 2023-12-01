import * as RNA from "fp-ts/ReadonlyNonEmptyArray";

import * as IO from "fp-ts/IO";
import * as IOE from "fp-ts/IOEither";
import { flow, pipe } from "fp-ts/lib/function";
import { concatAll } from "fp-ts/lib/Monoid";
import { MonoidSum } from "fp-ts/lib/number";
import { ReadonlyNonEmptyArray } from "fp-ts/lib/ReadonlyNonEmptyArray";
import * as S from "fp-ts/string";
import { readInput } from "../../utils/readInput";

const parseInput = (fileBuffer: Buffer): ReadonlyNonEmptyArray<string> => {
  return pipe(fileBuffer.toString(), S.split("\n"));
};

const sum = concatAll(MonoidSum);

const testRangeOverlap = (
  inList: ReadonlyNonEmptyArray<ReadonlyNonEmptyArray<number>>
): number => {
  return (inList[0][0] <= inList[1][0] && inList[0][1] >= inList[1][1]) ||
    (inList[0][0] >= inList[1][0] && inList[0][1] <= inList[1][1])
    ? 1
    : 0;
};

const testRangeOverlap2 = (
  inList: ReadonlyNonEmptyArray<ReadonlyNonEmptyArray<number>>
): number => {
  return ! ((inList[0][0] < inList[1][0] && inList[0][1] < inList[1][0]) ||
    (inList[0][0] > inList[1][1] && inList[0][1] > inList[1][1]))
    ? 1
    : 0;
};

const splitting = RNA.map(
  flow(
    S.split(","),
    RNA.map(
      flow(
        S.split("-"),
        RNA.map((s) => parseInt(s, 10))
      )
    )
  )
);
function main() {
  const part1 = pipe(
    readInput("./input.txt"),
    IOE.map(parseInput),
    IOE.map(splitting),
    // IOE.chainFirst((item) => IOE.of(console.log(item))),
    IOE.map(RNA.map(testRangeOverlap)),
    // IOE.chainFirst((item) => IOE.of(console.log(item))),
    IOE.map(sum),
    IOE.getOrElse(() => IO.of(0))
  );
  console.log(`Result exercise 4 part 1: ${part1()}`);

  const part2 = pipe(
    readInput("./input.txt"),
    IOE.map(parseInput),
    IOE.map(splitting),
    // IOE.chainFirst((item) => IOE.of(console.log(item))),
    IOE.map(RNA.map(testRangeOverlap2)),
    // IOE.chainFirst((item) => IOE.of(console.log(item))),
    IOE.map(sum),
    IOE.getOrElse(() => IO.of(0))
  );
  console.log(`Result exercise 4 part 2: ${part2()}`);
}

main();
