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
    , currentTicket : RemoteData.WebData TicketData
    , password : String
    , zone : Time.Zone
    , tncLink : String
    , bookletLink : String
    , surveyLink : String
    }


type Msg
    = OnUrlRequest Browser.UrlRequest
    | OnUrlChange Url.Url
    | GotTicketData (Result.Result Http.Error TicketData)
    | OnPasswordChanged String
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

type alias TicketData =
    { title : String
    , venue : String
    , ticketID : String
    , date : String
    , seatID : Maybe String
    , surveyLink : String
    , bookletLink : String
    }

ticketDataDecoder : Json.Decode.Decoder TicketData
ticketDataDecoder =
    Json.Decode.succeed TicketData
        |> Json.Decode.Pipeline.required "title" Json.Decode.string
        |> Json.Decode.Pipeline.required "venue" Json.Decode.string
        |> Json.Decode.Pipeline.required "pk" Json.Decode.string
        |> Json.Decode.Pipeline.required "date" Json.Decode.string
        |> Json.Decode.Pipeline.optional "seat" (Json.Decode.map Just Json.Decode.string) Nothing
        |> Json.Decode.Pipeline.required "survey_link" Json.Decode.string
        |> Json.Decode.Pipeline.required "booklet_link" Json.Decode.string

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
