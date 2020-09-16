module Study exposing (..)

import Json.Decode as Decode exposing (Decoder, Value)
import Profile exposing (Profile)


type alias Study =
    { id : String
    , name : String
    , description : String
    , survivalOutcome : String
    , survivalTimeUnits : String
    , profiles : List Profile
    }


decoder : Decoder Study
decoder =
    Decode.map6 Study
        (Decode.field "ID" Decode.string)
        (Decode.field "NAME" Decode.string)
        (Decode.field "DESCRIPTION" Decode.string)
        (Decode.field "SURVIVAL_OUTCOME" Decode.string)
        (Decode.map String.toLower <| Decode.field "SURVIVAL_TIME_UNIT" Decode.string)
        -- filter out Z-scores, not meaningful for quantile-based division
        (Decode.field "PROFILES" (Profile.decoderList |> Decode.map (List.filter Profile.isNotZScore)))


decoderList : Decoder (List Study)
decoderList =
    Decode.list decoder
