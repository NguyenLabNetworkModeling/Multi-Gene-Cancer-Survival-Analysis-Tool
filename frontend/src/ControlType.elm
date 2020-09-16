module ControlType exposing (..)

import Enum exposing (Enum)


{-| Basic control type.

A control type can be a mirrored criteria (i.e. having a threshold on the
"opposite" side of the quantile) or a complement of any case which does not
fulfil the test criteria.

-}
type ControlType
    = Mirrored
    | Complement


toString : ControlType -> String
toString controlType =
    case controlType of
        Mirrored ->
            "mirrored"

        Complement ->
            "complement"


fromString : String -> Maybe ControlType
fromString string =
    case string of
        "mirrored" ->
            Just Mirrored

        "complement" ->
            Just Complement

        _ ->
            Nothing


list : List ControlType
list =
    [ Complement, Mirrored ]


{-| Interface for enumerable
-}
enum : Enum ControlType
enum =
    { toString = toString
    , fromString = fromString
    , list = list
    }


isComplement : ControlType -> Bool
isComplement controlType =
    case controlType of
        Complement ->
            True

        Mirrored ->
            False
