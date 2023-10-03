module Main where

import Data.Text (splitOn)
import Data.Tree (flatten)
import System.Environment

-- import Data.Text

main :: IO ()
main = do
  fileIo <- readFile "input.txt"
  let dataLines = foldMap lineToInstruction (lines fileIo)
  let register = scanl (+) 1 dataLines
  print register
  print (sum (map (\x -> (register !! (x - 1)) * x) [20, 60, 100, 140, 180, 220]))

lineToInstruction :: String -> [Int]
lineToInstruction "noop" = [0]
lineToInstruction ('a' : 'd' : 'd' : 'x' : ' ' : x) = [0, read x]
lineToInstruction _ = []
