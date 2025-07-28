module Main where
import Prelude
import Data.Maybe (Maybe(..))
import Data.Array (index)
import Data.Array (length)
import Data.Void (Void, absurd)
import Data.Functor (void)
import Effect.Class (liftEffect)
import Effect.Aff (Aff)
import Halogen.Aff (awaitBody, runHalogenAff, selectElement)
import Web.DOM.ParentNode (QuerySelector(..))
import Effect (Effect)
import Effect.Random (randomInt)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)

-- The app will show a quote
type State = { quote :: String }

-- Actions the user can do
data Action = GetQuote

-- Query type (we don't use queries, so this is just a placeholder)
data Query a = Query Void a

-- List of quotes
quotes :: Array String
quotes =
  [ "Stay hungry, stay foolish."
  , "Code is like humor. When you have to explain it, it's bad."
  , "Simplicity is the soul of efficiency."
  , "Any fool can write code that a computer can understand. Good programmers write code that humans can understand."
  , "The best way to get a project done faster is to start sooner."
  ]

-- The UI component
component :: H.Component Query Unit Void Aff
component = H.mkComponent
  { initialState: const { quote: "Click the button to get a quote!" }
  , render
  , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
  }

-- What the app looks like
render :: State -> H.ComponentHTML Action () Aff
render state =
  HH.div_
    [ HH.h2_ [ HH.text "💬 Quote Explorer" ]
    , HH.p_ [ HH.text state.quote ]
    , HH.button [ HE.onClick \_ -> GetQuote ]
        [ HH.text "✨ Show me a quote!" ]
    ]

-- What happens when user clicks
handleAction :: Action -> H.HalogenM State Action () Void Aff Unit
handleAction GetQuote = do
  idx <- liftEffect $ randomInt 0 (length quotes - 1)
  let newQuote = case index quotes idx of
        Just q -> q
        Nothing -> "Oops, no quote!"
  H.modify_ \st -> st { quote = newQuote }

-- Start app
main :: Effect Unit
main = runHalogenAff do
  body <- awaitBody
  app <- selectElement (QuerySelector "#app")
  case app of
    Just element -> void $ runUI component unit element
    Nothing -> pure unit