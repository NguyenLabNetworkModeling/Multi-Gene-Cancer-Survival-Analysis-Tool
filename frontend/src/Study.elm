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
        (Decode.field "SURVIVAL_TIME_UNIT" Decode.string)
        (Decode.field "PROFILES" Profile.decoderList)


decoderList : Decoder (List Study)
decoderList =
    Decode.list decoder
