module Types exposing (..)

import Browser
import Browser.Navigation
import Http
import Json.Decode
import Json.Decode.Pipeline
import RemoteData exposing (RemoteData)
import Route
import Time
import Url


type alias Model =
    { apiKey : String
    , currentPage : Route.Page
    , lambdaUrl : String
    , navKey : Browser.Navigation.Key
    , currentTicket : RemoteData.WebData TicketStatus
    , password : String
    , zone : Time.Zone
    , tncLink : String
    , bookletLink : String
    , surveyLink : String
    }


type Msg
    = OnUrlRequest Browser.UrlRequest
    | OnUrlChange Url.Url
    | GotTicketStatus (Result.Result Http.Error TicketStatus)
    | OnPasswordChanged String
    | OnMarkAsScannedSubmitted String
    | TicketMarkedAsScanned String (Result.Result Http.Error MarkTicketAsScannedResponse)
    | AdjustTimeZone Time.Zone


type alias Flags =
    { apiKey : String
    , lambdaUrl : String
    , tncLink : String
    , bookletLink : String
    , surveyLink : String
    }


type alias TicketStatus =
    { seatID : String
    , ticketID : String
    , scannedAt : Maybe Time.Posix
    , startTime : String
    }


ticketStatusDecoder : Json.Decode.Decoder TicketStatus
ticketStatusDecoder =
    Json.Decode.succeed TicketStatus
        |> Json.Decode.Pipeline.required "seat_id" Json.Decode.string
        |> Json.Decode.Pipeline.required "ticket_id" Json.Decode.string
        |> Json.Decode.Pipeline.optional "scanned_at" decodeTimePosix Nothing
        |> Json.Decode.Pipeline.required "start_time" Json.Decode.string


emptyTicketStatus : TicketStatus
emptyTicketStatus =
    { seatID = "", ticketID = "", scannedAt = Nothing, startTime = "" }


type alias MarkTicketAsScannedResponse =
    { status : String }


markTicketAsScannedResponseDecoder : Json.Decode.Decoder MarkTicketAsScannedResponse
markTicketAsScannedResponseDecoder =
    Json.Decode.succeed MarkTicketAsScannedResponse
        |> Json.Decode.Pipeline.required "status" Json.Decode.string


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


toMonthStr : Time.Month -> String
toMonthStr month =
    case month of
        Time.Jan ->
            "Jan"

        Time.Feb ->
            "Feb"

        Time.Mar ->
            "Mar"

        Time.Apr ->
            "Apr"

        Time.May ->
            "May"

        Time.Jun ->
            "Jun"

        Time.Jul ->
            "Jul"

        Time.Aug ->
            "Aug"

        Time.Sep ->
            "Sep"

        Time.Oct ->
            "Oct"

        Time.Nov ->
            "Nov"

        Time.Dec ->
            "Dec"
