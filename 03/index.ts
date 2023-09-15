import * as A from "fp-ts/Array";
import * as RNA from "fp-ts/ReadonlyNonEmptyArray";

import * as IO from "fp-ts/IO";
import * as IOE from "fp-ts/IOEither";
import { pipe } from "fp-ts/lib/function";
import { concatAll } from "fp-ts/lib/Monoid";
import { MonoidSum } from "fp-ts/lib/number";
import { ReadonlyNonEmptyArray } from "fp-ts/lib/ReadonlyNonEmptyArray";
import * as S from "fp-ts/string";
import { readInput } from "../utils/readInput";

const parseInput = (fileBuffer: Buffer): ReadonlyNonEmptyArray<string> => {
  return pipe(fileBuffer.toString(), S.trim, S.split("\n"));
};

const split = (
  inList: ReadonlyArray<string>
): Array<readonly [string, string]> => {
  return pipe(
    inList,
    A.map((item) => {
      const size = S.size(item);
      return [item.slice(0, size / 2), item.slice(size / 2, size)] as const;
    })
  );
};

const findDuplicate = (inList: Array<[string, string]>): Array<string> => {
  return pipe(
    inList,
    A.map((item) => {
      return {
        first: Array.from(item[0]),
        second: Array.from(item[1]),
      };
    }),
    A.map(({ first, second }) =>
      first.find((it) => second.some((es) => it === es))
    )
  );
};

const findTripleDuplicate = (
  inList: ReadonlyNonEmptyArray<[string, string, string]>
): ReadonlyNonEmptyArray<string> => {
  return pipe(
    inList,
    RNA.map((item) => {
      return {
        first: Array.from(item[0]),
        second: Array.from(item[1]),
        third: Array.from(item[2]),
      };
    }),
    RNA.map(({ first, second, third }): string =>
      first.find(
        (fir) =>
          second.some((sec) => fir === sec) && third.some((thi) => fir === thi)
      )
    )
  );
};

const sum = concatAll(MonoidSum);

const assignPriority = (item: string) =>
  item.charCodeAt(0) < 97
    ? item.charCodeAt(0) - 64 + 26
    : item.charCodeAt(0) - 96;
function main() {
  const part1 = pipe(
    readInput("./input.txt"),
    IOE.map(parseInput),
    IOE.map(split),
    IOE.map(findDuplicate),
    IOE.map(A.map(assignPriority)),
    // IOE.chainFirst((item) => IOE.of(console.log(item))),
    IOE.map(sum),
    IOE.getOrElse(() => IO.of(0))
  );
  console.log(`Result exercise 3 part 1 ${part1()}`);

  const part2 = pipe(
    readInput("./input.txt"),
    IOE.map(parseInput),
    IOE.map(RNA.chunksOf(3)),
    // IOE.chainFirst((item) => IOE.of(console.log(item))),
    IOE.map(findTripleDuplicate),
    // IOE.chainFirst((item) => IOE.of(console.log(item))),
    IOE.map(RNA.map(assignPriority)),
    IOE.map(sum),
    IOE.getOrElse(() => IO.of(0))
  );

  console.log(`Result exercise 3 part 2 ${part2()}`);
}

main();
