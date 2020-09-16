module RemoteData exposing (..)

import Http exposing (Error(..))


type RemoteData a
    = NotAsked
    | Loading
    | Success a
    | Failure Error


errorString : Error -> String
errorString error =
    case error of
        BadUrl s ->
            "The following URL was invalid: " ++ s

        Timeout ->
            "The request timed out."

        NetworkError ->
            "There was a network connection error."

        BadStatus c ->
            "The server returned an error code: " ++ String.fromInt c

        BadBody b ->
            "The server's response was not decodable: " ++ b


fromResult : Result Error a -> RemoteData a
fromResult result =
    case result of
        Ok data ->
            Success data

        Err e ->
            Failure e


isLoading : RemoteData a -> Bool
isLoading remote =
    case remote of
        Loading ->
            True

        _ ->
            False


isSuccess : RemoteData a -> Bool
isSuccess remote =
    case remote of
        Success _ ->
            True

        _ ->
            False


isFailure : RemoteData a -> Bool
isFailure remote =
    case remote of
        Failure _ ->
            True

        _ ->
            False


isNotAsked : RemoteData a -> Bool
isNotAsked remote =
    case remote of
        NotAsked ->
            True

        _ ->
            False
