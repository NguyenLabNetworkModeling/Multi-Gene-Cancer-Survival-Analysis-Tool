module Msg exposing (..)

import Analysis exposing (Analysis)
import Api
import Config exposing (Config)
import ControlType exposing (ControlType)
import Gene exposing (Gene)
import Profile exposing (Profile)
import RemoteData exposing (RemoteData(..))
import Side exposing (Side)
import Study exposing (Study)


type Msg
    = GotStudies (RemoteData (List Study))
    | GotGenes String (RemoteData Gene.Results)
    | ChangedStudyString String
    | UnfocusedStudyString String
    | FocusedGeneString
    | UnfocusedGeneString String
    | ClickedStudy Study
    | SelectedMolecularProfile Profile
    | ChangedGeneString String
    | ClickedGene Gene
    | SelectedGeneSide Gene Side
    | SelectedGeneControlType Gene ControlType
    | ChangedGeneThreshold Gene Side Int
    | ClickedDeleteGene Gene
    | Tick String
    | ClickedSubmitAnalysis
    | GotAnalysis Config (RemoteData String)
    | ClosedAnalysisModal ()
    | NoOp
