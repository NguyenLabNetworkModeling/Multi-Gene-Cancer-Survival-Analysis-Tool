module Profile exposing (..)

import Json.Decode as Decode exposing (Decoder)


type alias Profile =
    { id : String
    , name : String
    , description : String
    , datatype : String
    , studyId : String
    }


decoder : Decoder Profile
decoder =
    Decode.map5 Profile
        (Decode.field "PROFILE_ID" Decode.string)
        (Decode.field "NAME" Decode.string)
        (Decode.field "DESCRIPTION" Decode.string)
        (Decode.field "DATATYPE" Decode.string)
        (Decode.field "STUDY_ID" Decode.string)


decoderList : Decoder (List Profile)
decoderList =
    Decode.list decoder


isNotZScore : Profile -> Bool
isNotZScore profile =
    profile.datatype /= "Z-SCORE"
