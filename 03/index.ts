import * as A from "fp-ts/Array";
import * as Tu from "fp-ts/Tuple";
import * as IOE from "fp-ts/IOEither";
import * as IO from "fp-ts/IO";
import { pipe } from "fp-ts/lib/function";
import { concatAll } from "fp-ts/lib/Monoid";
import { MonoidSum } from "fp-ts/lib/number";
import * as S from "fp-ts/string";
import * as t from "io-ts";
import { readInput } from "../utils/readInput";

const parseInput = (fileBuffer: Buffer) => {
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

const sum = concatAll(MonoidSum);

function main() {
  const think = pipe(
    readInput("./input.txt"),
    IOE.map(parseInput),
    IOE.map(split),
    IOE.map(findDuplicate),
    IOE.map(
      A.map((item) =>
        item.charCodeAt(0) < 97
          ? item.charCodeAt(0) - 64 + 26
          : item.charCodeAt(0) - 96
      )
    ),
    IOE.chainFirst((item) => IOE.of(console.log(item))),
    IOE.map(sum),
    IOE.getOrElse(() => IO.of(0))
  )();
  console.log(think);
}

main();
