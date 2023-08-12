module Route exposing (..)

import Url.Parser exposing ((</>), Parser, map, oneOf, s, string)


type Page
    = TicketData String
    | MusicUnmasked
    | MusicUnmaskedDocs
    | SymphonicFantasies
    | NotFound


route : Parser (Page -> a) a
route =
    oneOf
        [ map MusicUnmasked (s "musicunmasked")
        , map MusicUnmaskedDocs (s "musicunmaskeddocs")
        , map SymphonicFantasies (s "symphonicfantasies")
        , map TicketData string
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

        TicketData ticketID ->
            "/" ++ ticketID

        NotFound ->
            "/notfound"
