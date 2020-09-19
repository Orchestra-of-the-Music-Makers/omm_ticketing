module Types exposing (..)

import Browser
import Browser.Navigation
import Http
import Iso8601
import Json.Decode
import Json.Decode.Extra
import Json.Decode.Pipeline
import Route
import Time
import Url


type alias Model =
    { apiKey : String
    , currentPage : Route.Page
    , lambdaUrl : String
    , navKey : Browser.Navigation.Key
    , currentTicket : Maybe GetTicketStatusResponse
    }


type Msg
    = OnUrlRequest Browser.UrlRequest
    | OnUrlChange Url.Url
    | GotTicketStatus (Result.Result Http.Error GetTicketStatusResponse)


type alias Flags =
    { apiKey : String
    , lambdaUrl : String
    }


type alias GetTicketStatusResponse =
    { seatID : String
    , ticketID : String
    , scannedAt : Maybe Time.Posix
    }


getTicketStatusResponseDecoder : Json.Decode.Decoder GetTicketStatusResponse
getTicketStatusResponseDecoder =
    Json.Decode.succeed GetTicketStatusResponse
        |> Json.Decode.Pipeline.required "seat_id" Json.Decode.string
        |> Json.Decode.Pipeline.required "ticket_id" Json.Decode.string
        |> Json.Decode.Pipeline.optional "scanned_at" decodeTimePosix Nothing


emptyGetTicketStatusResponse : GetTicketStatusResponse
emptyGetTicketStatusResponse =
    { seatID = "", ticketID = "", scannedAt = Nothing }


decodeTimePosix : Json.Decode.Decoder (Maybe Time.Posix)
decodeTimePosix =
    let
        maybeIntToMaybePosix : Maybe Int -> Json.Decode.Decoder (Maybe Time.Posix)
        maybeIntToMaybePosix maybeInt =
            case maybeInt of
                Just ms ->
                    Json.Decode.succeed <| Just (Time.millisToPosix (ms * 1000))

                Nothing ->
                    Json.Decode.succeed Nothing
    in
    Json.Decode.nullable Json.Decode.int
        |> Json.Decode.andThen maybeIntToMaybePosix
