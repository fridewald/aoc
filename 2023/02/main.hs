module Main where

import Data.Char (isSpace)
import Data.List (stripPrefix)
import Data.List.Split (splitOn)
import Data.Maybe (fromJust)
import System.Environment ()

trim :: String -> String
trim = f . f
 where
  f = reverse . dropWhile isSpace

lineToInstruction :: [Char] -> (Int, (Int, Int, Int))
lineToInstruction line = (fromJust gameNumber, fromJust rounds)
 where
  suffix = stripPrefix "Game " line
  gameNumber = read . head . splitOn ":" <$> suffix
  rounds = getRounds <$> stripPrefix "Game " line

getRounds :: [Char] -> (Int, Int, Int)
getRounds group =
  let group1 = (splitOn ";" . dropWhile (/= ' ')) group
      group2 = map (splitOn " " . trim) . splitOn "," <$> group1
      group3 = [(read (head xs) :: Int, xs !! 1) | xss <- group2, xs <- xss]
      maxBall = foldl getColor (0, 0, 0) group3
   in maxBall

getColor :: (Int, Int, Int) -> (Int, String) -> (Int, Int, Int)
getColor (red, green, blue) (balls, color)
  | color == "red" = (max red balls, green, blue)
  | color == "green" = (red, max green balls, blue)
  | color == "blue" = (red, green, max blue balls)
  | otherwise = (red, green, blue)

-- >>> 1+ 1

main :: IO ()
main = do
  -- fileIo <- readFile "test.txt"
  fileIo <- readFile "input.txt"
  let maxBalls = lineToInstruction <$> lines fileIo

  let invalidRounds = sum [game | (game, (red, green, blue)) <- maxBalls, red <= 12, green <= 13, blue <= 14]
  let sumOfMinSetPower = sum [red * green * blue | (_, (red, green, blue)) <- maxBalls]

  -- foldMap print dataLines
  -- foldMap putStrLn (lines fileIo)
  print invalidRounds
  print sumOfMinSetPower
