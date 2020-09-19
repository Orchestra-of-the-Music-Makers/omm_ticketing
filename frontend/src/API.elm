module API exposing (..)

import Http
import Json.Decode
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
        , expect = Http.expectJson GotTicketStatus getTicketStatusResponseDecoder
        , timeout = httpTimeout
        , tracker = Nothing
        }
