module Route exposing (..)

import Url.Parser exposing ((</>), Parser, map, oneOf, s, string)


type Page
    = TicketStatus String
    | UsherTicketStatus String
    | MusicUnmasked
    | MusicUnmaskedDocs
    | SymphonicFantasies
    | NotFound


route : Parser (Page -> a) a
route =
    oneOf
        [ map UsherTicketStatus (string </> s "status")
        , map MusicUnmasked (s "musicunmasked")
        , map MusicUnmaskedDocs (s "musicunmaskeddocs")
        , map SymphonicFantasies (s "symphonicfantasies")
        , map TicketStatus string
        ]


toString : Page -> String
toString page =
    case page of
        MusicUnmasked ->
            "/musicunmasked"
        
        MusicUnmaskedDocs ->
            "/musicunmaskeddocs"

        SymphonicFantasies ->
            "/symphonicfantasies"

        TicketStatus ticketID ->
            "/" ++ ticketID

        UsherTicketStatus ticketID ->
            "/" ++ ticketID ++ "/status"

        NotFound ->
            "/notfound"
