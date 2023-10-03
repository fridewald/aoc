module Main where

import Data.Foldable (toList)
import Data.List
import Data.List.Split (chunksOf)
import Data.Sequence (fromList, mapWithIndex)
import System.Environment

-- import Data.Text

main :: IO ()
main = do
  fileIo <- readFile "input.txt"
  let dataLines = foldMap lineToInstruction (lines fileIo)
  let register = scanl (+) 1 dataLines
  print (sum (map (\x -> (register !! (x - 1)) * x) [20, 60, 100, 140, 180, 220]))
  putStrLn (handleRegister register)

lineToInstruction :: String -> [Int]
lineToInstruction "noop" = [0]
lineToInstruction ('a' : 'd' : 'd' : 'x' : ' ' : x) = [0, read x]
lineToInstruction _ = []

handleRegister :: [Int] -> String
handleRegister register =
  let chars = toList (mapWithIndex getCRT (fromList register))
   in intercalate "\n" (chunksOf 40 chars)

getCRT index v = if mod index 40 >= v - 1 && mod index 40 <= v + 1 then '#' else '.'
