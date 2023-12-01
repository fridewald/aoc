import * as A from "fp-ts/Array";
import * as IOE from "fp-ts/IOEither";
import { pipe } from "fp-ts/lib/function";
import { concatAll } from "fp-ts/lib/Monoid";
import { MonoidSum } from "fp-ts/lib/number";
import * as S from "fp-ts/string";
import * as t from "io-ts";
import { readInput } from "../../utils/readInput";

const scoreMap = {
  "A X": 4,
  "A Y": 8,
  "A Z": 3,
  "B X": 1,
  "B Y": 5,
  "B Z": 9,
  "C X": 7,
  "C Y": 2,
  "C Z": 6,
} as const;

const scoreMapb = {
  "A X": 3,
  "A Y": 4,
  "A Z": 8,
  "B X": 1,
  "B Y": 5,
  "B Z": 9,
  "C X": 2,
  "C Y": 6,
  "C Z": 7,
} as const;

const ScorePlanSchema = t.array(t.keyof(scoreMap));
export type ScorePlan = t.TypeOf<typeof ScorePlanSchema>;

const parseInput = (fileBuffer: Buffer) => {
  return pipe(fileBuffer.toString(), S.split("\n"));
};

const sum = concatAll(MonoidSum);

const getScoreValues =
  (sMap: Record<ScorePlan[number], number>) => (scoreKeys: ScorePlan) => {
    return pipe(
      scoreKeys,
      A.map((value) => sMap[value])
    );
  };

function main() {
  const think = pipe(
    readInput("./input.txt"),
    IOE.map(parseInput),
    IOE.chainW(IOE.fromEitherK(ScorePlanSchema.decode)),
    IOE.map(getScoreValues(scoreMap)),
    IOE.map(sum)
  )();
  console.log(think);

  const thinkAgain = pipe(
    readInput("./input.txt"),
    IOE.map(parseInput),
    IOE.chainW(IOE.fromEitherK(ScorePlanSchema.decode)),
    IOE.map(getScoreValues(scoreMapb)),
    IOE.map(sum)
  )();
  console.log(thinkAgain);
}

main();
