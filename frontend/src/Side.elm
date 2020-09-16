module Side exposing (..)

{-| Generic side module.

Sides are used here primarily for referring to whether a gene should be included
in a test group if it is _above_ or _below_ a specified threshold quantile.

-}

import Enum exposing (Enum)


{-| A side can be above or below a threshold.
-}
type Side
    = Above
    | Below


{-| Convert a side to a string "above" or "below".
-}
toString : Side -> String
toString side =
    case side of
        Above ->
            "above"

        Below ->
            "below"


{-| Convert a side from a string "above" or "below".
-}
fromString : String -> Maybe Side
fromString string =
    case string of
        "above" ->
            Just Above

        "below" ->
            Just Below

        _ ->
            Nothing


{-| A list of sides.
-}
list : List Side
list =
    [ Above, Below ]


{-| Interface for enumerable
-}
enum : Enum Side
enum =
    { toString = toString
    , fromString = fromString
    , list = list
    }


isAbove : Side -> Bool
isAbove side =
    case side of
        Above ->
            True

        Below ->
            False
