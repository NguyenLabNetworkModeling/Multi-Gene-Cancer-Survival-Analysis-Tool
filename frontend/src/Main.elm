module Main exposing (..)

import Api exposing (RemoteData(..))
import Browser
import Gene exposing (Gene)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Study exposing (Study)
import Time



---- MODEL ----


type alias Model =
    { configStudies : RemoteData (List Study)
    , configGeneString : String
    , configGenes : RemoteData Gene.Results
    , configGeneValidity : RemoteData Gene.Validity
    }


defaultModel : Model
defaultModel =
    { configStudies = Loading
    , configGeneString = ""
    , configGenes = NotAsked
    , configGeneValidity = NotAsked
    }


init : () -> ( Model, Cmd Msg )
init flags =
    ( defaultModel
    , Api.getStudies GotStudies
    )



---- UPDATE ----


type Msg
    = GotStudies (RemoteData (List Study))
    | GotGenes String (RemoteData Gene.Results)
    | GotGeneValidity String (RemoteData Gene.Validity)
    | ChangedGeneString String
    | ClickedValidateGene
    | Tick String


withCmd : Cmd Msg -> Model -> ( Model, Cmd Msg )
withCmd cmd model =
    ( model, cmd )


withCmdNone : Model -> ( Model, Cmd Msg )
withCmdNone model =
    ( model, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotStudies data ->
            { model | configStudies = data }
                |> withCmdNone

        GotGenes request data ->
            -- only update if returned prefix is the same as current model
            if request == model.configGeneString then
                { model | configGenes = data }
                    |> withCmdNone

            else
                model |> withCmdNone

        GotGeneValidity request data ->
            -- only update if returned hugo symbol is the same as current model
            if request == model.configGeneString then
                { model | configGeneValidity = data }
                    |> withCmdNone

            else
                model |> withCmdNone

        ChangedGeneString string ->
            { model | configGeneString = string, configGenes = NotAsked }
                |> withCmdNone

        ClickedValidateGene ->
            { model | configGeneValidity = Loading }
                |> withCmd (Api.checkGene model.configGeneString GotGeneValidity)

        -- only request if current gene string is the same as when the tick was sent
        Tick string ->
            if string == model.configGeneString then
                { model | configGenes = Loading }
                    |> withCmd (Api.getGenes model.configGeneString GotGenes)

            else
                model |> withCmdNone



---- VIEW ----


view : Model -> Html Msg
view model =
    div
        []
        [ input [ onInput ChangedGeneString ] [] ]



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    -- tick the timer if configGenes is not asked and the prefix length is more than 1
    case model.configGenes of
        NotAsked ->
            if String.length model.configGeneString > 1 then
                Time.every 800 (\_ -> Tick model.configGeneString)

            else
                Sub.none

        _ ->
            Sub.none



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
