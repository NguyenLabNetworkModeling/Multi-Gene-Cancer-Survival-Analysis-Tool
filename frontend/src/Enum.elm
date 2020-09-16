module Enum exposing (..)

{-| This is a "dictionary of functions" approach to polymorphism
with types that can be enumerated
-}

import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode


{-| An type which can be enumerated.
-}
type alias Enum a =
    { list : List a
    , fromString : String -> Maybe a
    , toString : a -> String
    }


{-| Encode an enum into a JSON value.
-}
encode : Enum a -> a -> Value
encode enum a =
    Encode.string (enum.toString a)


{-| Decode an enum value from a string
-}
decodeString : Enum a -> String -> Decoder a
decodeString enum string =
    case enum.fromString string of
        Just a ->
            Decode.succeed a

        Nothing ->
            Decode.fail ("Invalid enum value: " ++ string)


{-| Decode a side from strings "above" and "below".
-}
decoder : Enum a -> Decoder a
decoder enum =
    Decode.string
        |> Decode.andThen (decodeString enum)
