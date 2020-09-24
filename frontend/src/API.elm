module API exposing (..)

import Http
import Json.Encode
import Types exposing (..)


httpTimeout : Maybe Float
httpTimeout =
    Just 6000.0


getTicketStatus : String -> String -> String -> Cmd Msg
getTicketStatus hostURL apiKey ticketID =
    Http.request
        { method = "GET"
        , headers = [ Http.header "x-api-key" apiKey ]
        , url = hostURL ++ "/" ++ ticketID ++ "/status"
        , body = Http.emptyBody
        , expect = Http.expectJson GotTicketStatus ticketStatusDecoder
        , timeout = httpTimeout
        , tracker = Nothing
        }


markTicketAsScanned : String -> String -> String -> String -> Cmd Msg
markTicketAsScanned hostURL apiKey ticketID secretKey =
    Http.request
        { method = "POST"
        , headers = [ Http.header "x-api-key" apiKey ]
        , url = hostURL ++ "/" ++ ticketID ++ "/submit"
        , body = Http.jsonBody (markTicketAsScannedInput secretKey)
        , expect = Http.expectJson (TicketMarkedAsScanned ticketID) markTicketAsScannedResponseDecoder
        , timeout = httpTimeout
        , tracker = Nothing
        }


markTicketAsScannedInput : String -> Json.Encode.Value
markTicketAsScannedInput v =
    Json.Encode.object [ ( "secret_key", Json.Encode.string v ) ]
