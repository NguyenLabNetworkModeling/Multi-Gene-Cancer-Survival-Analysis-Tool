module Api exposing (RemoteData(..), getStudies, getGenes, checkGene)

{-| API interface.
-}

import Gene
import Http exposing (Error)
import Study exposing (Study)
import Url.Builder as Builder exposing (crossOrigin)


type RemoteData a
    = NotAsked
    | Loading
    | Success a
    | Failure Error


resultToRemoteData : Result Error a -> RemoteData a
resultToRemoteData result =
    case result of
        Ok data ->
            Success data

        Err e ->
            Failure e


{-| API endpoints in the backend.

  - GetStudies: get all valid studies.
  - SearchGenes: search genes by HUGO prefix.
  - CheckGene: check whether a HUGO symbol string is valid.

-}
type Endpoint
    = GetStudies
    | SearchGenes String
    | CheckGene String


{-| Backend API base URL.
-}
baseUrl : String
baseUrl =
    "http://127.0.0.1:8080"


{-| Convert an endpoint to a URL.
-}
endpointToUrl : Endpoint -> String
endpointToUrl endpoint =
    let
        ( paths, queries ) =
            case endpoint of
                GetStudies ->
                    ( [ "study" ], [] )

                SearchGenes prefix ->
                    ( [ "gene" ], [ Builder.string "prefix" prefix ] )

                CheckGene hugo ->
                    ( [ "gene", "check" ], [ Builder.string "hugo" hugo ] )
    in
    crossOrigin baseUrl paths queries


{-| Supply a callback and get a list of all valid studies
-}
getStudies : (RemoteData (List Study) -> msg) -> Cmd msg
getStudies callback =
    Http.get
        { url = endpointToUrl GetStudies
        , expect = Http.expectJson (resultToRemoteData >> callback) Study.decoderList
        }


{-| Supply a callback and a prefix and get a list of matching genes
-}
getGenes : String -> (String -> RemoteData Gene.Results -> msg) -> Cmd msg
getGenes prefix callback =
    Http.get
        { url = endpointToUrl (SearchGenes prefix)
        , expect = Http.expectJson (resultToRemoteData >> callback prefix) Gene.decoderResults
        }


{-| Supply a callback and a HUGO gene string and check if it is valid
-}
checkGene : String -> (String -> RemoteData Gene.Validity -> msg) -> Cmd msg
checkGene hugo callback =
    Http.get
        { url = endpointToUrl (CheckGene hugo)
        , expect = Http.expectJson (resultToRemoteData >> callback hugo) Gene.decoderValidity
        }
