{-
 -   Módulo: PokeParse.hs
 -
 -   Integrantes: Grupo 16
 -   Alberto Cols      09-10177
 -   Matteo Ferrando   09-10285
 -
 -   Se encuentran las funciones encargadas del parseo de la información
 -   pasada por archivo. Crea las listas de todos las Especies, todos los 
 -   movimientos y a los dos Trainer con sus respectivos Pokemons.  
 -}

module PokeParse
  ( linesParse
  , speciesParse
  , movesParse
  , trainerParse
  ) where

import Data.List (find)
import Data.Maybe (isJust, fromJust)
import qualified Data.IntMap as IMap (IntMap, fromList, lookup)
import qualified Data.Map as Map (Map, fromList, lookup)

import Data.List.Split (splitOn)

import Pokemon

-- Para separar el String leido del archivo en lineas, sin incluir lineas en blanco
linesParse :: String -> [[String]]
linesParse s = map (splitOn (",")) $ filter ("" /=) $ lines s

-- Por cada linea del archivo se crea una Species
speciesParse :: [[String]] -> IMap.IntMap Species
speciesParse list = 
  IMap.fromList $ map (\x -> (no x,x)) $ map getEvolutions $ listSpecies
  where
    listSpecies = map species list
    species [sNo, sName, sPT1, sPT2, sHP, sAtk, sDef, sSpAtk, sSpDef, sSpd, sPreE, sCr] =
      Species 
        { no       = read sNo :: Int
        , name     = sName
        , pokeType = (read sPT1 :: Type) 
            : (if sPT2 /= "" then (read sPT2 :: Type) : [] else [])
        , base     = 
            Stats 
              { hp        = read sHP    :: Int
              , attack    = read sAtk   :: Int
              , defense   = read sDef   :: Int
              , spAttack  = read sSpAtk :: Int
              , spDefense = read sSpDef :: Int
              , speed     = read sSpd   :: Int
              }
        , preEvolution = 
            if sPreE /= "" 
            then Just Evolution { eNo = read sPreE :: Int, criterio = sCr } 
            else Nothing
        , evolutions   = []
        }
    -- Para hacer la lista de Evolution para cada Species
    getEvolutions :: Species -> Species
    getEvolutions x = 
      x { evolutions = 
            let 
              pre = fromJust.preEvolution
            in 
              map (\y -> Evolution { eNo = no y, criterio = criterio $ pre y }) 
                $ filter ((no x==).eNo.pre) 
                  $ filter (isJust.preEvolution) listSpecies
        }

-- Por cada linea del archivo se crea un Move
movesParse :: [[String]] -> Map.Map String Move
movesParse x = Map.fromList $ map (\x -> (moveName x, x)) $ map moves x
  where
  moves [mName, mType, mPhy, mPP, mPWR] = Move 
      { moveName = mName
      , moveType = read mType :: Type
      , physical = read mPhy  :: Bool
      , pp       = read mPP   :: Int
      , power    = read mPWR  :: Int
      }

-- Crea un Trainer con los Monster indicados en el archivo
trainerParse :: [[String]] -> IMap.IntMap Species -> Map.Map String Move -> Trainer
trainerParse list specs moves = Trainer { active = 0, pokeballs = map monster list }
  where
  monster [pSpec, pNick, pLVL, pAtk1, pAtk2, pAtk3, pAtk4] = 
    mons { presHP = maxHP mons
         , stats  = 
            Stats 
              { hp        = maxHP mons
              , attack    = stat  mons attack
              , defense   = stat  mons defense
              , spAttack  = stat  mons spAttack
              , spDefense = stat  mons spDefense
              , speed     = stat  mons speed
              }
         }
    where
    mons = 
      Monster 
        { species  = pokeSpecies
        , nickname = if pNick == "" then name pokeSpecies else pNick
        , lvl      = read pLVL :: Int
        , presHP   = 0 
        , moves    = getMoves $ filter ("" /=) [pAtk1, pAtk2, pAtk3, pAtk4]
        , stats    = base pokeSpecies
        , iv       = perfIV
        , ev       = perfEV
        }
      where
      pokeSpecies = fromJust $ IMap.lookup (read pSpec :: Int) specs
      getMoves = map (\nom -> MonsterMove { monMove = move nom, monPP = pp $ move nom })
        where
        move nom = fromJust $ Map.lookup nom moves
      perfIV = Stats 31 31 31 31 31 31 
      perfEV = Stats 255 255 255 255 255 255