module Update exposing (..)

import Api
import Browser
import Config exposing (Config)
import Dict
import Gene exposing (Gene)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Markdown
import Model exposing (Model)
import Msg exposing (Msg(..))
import RemoteData exposing (RemoteData(..))
import Side exposing (Side)
import Study exposing (Study)



-- Init


init : () -> ( Model, Cmd Msg )
init flags =
    ( Model.default
    , Api.getStudies GotStudies
    )



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ configInProgress } as model) =
    case msg of
        GotStudies data ->
            { model | inputStudyRemote = data }
                |> withCmdNone

        GotGenes request data ->
            -- only update if returned prefix is the same as current model
            if request == model.inputGeneString then
                case data of
                    -- remove any genes already added to the config
                    Success genes ->
                        { model | inputGeneRemote = Success { prefix = genes.prefix, results = List.filter (\g -> not (Dict.member g.hugo model.configInProgress.genes)) genes.results } }
                            |> withCmdNone

                    _ ->
                        { model | inputGeneRemote = data }
                            |> withCmdNone

            else
                model |> withCmdNone

        ChangedStudyString string ->
            -- only update filtered study list if studies are available
            case model.inputStudyRemote of
                Success studies ->
                    -- only update filtered study list if filter string is at least one character
                    if String.length string >= 1 then
                        { model
                            | inputStudyString = string
                            , inputStudyFiltered = studies |> List.filter (.name >> String.toLower >> String.contains (String.toLower string))
                        }
                            |> withCmdNone

                    else
                        { model | inputStudyString = string, inputStudyFiltered = [] }
                            |> withCmdNone

                _ ->
                    { model | inputStudyString = string, inputStudyFiltered = [] }
                        |> withCmdNone

        UnfocusedStudyString _ ->
            { model | inputStudyFiltered = [] }
                |> withCmdNone

        ClickedStudy study ->
            { model
                | configInProgress = { configInProgress | study = Just study, profile = List.head study.profiles }
                , inputStudyString = ""
                , inputStudyFiltered = []
            }
                |> withCmdNone

        SelectedMolecularProfile profile ->
            { model
                | configInProgress = { configInProgress | profile = Just profile }
            }
                |> withCmdNone

        ChangedGeneString string ->
            case model.inputGeneRemote of
                Success results ->
                    let
                        lowerOld =
                            String.toLower results.prefix

                        lowerNew =
                            String.toLower string
                    in
                    -- just reuse the previous if previous is a prefix of the current input
                    if String.startsWith lowerOld lowerNew then
                        { model
                            | inputGeneRemote =
                                Success
                                    { prefix = lowerNew
                                    , results = List.filter (.hugo >> String.toLower >> String.startsWith lowerNew) results.results
                                    }
                            , inputGeneString = string
                            , inputGeneRemoteShow = True
                        }
                            |> withCmdNone

                    else
                        { model
                            | inputGeneString = string
                            , inputGeneRemote = NotAsked
                            , inputGeneRemoteShow = True
                        }
                            |> withCmdNone

                _ ->
                    { model
                        | inputGeneString = string
                        , inputGeneRemote = NotAsked
                        , inputGeneRemoteShow = True
                    }
                        |> withCmdNone

        FocusedGeneString ->
            { model | inputGeneRemoteShow = True }
                |> withCmdNone

        UnfocusedGeneString _ ->
            { model | inputGeneRemoteShow = False }
                |> withCmdNone

        ClickedGene gene ->
            { model
                | configInProgress = configInProgress |> Config.addGene gene
                , inputGeneString = ""
                , inputGeneRemote = NotAsked
                , inputGeneRemoteShow = False
            }
                |> withCmdNone

        -- only request if current gene string is the same as when the tick was sent
        Tick string ->
            if string == model.inputGeneString then
                { model | inputGeneRemote = Loading }
                    |> withCmd (Api.getGenes model.inputGeneString GotGenes)

            else
                model |> withCmdNone

        SelectedGeneSide gene side ->
            { model | configInProgress = configInProgress |> Config.updateGeneSide gene side }
                |> withCmdNone

        SelectedGeneControlType gene controlType ->
            { model | configInProgress = configInProgress |> Config.updateGeneControlType gene controlType }
                |> withCmdNone

        ChangedGeneThreshold gene side threshold ->
            { model | configInProgress = configInProgress |> Config.updateGeneThreshold gene side threshold }
                |> withCmdNone

        ClickedDeleteGene gene ->
            { model | configInProgress = configInProgress |> Config.removeGene gene }
                |> withCmdNone

        ClickedSubmit config ->
            case model.analysisRemote of
                NotAsked ->
                    { model | analysisRemote = Loading } |> withCmd (Api.submitAnalysis config GotAnalysis)

                Failure _ ->
                    { model | analysisRemote = Loading } |> withCmd (Api.submitAnalysis config GotAnalysis)

                _ ->
                    model |> withCmdNone

        GotAnalysis config analysis ->
            { model | analysisRemote = analysis } |> withCmdNone

        NoOp ->
            model |> withCmdNone



-- HELPERS


withCmd : Cmd Msg -> Model -> ( Model, Cmd Msg )
withCmd cmd model =
    ( model, cmd )


withCmdNone : Model -> ( Model, Cmd Msg )
withCmdNone model =
    ( model, Cmd.none )
