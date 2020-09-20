module Route exposing (..)

import Url.Parser exposing ((</>), Parser, map, oneOf, s, string)


type Page
    = TicketStatus String
    | NotFound


route : Parser (Page -> a) a
route =
    oneOf
        [ map TicketStatus (string </> s "status")
        ]


toString : Page -> String
toString page =
    case page of
        TicketStatus string ->
            "/" ++ string ++ "/status"

        NotFound ->
            "/notfound"
