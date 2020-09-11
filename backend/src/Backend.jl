module Backend

using Logging, LoggingExtras

function main()
  Base.eval(Main, :(const UserApp = Backend))

  include(joinpath("..", "genie.jl"))

  Base.eval(Main, :(const Genie = Backend.Genie))
  Base.eval(Main, :(using Genie))
end; main()

end
