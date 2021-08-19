module Route exposing (..)

import Url.Parser exposing ((</>), Parser, map, oneOf, s, string)


type Page
    = TicketStatus String
    | UsherTicketStatus String
    | AlbertTiuChopin
    | NotFound


route : Parser (Page -> a) a
route =
    oneOf
        [ map UsherTicketStatus (string </> s "status")
        , map TicketStatus string
        , map AlbertTiuChopin (s "albertplayschopin")
        ]


toString : Page -> String
toString page =
    case page of
        TicketStatus ticketID ->
            "/" ++ ticketID

        UsherTicketStatus ticketID ->
            "/" ++ ticketID ++ "/status"
        
        AlbertTiuChopin ->
            "https://ticketing.orchestra.sg/booklet"

        NotFound ->
            "/notfound"
