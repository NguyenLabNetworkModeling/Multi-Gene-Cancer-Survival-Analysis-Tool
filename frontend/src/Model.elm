module Model exposing (..)

import Analysis exposing (Analysis)
import Config exposing (Config)
import Dict
import Gene exposing (Gene)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import RemoteData exposing (RemoteData(..))
import Side exposing (Side)
import Study exposing (Study)


type alias Model =
    { inputStudyRemote : RemoteData (List Study)
    , inputStudyString : String
    , inputStudyFiltered : List Study
    , inputGeneString : String
    , inputGeneRemote : RemoteData Gene.Results
    , inputGeneRemoteShow : Bool
    , configInProgress : Config.InProgress
    , analysisRemote : RemoteData Analysis
    }


default : Model
default =
    { inputStudyRemote = Loading
    , inputStudyString = ""
    , inputStudyFiltered = []
    , inputGeneString = ""
    , inputGeneRemote = NotAsked
    , inputGeneRemoteShow = False
    , configInProgress = Config.default
    , analysisRemote = NotAsked
    }
