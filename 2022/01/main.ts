import * as IOEither from "fp-ts/IOEither";
import { pipe } from "fp-ts/lib/function";
import { ReadonlyNonEmptyArray } from "fp-ts/lib/ReadonlyNonEmptyArray";
import * as N from "fp-ts/number";
import * as RA from "fp-ts/ReadonlyArray";
import * as S from "fp-ts/string";
import { readInput } from "../../utils/readInput";

const parseInput = (fileBuffer: Buffer) => {
  return pipe(fileBuffer.toString(), S.split("\n"));
};
const group: (
  as: ReadonlyNonEmptyArray<string>
) => ReadonlyArray<ReadonlyArray<string>> = RA.chop((as) => {
  const { init, rest } = pipe(
    as,
    RA.spanLeft((a: string) => a !== ""),
    ({ init, rest }) => {
      return { init, rest: RA.dropLeft(1)(rest) };
    }
  );
  return [init, rest];
});

const calcSum = (arr: ReadonlyNonEmptyArray<string>) => {
  return pipe(
    arr,
    RA.map(parseInt),
    RA.reduce(0, (b, a) => a + b)
  );
};

const addUpCalories = (listCal: ReadonlyNonEmptyArray<string>) => {
  return pipe(listCal, group, RA.map(calcSum));
};

const orderAccordingToCalories = (
  listCalSum: ReadonlyNonEmptyArray<number>
) => {
  return pipe(listCalSum, RA.sort(N.Ord), RA.reverse);
};

function main() {
  const think = pipe(
    readInput("./input.txt"),
    IOEither.map(parseInput),
    IOEither.map(addUpCalories),
    IOEither.map(orderAccordingToCalories)
  )();
  console.log(think);
}

main();
