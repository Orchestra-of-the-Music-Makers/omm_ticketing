module API exposing (..)

import Http
import Json.Encode
import Types exposing (..)


httpTimeout : Maybe Float
httpTimeout =
    Just 6000.0

getTicketData : String -> String -> String -> Cmd Msg
getTicketData hostURL apiKey ticketID =
    Http.request
        { method = "GET"
        , headers = [ Http.header "x-api-key" apiKey ]
        , url = hostURL ++ "/" ++ ticketID ++ "/data"
        , body = Http.emptyBody
        , expect = Http.expectJson GotTicketData ticketDataDecoder
        , timeout = httpTimeout
        , tracker = Nothing
        }
