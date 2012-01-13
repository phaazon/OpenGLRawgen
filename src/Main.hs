-----------------------------------------------------------------------------
--
-- Module      :  Main
-- Copyright   :  (c) 2011-2012 Lars Corbijn
-- License     :  BSD-style (see the file /LICENSE)
--
-- Maintainer  :
-- Stability   :
-- Portability :
--
-- |
--
-----------------------------------------------------------------------------

module Main (
    main
) where


import Language.Haskell.Exts.Pretty
import Code.Generating.Utils

import Code.Generating.Package

import Spec
import Spec.Parsing(parseSpecs, parseReuses)

import Code.Raw
import Code.Module(replaceCallConv)

-----------------------------------------------------------------------------

main :: IO ()
main = procNew

procNew :: IO ()
procNew = do
    let especP  = "enumext.spec"
        fspecP  = "gl.spec"
        tmspecP = "gl.tm"
        rfuncP  = "reusefuncs"
    erawSpec <- parseSpecs especP fspecP tmspecP
    case erawSpec of
        Left e -> print e
        Right rawSpec -> do
            reuses <- readFile rfuncP >>= return . parseReuses
            let reuses' = either (\ e-> error $ "Parsing the reuses faild with" ++ show e) id reuses
                modules = makeRaw $ cleanupSpec . addReuses reuses' $ rawSpec
                -- | Post processes a module and writes it to file
                pmodule mn m =
                    let msc = replaceCallConv "CALLCONV" $ prettyPrint m
                    in  safeWriteFile ("output/" ++ moduleNameToPath mn ++ ".hs") msc
            -- write out the modules
            processModules' pmodule modules
            -- and a list of exposed and internal modules.
                >> safeWriteFile "output/modulesE.txt" (unlines .
                    map (\n -> "      " ++ moduleNameToName n ++ ",") . fst $ listModules modules)
                >> safeWriteFile "output/modulesI.txt" (unlines .
                    map (\n -> "      " ++ moduleNameToName n ++ ",") . snd $ listModules modules)
