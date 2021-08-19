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
        , map AlbertTiuChopin (s "albertplayschopin")
        , map TicketStatus string
        ]


toString : Page -> String
toString page =
    case page of
        AlbertTiuChopin ->
            "/albertplayschopin"

        TicketStatus ticketID ->
            "/" ++ ticketID

        UsherTicketStatus ticketID ->
            "/" ++ ticketID ++ "/status"

        NotFound ->
            "/notfound"
