--------------------------------------------------------------------------------
-- |
-- Module      : UnivOpWrap
-- Note        :
--
--
--
--------------------------------------------------------------------------------
{-# LANGUAGE CPP #-}
module System.UnivOpWrap
  ( univOpWrap
  , module X
  ) where

import System.Directory
import System.Process
import System.FilePath
import System.IO
import Control.Monad (when,unless,liftM)
import Data.Foldable (forM_)
import Data.Maybe
import System.Exit ( exitSuccess )

import System.UnivOpWrap.Common as X
import System.UnivOpWrap.Backend
import System.UnivOpWrap.Logic
import System.UnivOpWrap.Tui
import System.UnivOpWrap.Repl

univOpWrap :: Parameter -> IO()
univOpWrap p@P{sanitize=True} = getInfo (fromJust (cmP p)) >>= sanitizeInfo
univOpWrap p                  = do
    i <- getInfo (fromJust (cmP p))
    case p of
      P{list = True} -> mapM_ print $ md i
      _              -> do
        (i',ph) <- if repl p
          then replRoutine (ask p) (unwords (argsP p)) i
          else defaultRoutine (ask p) (unwords (argsP p)) i
        _ <- when (dbg p) (print i')
        saveInfo i'
        unless (fork p) $ forM_ ph waitForProcess

defaultRoutine :: Bool -> String -> Info -> IO (Info, Maybe ProcessHandle)
defaultRoutine b arg i = do
    ex <- doesFileExist arg
    mtch <- if ex
      then do
        cp <- cleanPath arg
        newMData cp 100
      else return $ findBestMatchI arg i
    case mtch of
      Non _ -> return (i, Nothing)
      _     -> do
                ph <- runCmd b (cm i) mtch
                return (updateInfo mtch i, ph)

replRoutine :: Bool -> String -> Info -> IO(Info, Maybe ProcessHandle)
replRoutine b arg i = do
  ex <- doesFileExist arg
  mtch <- if ex
          then do
            cleanedPath <- cleanPath arg
            newMData cleanedPath 100
          else runRepl arg i
  case mtch of
    Non _ -> return (i, Nothing)
    _     -> do
              ph <- runCmd b (cm i) mtch
              return (updateInfo mtch i, ph)

runCmd :: Bool -> Command -> MData -> IO(Maybe ProcessHandle)
runCmd b (C cts) m = let
    getCmdPerFT :: [(String,FilePath)] -> String -> String
    getCmdPerFT [] _                             = "exit 2;"
    getCmdPerFT (("",c):_) _                     = c
    getCmdPerFT ((ext,c):css) ext' | ext == ext' = c
                                   | otherwise   = getCmdPerFT css ext'
  in do
    let l = getCmdPerFT cts (takeExtension (fn m)) ++ " \"" ++ fn m ++ "\""
    putStrLn l
    ans <- if b
      then putStr " [Y/n]: " >> hFlush stdout >> getLine
      else return "y"
    case ans of
      "n" -> return Nothing
      _   -> liftM Just (runCommand l)
