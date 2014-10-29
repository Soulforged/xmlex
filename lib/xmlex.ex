defmodule Xmlex do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Xmlex.Worker, [arg1, arg2, arg3])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Xmlex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defmodule XML do
    @derive [HashUtils]
    defstruct   tagname: nil,
          tagtext: "",
          attrs: %{},
          childs: []
  end

  def decode(str) do
    Xmlex.Decoder.decode(str)
  end
  def decode!(str) do
    Xmlex.Decoder.decode!(str)
  end
  
  def encode(content) do
    Xmlex.Encoder.encode(content)
  end
  def encode!(content) do
    Xmlex.Encoder.encode!(content)
  end
  

end
