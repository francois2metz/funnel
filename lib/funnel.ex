defmodule Funnel do
  use Application.Behaviour

  @doc """
  The application callback used to start this
  application and its Dynamos.
  """
  def start(_type, _args) do
    Funnel.Supervisor.start_link(nil)
  end
end
