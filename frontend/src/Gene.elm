module Gene exposing (..)

import Json.Decode as Decode exposing (Decoder)


type alias Gene =
    { hugo : String
    , entrez : String
    , name : String
    }


decoder : Decoder Gene
decoder =
    Decode.map3 Gene
        (Decode.field "hugo" Decode.string)
        (Decode.field "entrez" Decode.string)
        (Decode.field "name" Decode.string)


type alias Results =
    { prefix : String
    , results : List Gene
    }


decoderResults : Decoder Results
decoderResults =
    Decode.map2 Results
        (Decode.field "query" Decode.string)
        (Decode.field "results" (Decode.list decoder))


type alias Validity =
    { hugo : String
    , valid : Bool
    }


decoderValidity : Decoder Validity
decoderValidity =
    Decode.map2 Validity
        (Decode.field "query" Decode.string)
        (Decode.field "valid" Decode.bool)
