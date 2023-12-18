import Data.Foldable (Foldable (fold), toList)
import Data.List (nub, stripPrefix)
import Data.List.Split (splitOn, splitWhen)
import System.Environment ()


notNull :: (Foldable t) => t a -> Bool
notNull x = not $ null x

dropNull :: [[a]] -> [[a]]
dropNull = filter notNull

readNumber :: [String] -> [Int]
readNumber = map read

pot = [0]

main :: IO ()
main = do
  -- fileIo <- readFile "input.txt"
  fileIo <- readFile "test.txt"
  -- Aufgabe 1
  let filesLines = lines fileIo
  let linesLength = length $ head filesLines
  let hm1 = map (splitOn "|" . tail . dropWhile (/= ':')) filesLines
  let hm2 = [(readNumber . dropNull . splitOn " " $ head hmm, readNumber . dropNull . splitOn " " $ hmm !! 1) | hmm <- hm1, length hmm == 2]
  foldMap print $ take 10 hm2
  let hm3 = [[own| own <- ownNumbers, own `elem` winningNumbers ] | (winningNumbers, ownNumbers) <- hm2]
  let res = [2 ^ (length wiScratch - 1) |wiScratch <- hm3, not (null wiScratch)]

  foldMap print $ take 10 res

  putStrLn $ "Aufgabe 1: " ++ show (sum res)

-- Aufgabe 2

  let res = [length wiScratch |wiScratch <- hm3]
  foldMap print $ take 10 res

--   putStrLn $ "Aufgabe 2: " ++ show res
