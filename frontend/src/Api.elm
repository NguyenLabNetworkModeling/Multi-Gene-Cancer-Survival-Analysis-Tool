module Api exposing (checkGene, getGenes, getStudies, submitAnalysis)

{-| API interface.
-}

import Analysis exposing (Analysis)
import Config exposing (Config)
import Gene
import Http exposing (Error(..))
import RemoteData exposing (RemoteData(..))
import Study exposing (Study)
import Url.Builder as Builder exposing (crossOrigin)


{-| API endpoints in the backend.

  - GetStudies: get all valid studies.
  - SearchGenes: search genes by HUGO prefix.
  - CheckGene: check whether a HUGO symbol string is valid.

-}
type Endpoint
    = GetStudies
    | SearchGenes String
    | CheckGene String
    | SubmitAnalysis Config


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

                SubmitAnalysis config ->
                    ( [ "analysis" ], [] )
    in
    crossOrigin baseUrl paths queries


{-| Supply a callback and get a list of all valid studies
-}
getStudies : (RemoteData (List Study) -> msg) -> Cmd msg
getStudies callback =
    Http.get
        { url = endpointToUrl GetStudies
        , expect = Http.expectJson (RemoteData.fromResult >> callback) Study.decoderList
        }


{-| Supply a callback and a prefix and get a list of matching genes
-}
getGenes : String -> (String -> RemoteData Gene.Results -> msg) -> Cmd msg
getGenes prefix callback =
    Http.get
        { url = endpointToUrl (SearchGenes prefix)
        , expect = Http.expectJson (RemoteData.fromResult >> callback prefix) Gene.decoderResults
        }


{-| Supply a callback and a HUGO gene string and check if it is valid
-}
checkGene : String -> (String -> RemoteData Gene.Validity -> msg) -> Cmd msg
checkGene hugo callback =
    Http.get
        { url = endpointToUrl (CheckGene hugo)
        , expect = Http.expectJson (RemoteData.fromResult >> callback hugo) Gene.decoderValidity
        }


submitAnalysis : Config -> (Config -> RemoteData Analysis -> msg) -> Cmd msg
submitAnalysis config callback =
    Cmd.none



{-
   Http.post
       { url = endpointToUrl (SubmitAnalysis config)
       , expect = Http.expectJson (An)}
-}
