module View exposing (..)

import Config exposing (Config)
import ConfigGene exposing (ConfigGene)
import ControlType exposing (ControlType)
import Dict
import Gene exposing (Gene)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import List.Extra
import Markdown
import Model exposing (Model)
import Msg exposing (Msg(..))
import RemoteData exposing (RemoteData(..))
import Side exposing (Side)
import Study exposing (Study)


tailwind : String -> Html.Attribute msg
tailwind =
    class



-- main view


view : Model -> Html Msg
view model =
    main_ [ class "main" ]
        [ section [ class "screen" ]
            [ article [ class "config-interface" ]
                [ header [ class "header" ]
                    [ h1 [ class "title" ] [ text "Multi-Gene Survival Tool" ]
                    , h2 [ class "subtitle" ]
                        [ text "A small web tool to perform cancer data survival analyses using multi-gene combinations on "
                        , a [ href "https://www.cbioportal.org/" ] [ text "cBioPortal data" ]
                        , text ". Developed at "
                        , a [ href "https://www.monash.edu/discovery-institute/nguyen-lab" ] [ text "Nguyen Lab (Monash BDI)." ]
                        ]
                    ]
                , section [ class "body" ]
                    [ section [ class "top" ]
                        [ article [ class "left" ]
                            [ h1 [ class "tagline" ] [ div [ class "circled" ] [ text "1" ], div [] [ text "Analyse this study..." ] ]
                            , viewInputStudy model
                            , div [ class "chosen-study-container" ] [ viewChosenStudy model ]
                            ]
                        , article [ class "right" ]
                            [ h1 [ class "tagline" ] [ div [ class "circled" ] [ text "2" ], div [] [ text "For this gene combination..." ] ]
                            , viewInputGene model
                            , div [] [ viewGeneConfig model ]
                            ]
                        ]
                    , div [ class "bottom" ]
                        [ viewSubmitButton model
                        ]
                    ]
                ]
            ]
        , section [] []
        ]



-- events


{-| Custom onBlur event which does not trigger if the target has a supplied class
-}
onBlurExcept : String -> (String -> Msg) -> Attribute Msg
onBlurExcept okayClass msg =
    let
        matchClass classes =
            if String.contains okayClass classes then
                NoOp

            else
                msg classes

        decoder =
            Decode.oneOf
                [ Decode.field "relatedTarget" (Decode.null (msg "null"))
                , Decode.field "relatedTarget" (Decode.field "className" Decode.string)
                    |> Decode.map matchClass
                ]
    in
    on "blur" decoder



-- helpers


{-| Input to search studies and show study results for selection.
-}
viewInputStudy : Model -> Html Msg
viewInputStudy model =
    let
        placeholderText =
            case model.inputStudyRemote of
                Loading ->
                    "Loading"

                _ ->
                    case model.configInProgress.study of
                        Just study ->
                            "Or search for a different study here..."

                        _ ->
                            "Search available studies e.g. \"lung\"..."
    in
    case model.inputStudyRemote of
        Failure e ->
            article [] [ text ("Oops, there was a problem loading studies from the server. The reason is:\n" ++ RemoteData.errorString e) ]

        _ ->
            article [ class "study-input-container" ]
                [ input
                    [ onInput ChangedStudyString
                    , onBlurExcept "study-result" UnfocusedStudyString
                    , onFocus (ChangedStudyString model.inputStudyString)
                    , id "study-selector"
                    , disabled (RemoteData.isLoading model.inputStudyRemote)
                    , placeholder placeholderText
                    , value model.inputStudyString
                    , type_ "text"
                    ]
                    []
                , article [ id "study-results" ] [ viewInputStudyResults model ]
                ]


{-| Generic search result element
-}
viewResult : String -> msg -> String -> String -> Html msg
viewResult classString onClickMsg major minor =
    button
        [ onClick onClickMsg
        , class classString
        , classList [ ( "search-result", True ) ]
        ]
        [ div [ class "major" ] [ text major ]
        , div [ class "minor" ] [ text minor ]
        ]


{-| Study search results
-}
viewInputStudyResults : Model -> Html Msg
viewInputStudyResults model =
    article [ id "study-results-absolute" ]
        (List.map (\s -> viewResult "study-result" (ClickedStudy s) s.name s.id) model.inputStudyFiltered)


{-| Element to view meta data on the chosen study
-}
viewChosenStudy : Model -> Html Msg
viewChosenStudy model =
    let
        {- Controlled by the backend, so sanitize = False as some descriptions from cBioPortal contain HTML. -}
        markdownOptions =
            { githubFlavored = Nothing, defaultHighlighting = Nothing, sanitize = False, smartypants = False }
    in
    case model.configInProgress.study of
        Just study ->
            article [ id "chosen-study" ]
                [ h3 [ class "study-name" ] [ text study.name ]
                , h4 [ class "study-id" ] [ text study.id ]
                , div [ class "study-body" ]
                    [ text "The best survival outcome available for this study is "
                    , strong [] [ text (String.toLower study.survivalOutcome) ]
                    , text " measured in "
                    , strong [] [ text study.survivalTimeUnits ]
                    , text "."
                    , text " The selected molecular profile for this study is "
                    , viewProfileSelect model
                    , text "."
                    ]
                , p [ class "study-description" ] [ text "This study's cBioPortal description is:" ]
                , p [ class "study-description-quote" ] [ Markdown.toHtmlWith markdownOptions [ class "markdown" ] study.description ]
                ]

        Nothing ->
            article [ id "chosen-study" ] []


viewProfileSelect : Model -> Html Msg
viewProfileSelect model =
    let
        profiles =
            case model.configInProgress.study of
                Just study ->
                    study.profiles

                _ ->
                    []

        profileToOption profile =
            option
                [ value profile.id
                , selected
                    (model.configInProgress.profile
                        |> Maybe.map (\p -> p.id == profile.id)
                        |> Maybe.withDefault False
                    )
                ]
                [ text profile.name ]
    in
    select
        [ class "profile-select"
        , onInput (\id -> List.Extra.find (\p -> p.id == id) profiles |> Maybe.map SelectedMolecularProfile |> Maybe.withDefault NoOp)
        ]
        (List.map profileToOption profiles)


{-| Input element to search genes
-}
viewInputGene : Model -> Html Msg
viewInputGene model =
    case model.inputStudyRemote of
        Failure e ->
            article [] [ text "There was a problem loading genes from the server as well, probably for the same reason..." ]

        _ ->
            article [ class "gene-input-container" ]
                [ input
                    [ onInput ChangedGeneString
                    , onBlurExcept "gene-result" UnfocusedGeneString
                    , onFocus FocusedGeneString
                    , id "gene-selector"
                    , placeholder "Search for a gene to add to the combination e.g. \"TP53\"..."
                    , value model.inputGeneString
                    , type_ "text"
                    ]
                    []
                , article [ id "gene-results", tailwind "relative w-full" ] [ viewGeneResults model ]
                ]


{-| Gene search results
-}
viewGeneResults : Model -> Html Msg
viewGeneResults model =
    case ( model.inputGeneRemote, model.inputGeneRemoteShow ) of
        ( Success genes, True ) ->
            let
                constructMinor gene =
                    String.join ""
                        [ gene.name
                        , " (Entrez ID "
                        , gene.entrez
                        , ")"
                        ]
            in
            article [ id "gene-results-absolute" ]
                (List.map (\g -> viewResult "gene-result" (ClickedGene g) g.hugo (constructMinor g)) genes.results)

        _ ->
            article [] []


{-| View a single gene configuration
-}
viewSingleGeneConfig : String -> ConfigGene -> Html Msg
viewSingleGeneConfig _ gene =
    article
        [ class "single-gene-config" ]
        [ section [ class "gene-left" ]
            [ div [ class "gene-hugo" ] [ text gene.gene.hugo ]
            , viewSideSelect gene
            , div [ class "gene-the" ] [ text "the" ]
            , input
                [ type_ "number"
                , value (String.fromInt gene.threshold)
                , class "gene-threshold"
                , Html.Attributes.min "0"
                , Html.Attributes.max "100"
                , step "1"
                , onInput (\s -> ChangedGeneThreshold gene.gene gene.side (String.toInt s |> Maybe.withDefault 50))
                ]
                []
            , div [ class "quantile" ] [ text "-th percentile, with" ]
            , viewControlTypeSelect gene
            , div [ class "controls" ] [ text "controls." ]
            ]
        , div [ class "gene-right" ] (viewRangeInput gene)
        , div [ class "gene-end" ] [ button [ onClick (ClickedDeleteGene gene.gene) ] [ text "×" ] ]
        ]


viewRangeInput : ConfigGene -> List (Html Msg)
viewRangeInput gene =
    case gene.controlType of
        ControlType.Complement ->
            [ div
                [ classList [ ( "shading-test", not (Side.isAbove gene.side) ), ( "shading-control", Side.isAbove gene.side ) ]
                , style "width" (String.fromInt gene.threshold ++ "%")
                ]
                []
            , div
                [ classList [ ( "shading-control", not (Side.isAbove gene.side) ), ( "shading-test", Side.isAbove gene.side ) ]
                , style "width" (String.fromInt (100 - gene.threshold) ++ "%")
                , style "left" (String.fromInt gene.threshold ++ "%")
                ]
                []
            , input
                [ type_ "range"
                , value (String.fromInt gene.threshold)
                , class "gene-slider"
                , Html.Attributes.min "0"
                , Html.Attributes.max "100"
                , step "1"
                , onInput (\s -> ChangedGeneThreshold gene.gene gene.side (String.toInt s |> Maybe.withDefault 50))
                ]
                []
            ]

        ControlType.Mirrored ->
            let
                threshBelow50 =
                    if gene.threshold > 50 then
                        100 - gene.threshold

                    else
                        gene.threshold

                middleWidth =
                    100 - (threshBelow50 * 2)
            in
            [ div
                [ classList [ ( "shading-test", not (Side.isAbove gene.side) ), ( "shading-control", Side.isAbove gene.side ) ]
                , style "width" (String.fromInt threshBelow50 ++ "%")
                ]
                []
            , div
                [ class "shading-neutral"
                , style "width" (String.fromInt middleWidth ++ "%")
                , style "left" (String.fromInt threshBelow50 ++ "%")
                ]
                []
            , div
                [ classList [ ( "shading-control", not (Side.isAbove gene.side) ), ( "shading-test", Side.isAbove gene.side ) ]
                , style "width" (String.fromInt threshBelow50 ++ "%")
                , style "left" (String.fromInt (middleWidth + threshBelow50) ++ "%")
                ]
                []
            , input
                [ type_ "range"
                , value (String.fromInt gene.threshold)
                , class "gene-slider"
                , Html.Attributes.min "0"
                , Html.Attributes.max "100"
                , step "1"
                , onInput (\s -> ChangedGeneThreshold gene.gene gene.side (String.toInt s |> Maybe.withDefault 50))
                ]
                []
            ]


viewSideSelect : ConfigGene -> Html Msg
viewSideSelect gene =
    select
        [ class "side-select"
        , onInput (\s -> SelectedGeneSide gene.gene (Side.fromString s |> Maybe.withDefault Side.Above))
        ]
        [ option [ value (Side.toString Side.Above), selected (Side.isAbove gene.side) ] [ text (Side.toString Side.Above) ]
        , option [ value (Side.toString Side.Below), selected (not <| Side.isAbove gene.side) ] [ text (Side.toString Side.Below) ]
        ]


viewControlTypeSelect : ConfigGene -> Html Msg
viewControlTypeSelect gene =
    select
        [ class "control-type-select"
        , onInput (\s -> SelectedGeneControlType gene.gene (ControlType.fromString s |> Maybe.withDefault ControlType.Complement))
        ]
        [ option [ value (ControlType.toString ControlType.Complement), selected (ControlType.isComplement gene.controlType) ] [ text (ControlType.toString ControlType.Complement) ]
        , option [ value (ControlType.toString ControlType.Mirrored), selected (not <| ControlType.isComplement gene.controlType) ] [ text (ControlType.toString ControlType.Mirrored) ]
        ]


{-| Gene configuration editor
-}
viewGeneConfig : Model -> Html Msg
viewGeneConfig model =
    if Dict.isEmpty model.configInProgress.genes then
        section [] []

    else
        section [ id "all-gene-config" ]
            [ div [ class "all-gene-statement" ] [ text "This will select a ", strong [ class "orange" ] [ text "test group" ], text " based on satisfying ALL of the quantile test criteria below," ]
            , div [ class "second-gene-statement" ] [ text "and will select a ", strong [ class "blue" ] [ text "control group" ], text " based on either remaining cases, or on mirrored test quantiles." ]
            , div [] (Dict.values (Dict.map viewSingleGeneConfig model.configInProgress.genes))
            ]


viewSubmitButton : Model -> Html Msg
viewSubmitButton model =
    case Config.validate model.configInProgress of
        Just config ->
            button
                [ class "submit-button"
                , onClick ClickedSubmitAnalysis
                ]
                [ text "Submit for Analysis" ]

        _ ->
            button
                [ class "submit-button"
                , disabled True
                ]
                [ text "Choose a study and at least one gene." ]
