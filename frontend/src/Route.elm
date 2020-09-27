module Route exposing (..)

import Url.Parser exposing ((</>), Parser, map, oneOf, s, string)


type Page
    = TicketStatus String
    | UsherTicketStatus String
    | NotFound


route : Parser (Page -> a) a
route =
    oneOf
        [ map UsherTicketStatus (string </> s "status")
        , map TicketStatus string
        ]


toString : Page -> String
toString page =
    case page of
        TicketStatus ticketID ->
            "/" ++ ticketID

        UsherTicketStatus ticketID ->
            "/" ++ ticketID ++ "/status"

        NotFound ->
            "/notfound"
