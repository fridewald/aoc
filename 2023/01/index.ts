import {flow, pipe} from "fp-ts/lib/function";
import {readInput} from "../../utils/readInput";
import * as S from "fp-ts/string";
import * as IOE from "fp-ts/IOEither";
import * as RA from "fp-ts/ReadonlyArray";
import * as O from "fp-ts/Option";
import * as E from "fp-ts/Either";

const parseInput = (fileBuffer: Buffer) => {
    return pipe(fileBuffer.toString(), S.split("\n"));
};

const getTwoDigit = (line: string) => {
    const lineArr = pipe(line, S.split(""), RA.map(parseInt));
    return pipe(
        O.Do,
        O.bind("firstDigit", () =>
            pipe(
                lineArr,
                RA.findFirst((item) => !Number.isNaN(item))
            )
        ),
        O.bind("lastDigit", () =>
            pipe(
                lineArr,
                RA.findLast((item) => !Number.isNaN(item))
            )
        ),
        O.map(({firstDigit, lastDigit}) => parseInt(`${firstDigit}${lastDigit}`)),
        O.getOrElse(() => 0)
    );
};

const spelledNumbers = {
    zero: 0,
    one: 1,
    two: 2,
    three: 3,
    four: 4,
    five: 5,
    six: 6,
    seven: 7,
    eight: 8,
    nine: 9,
};

const replaceByNumber = (line: string) => {
    return pipe(
        O.Do,
        O.bind("firstMatch", () =>
            pipe(
                line.match(/(zero|one|two|three|four|five|six|seven|eight|nine|\d)/)[0],
                O.fromNullable
            )
        ),
        O.bind("lastMatch", () =>
            pipe(
                line
                    .split("")
                    .reverse()
                    .join("")
                    .match(/enin|thgie|neves|xis|evif|ruof|eerht|owt|eno|orez|\d/)[0]
                    .split("")
                    .reverse()
                    .join(""),
                O.fromNullable
            )
        ),
        O.map(({firstMatch, lastMatch}) => `${firstMatch}${lastMatch}`),
        O.map((str) =>
            str.replaceAll(
                /(zero|one|two|three|four|five|six|seven|eight|nine)/g,
                (match, p1) => spelledNumbers[p1]
            )
        ),
        O.map(parseInt),
        O.getOrElse(() => 0)
    );
};

function main() {
    const numberNumbers = pipe(
        readInput("./input.txt"),
        IOE.map(
            flow(
                parseInput,
                RA.map(getTwoDigit),
                RA.reduce(0, (a, b) => a + b)
            )
        )
    );
    console.log(E.getOrElseW(() => "noooo")(numberNumbers()));
    const numberStrings = pipe(
        readInput("./input.txt"),
        IOE.map(
            flow(
                parseInput,
                RA.map(replaceByNumber),
                RA.reduce(0, (a, b) => a + b)
            )
        )
    );
    console.log(E.getOrElseW(() => "noooo")(numberStrings()));
}

main();
