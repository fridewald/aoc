import fetch from "node-fetch";
import * as fs from "fs";

function downloadInput() {
  if (process.argv.length < 3) {
    console.log(`Please provide a day number!`);
  }
  const cookie = fs
    .readFileSync("utils/cookie.txt", { flag: "r" })
    .toString()
    .trim();
  const exercisePath = `./${String("0" + process.argv[2])}`;

  fs.mkdirSync(exercisePath, { recursive: true });
  return fetch(`https://adventofcode.com/2022/day/${process.argv[2]}/input`, {
    headers: {
      accept:
        "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
      "cache-control": "max-age=0",
      "sec-ch-ua-platform": '"Linux"',
      "sec-fetch-dest": "document",
      "sec-fetch-site": "same-origin",
      "upgrade-insecure-requests": "1",
      cookie,
    },
    method: "GET",
  })
    .then((res) => res.text())
    .then((body) => fs.writeFileSync(`${exercisePath}/input.txt`, body.trimEnd()));
}

await downloadInput();
