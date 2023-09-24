import * as RA from "fp-ts/ReadonlyArray";
import * as Console from "fp-ts/Console";
import * as IOE from "fp-ts/IOEither";
import { flow, pipe } from "fp-ts/lib/function";
import * as N from "fp-ts/lib/number";
import * as O from "fp-ts/lib/Option";
import { reverse } from "fp-ts/lib/Ord";
import * as R from "fp-ts/lib/Record";
import * as S from "fp-ts/lib/string";
import { readInput } from "../utils/readInput";

type Line = string;
type Lines = ReadonlyArray<Line>;

const parseInput = (fileBuffer: Buffer): Lines => {
  return pipe(fileBuffer.toString(), S.trim, S.split("\n"));
};

type TreeElement = {
  pwd: string;
  folders: ReadonlyArray<string>;
  directSize: number;
};

type ReduceType = ReadonlyArray<TreeElement>;

const groupCommandAndOutput: (
  as: readonly string[]
) => readonly (readonly string[])[] = RA.chop((as) => {
  const { init, rest } = pipe(
    as,
    RA.dropLeft(1),
    RA.spanLeft((a: string) => !a.startsWith("$"))
  );
  return [pipe(init, RA.prepend(as[0])), rest];
});

const extractCdOrLs: (
  acc: ReduceType,
  curr: ReadonlyArray<string>
) => ReduceType = (acc, curr) =>
  pipe(curr, RA.splitAt(1), ([[head], tail]) =>
    pipe(
      acc,
      RA.last,
      O.map((lastTreeElement) =>
        pipe(acc, RA.append(createNewTreeElement(head, tail, lastTreeElement)))
      ),
      O.getOrElse(
        () => [{ pwd: head.slice(5), folders: [], directSize: 0 }] as const
      )
    )
  );

const createTree: (
  a: Lines
) => Record<string, { directSize: number; folders: ReadonlyArray<string> }> =
  flow(
    groupCommandAndOutput,
    RA.reduce([], extractCdOrLs),
    RA.filter((x) => x.directSize !== 0 || x.folders.length !== 0),
    RA.map(
      (x) => [x.pwd, { directSize: x.directSize, folders: x.folders }] as const
    ),
    R.fromEntries
  );

function createNewTreeElement(
  head: string,
  tail: ReadonlyArray<string>,
  lastTreeElement: TreeElement
): TreeElement {
  if (head.includes("cd")) {
    if (head.slice(5) === "..") {
      return {
        pwd: moveFolderUp(lastTreeElement),
        folders: [],
        directSize: 0,
      };
    }
    return {
      pwd: moveFolderDown(lastTreeElement, head.slice(5)),
      folders: [],
      directSize: 0,
    };
  } else {
    return pipe(tail, RA.partition(S.startsWith("dir")), (sep) => ({
      pwd: lastTreeElement.pwd,
      folders: addFolders(sep.right),
      directSize: calculateDirectSize(sep.left),
    }));
  }
}

function calculateDirectSize(sep): number {
  return pipe(
    sep,
    RA.map(
      flow(
        S.split(" "),
        RA.head,
        O.map(Number),
        O.getOrElseW(() => 0)
      )
    ),
    RA.reduce(0, (acc, curr) => acc + curr)
  );
}

function addFolders(sep): readonly string[] {
  return pipe(
    sep,
    RA.map(
      flow(
        S.split(" "),
        RA.lookup(1),
        O.getOrElseW(() => "")
      )
    )
  );
}

function moveFolderDown(lastTreeElement: TreeElement, head: string): string {
  return lastTreeElement.pwd.endsWith("/")
    ? lastTreeElement.pwd + head
    : lastTreeElement.pwd + "/" + head;
}

function moveFolderUp(lastTreeElement: TreeElement): string {
  return pipe(
    lastTreeElement.pwd,
    S.split("/"),
    RA.dropRight(1),
    RA.reduce("/", (arr, curr) =>
      arr.endsWith("/") ? arr + curr : arr + "/" + curr
    )
  );
}

type TotalSizeTreeElement = Omit<TreeElement, "pwd"> & { totalSize?: number };
type TotalSizeRecord = Record<string, TotalSizeTreeElement>;

const findTotalSize = (key: string, acc: TotalSizeRecord): O.Option<number> => {
  return pipe(
    acc,
    R.lookup(key),
    O.flatMap((x) => O.fromNullable(x.totalSize))
  );
};
const totalSizeExists: (key: string, acc: TotalSizeRecord) => boolean = flow(
  findTotalSize,
  O.fold(
    () => false,
    () => true
  )
);

const reduceTree: (
  key: string,
  acc: O.Option<TotalSizeRecord>,
  curr: TotalSizeTreeElement
) => O.Option<TotalSizeRecord> = (key, acc, curr) => {
  const early = pipe(acc, O.flatMap(earlyCheckForTotalSize(key, curr)));
  if (O.isSome(early)) {
    return early;
  }

  return pipe(
    acc,
    O.chain((treeSofar) =>
      pipe(
        curr.folders,
        RA.map((folder) =>
          findTotalSize(key + (key === "/" ? "" : "/") + folder, treeSofar)
        ),
        RA.sequence(O.Applicative),
        O.map(flow(RA.reduce(0, N.MonoidSum.concat))),
        O.map((totalSize) =>
          pipe(
            treeSofar,
            R.upsertAt(key, { ...curr, totalSize: totalSize + curr.directSize })
          )
        )
      )
    )
  );
};

const earlyCheckForTotalSize: (
  key: string,
  curr: TotalSizeTreeElement
) => (acc: TotalSizeRecord) => O.Option<TotalSizeRecord> =
  (key, curr) => (acc) => {
    if (totalSizeExists(key, acc)) {
      return O.of(acc);
    }
    if (pipe(curr.folders, RA.size) === 0) {
      return pipe(
        acc,
        R.upsertAt(key, { ...curr, totalSize: curr.directSize }),
        O.of
      );
    }
    return O.none;
  };

function findFoldersSmallerThan(folderSize: number, prefix: string) {
  return pipe(
    readInput("./input.txt"),
    IOE.map(parseInput),
    IOE.map(createTree),
    IOE.flatMap(
      flow(
        R.reduceWithIndex(reverse(S.Ord))(O.of({}), reduceTree),
        IOE.fromOption(
          () => new Error("could not find total size for some node")
        )
      )
    ),
    IOE.map(R.filter((x) => x.totalSize < folderSize)),
    IOE.map(R.reduce(S.Ord)(0, (acc, curr) => acc + curr.totalSize)),
    IOE.fold(
      (err) => Console.error(err.message),
      (result) => Console.log(`${prefix}: ${result}`)
    )
  );
}

function findSmallestFolderBiggerThan(
  diskSpace: number,
  updateDiskSpace: number,
  prefix: string
) {
  return pipe(
    readInput("./input.txt"),
    IOE.map(parseInput),
    IOE.map(createTree),
    IOE.flatMap(
      flow(
        R.reduceWithIndex(reverse(S.Ord))(O.of({}), reduceTree),
        IOE.fromOption(
          () => new Error("could not find total size for some node")
        )
      )
    ),
    IOE.bindTo("tree"),
    IOE.bind("spaceNeeded", ({ tree }) =>
      IOE.of(updateDiskSpace - diskSpace + tree["/"].totalSize)
    ),
    IOE.bind("smallestFolder", ({ tree, spaceNeeded }) =>
      pipe(
        tree,
        R.filter((x) => x.totalSize >= spaceNeeded),
        R.collect(S.Ord)((_k, v) => v.totalSize),
        RA.sort(N.Ord),
        RA.head,
        IOE.fromOption(() => new Error("No solution found"))
      )
    ),
    IOE.map(({ smallestFolder }) => smallestFolder),
    IOE.fold(
      (err) => Console.error(err.message),
      (result) => Console.log(`${prefix}: ${result}`)
    )
  );
}

function main() {
  findFoldersSmallerThan(100_000, "Result exercise 7 part 1")();

  const diskSpace = 70_000_000;
  const updateDiskSpace = 30_000_000;
  findSmallestFolderBiggerThan(
    diskSpace,
    updateDiskSpace,
    "Result exercise 7 part 2"
  )();
}

main();
