module Types exposing (..)

import Browser
import Browser.Navigation
import Http
import Iso8601
import Json.Decode
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
    Json.Decode.map3 GetTicketStatusResponse
        (Json.Decode.field "seat_id" Json.Decode.string)
        (Json.Decode.field "ticket_id" Json.Decode.string)
        (Json.Decode.field "scanned_at" (Json.Decode.nullable decodeTimePosix))


emptyGetTicketStatusResponse : GetTicketStatusResponse
emptyGetTicketStatusResponse =
    { seatID = "", ticketID = "", scannedAt = Nothing }


decodeTimePosix : Json.Decode.Decoder Time.Posix
decodeTimePosix =
    Json.Decode.int
        |> Json.Decode.andThen
            (\ms ->
                Json.Decode.succeed <| Time.millisToPosix (ms * 1000)
            )
