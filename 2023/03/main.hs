import Data.Array.Base (mapIndices)
import Data.Char (isSpace)
import Data.Foldable (Foldable (fold), toList)
import Data.List (nub, stripPrefix)
import Data.List.Split ( chunksOf, divvy, splitWhen )
import Data.Maybe (fromJust)
import Data.Sequence (fromList, mapWithIndex)
import GHC.Real (reduce)
import System.Environment ()

trim :: String -> String
trim = f . f
  where
    f = reverse . dropWhile isSpace

charNumberAndDot = '.' : ['0' .. '9']

lineToInstruction [line0, line1, line2] = map (\(above, main, below) -> (main !! 1, filter (`notElem` charNumberAndDot) $ above ++ [main !! 0, main !! 2] ++ below)) grouped
  where
    grouped = grouping [line0, line1, line2]
lineToInstruction [_] = []

lineToInstruction2 :: [[(Char, Int)]] -> [(Char, [(Char, Int)])]
lineToInstruction2 [line0, line1, line2] = map (\(above, main, below) -> (fst (main !! 1), filter (\(key, _) -> key `notElem` charNumberAndDot) $ above ++ [main !! 0, main !! 2] ++ below)) grouped
  where
    grouped = grouping [line0, line1, line2]
lineToInstruction2 [_] = []

grouping [line0, line1, line2] = grouped
  where
    line0in3 = divvy 3 1 line0
    line1in3 = divvy 3 1 line1
    line2in3 = divvy 3 1 line2
    grouped = zip3 line0in3 line1in3 line2in3

notNull x = not $ null x

getNumberTuples :: [[(Char, b)]] -> [[(Char, b)]]
getNumberTuples = concatMap (filter notNull . splitWhen (\(ele, _) -> ele `notElem` ['0' .. '9']))

main :: IO ()
main = do
  -- fileIo <- readFile "input.txt"
  fileIo <- readFile "test.txt"
  -- Aufgabe 1
  let filesLines = map (\line -> '.' : line ++ ".") (lines fileIo)
  let linesLength = length $ head filesLines
  let emptyLines = ['.' | _ <- [1 .. linesLength]]
  let withEmptyBeforeAndAfter = emptyLines : filesLines ++ [emptyLines]
  let elementWithCharactersAround = lineToInstruction <$> divvy 3 1 withEmptyBeforeAndAfter

  let numberTuples = getNumberTuples elementWithCharactersAround
  let combined = map (foldl (\(digit, foundKey) (nextDigit, key) -> (digit * 10 + read [nextDigit], foundKey || notNull key)) (0, False)) numberTuples
  let res = sum [num | (num, foundKey) <- combined, foundKey]

  foldMap print elementWithCharactersAround
  foldMap print combined
  putStrLn $ "Aufgabe 1: " ++ show res

  -- Aufgabe 2
  -- if ele `elem` ['*'] then (ele, count+1) else
  let replaceSome = scanl (\(_, count) ele -> if ele `elem` ['0' .. '9'] then (ele, count) else if ele == '*' then ('*', count + 1) else ('.', count)) ('.', 0) $ concat withEmptyBeforeAndAfter
  let filesLines2 = chunksOf linesLength $ tail replaceSome
  let elementWithCharactersAround2 = lineToInstruction2 <$> divvy 3 1 filesLines2
  -- foldMap print elementWithCharactersAround2
  let numberTuples = getNumberTuples elementWithCharactersAround2
  let combined = map (foldl (\(digit, foundKey) (nextDigit, key) -> (digit * 10 + read [nextDigit], foundKey ++ key)) (0, [])) numberTuples
  foldMap print numberTuples
  let hm = map (\(number, keys) -> (number, nub (map snd keys))) combined
  let hm2 = [(num, keys) | (num, keys) <- hm, not (null keys)]

  foldMap print hm2

  -- let combined = map (foldl (\(digit, foundKey) (nextDigit, key) -> (digit * 10 + (read [nextDigit]), foundKey || notNull key)) (0, False)) numberTuples

  -- foldMap putStrLn res
  putStrLn $ "Aufgabe 2: " ++ show res
